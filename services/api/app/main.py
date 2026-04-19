import asyncio
import logging
from contextlib import asynccontextmanager, suppress
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.exc import OperationalError, TimeoutError as SQLAlchemyTimeoutError
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.api.router import api_router
from app.core.config import settings
from app.core.rate_limit import RateLimitException, rate_limit_exception_handler
from app.core.response import error
from app.db.session import SessionLocal
from app.services.stale import run_stale_job

# Disable all logging except errors
logging.getLogger().setLevel(logging.ERROR)
logging.getLogger("uvicorn").setLevel(logging.ERROR)
logging.getLogger("uvicorn.access").setLevel(logging.ERROR)
logging.getLogger("fastapi").setLevel(logging.ERROR)
logging.getLogger("sqlalchemy").setLevel(logging.ERROR)

async def stale_job_loop():
    while True:
        db: Session = SessionLocal()
        try:
            run_stale_job(db)
        finally:
            db.close()
        await asyncio.sleep(60)


@asynccontextmanager
async def lifespan(app: FastAPI):  # noqa: ARG001
    task = None
    if not settings.disable_stale_job:
        task = asyncio.create_task(stale_job_loop())
    try:
        yield
    finally:
        if task:
            task.cancel()
            with suppress(asyncio.CancelledError):
                await task


app = FastAPI(title="Trust Market API", lifespan=lifespan)

# services/api root (contains "storage/").
BASE_DIR = Path(__file__).resolve().parents[1]
cors_origins = [origin.strip() for origin in settings.cors_origins.split(",") if origin.strip()]
cors_origin_regex = None
if "*" in cors_origins:
    cors_origin_regex = ".*"
    cors_origins = []

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_origin_regex=cors_origin_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(GZipMiddleware, minimum_size=1024)

app.include_router(api_router, prefix="/api")

if settings.disable_storage:
    app.mount("/storage", StaticFiles(directory=str(BASE_DIR / "storage")), name="storage")


@app.exception_handler(RequestValidationError)
def validation_exception_handler(request, exc):
    errors = []
    for item in exc.errors():
        if "ctx" in item and isinstance(item["ctx"], dict):
            item = {**item, "ctx": {k: str(v) for k, v in item["ctx"].items()}}
        errors.append(item)
    return error("VALIDATION_ERROR", "Invalid input", {"errors": errors}, status_code=422)


@app.exception_handler(HTTPException)
def http_exception_handler(request, exc):
    return error("HTTP_ERROR", str(exc.detail), {}, status_code=exc.status_code)


@app.exception_handler(SQLAlchemyTimeoutError)
def sqlalchemy_timeout_handler(request, exc):
    return error("SERVICE_UNAVAILABLE", "Service temporarily overloaded", {}, status_code=503)


@app.exception_handler(OperationalError)
def sqlalchemy_operational_handler(request, exc):
    detail = str(getattr(exc, "orig", exc)).lower()
    if "database is locked" in detail:
        return error("SERVICE_UNAVAILABLE", "Service temporarily overloaded", {}, status_code=503)
    return error("DATABASE_ERROR", "Database operation failed", {}, status_code=500)


app.add_exception_handler(RateLimitException, rate_limit_exception_handler)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def ready():
    db: Session = SessionLocal()
    try:
        db.execute(text("SELECT 1"))
    finally:
        db.close()
    return {"status": "ready"}
