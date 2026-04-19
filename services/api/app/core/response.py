from typing import Any
from fastapi.responses import JSONResponse


def success(data: Any = None, meta: dict | None = None, status_code: int = 200) -> JSONResponse:
    payload = {"data": data, "meta": meta or {}}
    return JSONResponse(status_code=status_code, content=payload)


def error(code: str, message: str, details: dict | None = None, status_code: int = 400) -> JSONResponse:
    payload = {"error": {"code": code, "message": message, "details": details or {}}}
    return JSONResponse(status_code=status_code, content=payload)
