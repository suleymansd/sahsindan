"""Atomic, bounded rate limits. Shared-store outages must never grant free usage."""
import hashlib

from fastapi import HTTPException, Request

from app.core.redis import redis_client
from app.core.response import error

_COUNTER = """
local current = tonumber(redis.call('GET', KEYS[1]) or '0')
local ttl = redis.call('TTL', KEYS[1])
if current + tonumber(ARGV[1]) > tonumber(ARGV[2]) then
  return {0, math.max(ttl, 1)}
end
local count = redis.call('INCRBY', KEYS[1], ARGV[1])
if ttl < 0 then redis.call('EXPIRE', KEYS[1], ARGV[3]) end
return {1, tonumber(ARGV[3])}
"""


class RateLimitException(Exception):
    def __init__(self, retry_after: int = 60):
        self.retry_after = max(1, retry_after)


def consume_limit(key: str, limit: int, window_seconds: int, amount: int = 1):
    if amount < 1 or limit < 1 or window_seconds < 1:
        raise ValueError("Limits must be positive")
    try:
        if hasattr(redis_client, "consume_limit"):
            allowed, ttl = redis_client.consume_limit(key, amount, limit, window_seconds)
        else:
            allowed, ttl = redis_client.eval(_COUNTER, 1, key, amount, limit, window_seconds)
    except Exception as exc:
        raise HTTPException(status_code=503, detail="Usage controls temporarily unavailable", headers={"Retry-After": "30"}) from exc
    if not allowed:
        raise RateLimitException(int(ttl))


def rate_limit(limit: int, window_seconds: int):
    def _check(request: Request):
        identifier = request.client.host if request.client else "unknown"
        # Route templates prevent switching resource IDs to bypass the same limit.
        route = getattr(request.scope.get("route"), "path", request.url.path)
        digest = hashlib.sha256(f"{identifier}:{request.method}:{route}".encode()).hexdigest()
        consume_limit(f"rl:{digest}", limit, window_seconds)
    return _check


def rate_limit_exception_handler(request: Request, exc: RateLimitException):
    response = error("RATE_LIMITED", "Too many requests", {"retry_after": exc.retry_after}, status_code=429)
    response.headers["Retry-After"] = str(exc.retry_after)
    response.headers["Cache-Control"] = "no-store"
    return response
