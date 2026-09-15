import asyncio
import logging
from contextlib import asynccontextmanager, suppress
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.exc import OperationalError, SQLAlchemyError, TimeoutError as SQLAlchemyTimeoutError
from redis.exceptions import RedisError
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.api.router import api_router
from app.core.config import settings
from app.core.redis import redis_client
from app.core.rate_limit import RateLimitException, rate_limit_exception_handler
from app.core.response import error
from app.core.resource_limits import ResourceLimitsMiddleware
from app.db.session import SessionLocal
from app.services.stale import run_stale_job
from app.services.realtime import realtime_hub

# Keep operational failures visible; do not log request bodies or credentials
logging.getLogger().setLevel(logging.WARNING)
logging.getLogger("uvicorn").setLevel(logging.WARNING)
logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
logging.getLogger("fastapi").setLevel(logging.WARNING)
logging.getLogger("sqlalchemy").setLevel(logging.WARNING)

async def stale_job_loop():
    while True:
        db: Session = SessionLocal()
        try:
            run_stale_job(db)
        except Exception:
            db.rollback()
            logging.getLogger(__name__).exception("Stale listing job failed; retrying next interval")
        finally:
            db.close()
        await asyncio.sleep(60)


@asynccontextmanager
async def lifespan(app: FastAPI):  # noqa: ARG001
    await realtime_hub.start()
    task = None
    if not settings.disable_stale_job:
        task = asyncio.create_task(stale_job_loop())
    try:
        yield
    finally:
        await realtime_hub.stop()
        if task:
            task.cancel()
            with suppress(asyncio.CancelledError):
                await task


app = FastAPI(title="Trust Market API", lifespan=lifespan, docs_url=None if settings.app_env == "production" else "/docs", redoc_url=None if settings.app_env == "production" else "/redoc")

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
app.add_middleware(ResourceLimitsMiddleware)

app.include_router(api_router, prefix="/api")

def mount_public_storage(application: FastAPI, storage_root: Path):
    public_storage = storage_root / "listings"
    public_storage.mkdir(parents=True, exist_ok=True)
    application.mount("/storage/listings", StaticFiles(directory=str(public_storage)), name="storage")


if settings.disable_storage:
    mount_public_storage(app, BASE_DIR / "storage")


@app.exception_handler(RequestValidationError)
def validation_exception_handler(request, exc):
    errors = []
    for item in exc.errors():
        item = {k: v for k, v in item.items() if k != "input"}
        if "ctx" in item and isinstance(item["ctx"], dict):
            item = {**item, "ctx": {k: str(v) for k, v in item["ctx"].items()}}
        errors.append(item)
    return error("VALIDATION_ERROR", "Invalid input", {"errors": errors}, status_code=422)


@app.exception_handler(HTTPException)
def http_exception_handler(request, exc):
    response = error("HTTP_ERROR", str(exc.detail), {}, status_code=exc.status_code)
    response.headers.update(exc.headers or {})
    return response


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
        if not redis_client.ping():
            raise RedisError("Redis did not acknowledge readiness")
    except (SQLAlchemyError, RedisError):
        # Health stays live; readiness must fail when auth/quotas cannot operate.
        return error("SERVICE_UNAVAILABLE", "Service temporarily unavailable", {}, status_code=503)
    finally:
        db.close()
    return {"status": "ready"}
