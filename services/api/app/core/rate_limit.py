from fastapi import Depends, Request

from app.core.redis import redis_client
from app.core.response import error


def rate_limit(limit: int, window_seconds: int):
    async def _check(request: Request):
        identifier = request.client.host if request.client else "unknown"
        key = f"rl:{identifier}:{request.url.path}"
        try:
            count = redis_client.incr(key)
            if count == 1:
                redis_client.expire(key, window_seconds)
            if count > limit:
                raise RateLimitException()
        except RateLimitException:
            raise
        except Exception:
            # Fail open for temporary redis/network issues.
            return
    return _check


class RateLimitException(Exception):
    pass


def rate_limit_exception_handler(request: Request, exc: RateLimitException):
    return error("RATE_LIMITED", "Too many requests", {"path": request.url.path}, status_code=429)
