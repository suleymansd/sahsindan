import hashlib

from fastapi import HTTPException
from starlette.concurrency import run_in_threadpool
from starlette.requests import Request

from app.core.config import settings
from app.core.rate_limit import RateLimitException, consume_limit, rate_limit_exception_handler
from app.core.response import error


class ResourceLimitsMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            return await self.app(scope, receive, send)
        request = Request(scope)
        length = request.headers.get("content-length")
        if length and (not length.isdecimal() or int(length) > settings.max_request_bytes):
            return await error("BODY_TOO_LARGE", "Request body too large", {}, status_code=413)(scope, receive, send)
        metered = settings.app_env == "production" and scope["path"].startswith(("/api/", "/storage/")) and request.method != "OPTIONS"
        if metered:
            ip = request.client.host if request.client else "unknown"
            try:
                await run_in_threadpool(consume_limit, f"global:ip:{hashlib.sha256(ip.encode()).hexdigest()}", settings.api_ip_requests_per_minute, 60)
                await run_in_threadpool(consume_limit, "global:requests:day", settings.api_daily_request_limit, 86400)
            except RateLimitException as exc:
                return await rate_limit_exception_handler(request, exc)(scope, receive, send)
            except HTTPException as exc:
                response = error("SERVICE_UNAVAILABLE", str(exc.detail), {}, status_code=exc.status_code)
                response.headers.update(exc.headers or {})
                return await response(scope, receive, send)
        received = 0

        async def bounded_receive():
            nonlocal received
            message = await receive()
            if message["type"] == "http.request":
                received += len(message.get("body", b""))
                if received > settings.max_request_bytes:
                    raise HTTPException(status_code=413, detail="Request body too large")
            return message

        response_blocked = False

        async def secure_send(message):
            nonlocal response_blocked
            if response_blocked:
                return
            if message["type"] == "http.response.start":
                headers = list(message.get("headers", []))
                content_length = next((v for k, v in headers if k.lower() == b"content-length"), b"0")
                if metered and request.method in {"GET", "HEAD"} and content_length.isdigit() and int(content_length) > 0:
                    try:
                        await run_in_threadpool(consume_limit, "global:response:bytes:day", settings.api_daily_response_bytes, 86400, int(content_length))
                    except (RateLimitException, HTTPException) as exc:
                        response_blocked = True
                        if isinstance(exc, RateLimitException):
                            response = rate_limit_exception_handler(request, exc)
                        else:
                            response = error("SERVICE_UNAVAILABLE", "Usage controls temporarily unavailable", {}, status_code=503)
                            response.headers["Retry-After"] = "30"
                        await response(scope, receive, send)
                        return
                headers.extend([(b"x-content-type-options", b"nosniff"), (b"referrer-policy", b"no-referrer")])
                if request.headers.get("authorization") and not any(k.lower() == b"cache-control" for k, _ in headers):
                    headers.append((b"cache-control", b"private, no-store"))
                message = {**message, "headers": headers}
            await send(message)

        await self.app(scope, bounded_receive, secure_send)


def consume_upload_budget(user_id: int, size: int):
    # Count attempts too: repeated failed uploads must not become an unmetered path.
    consume_limit(f"upload:user:{user_id}:day", settings.upload_user_daily_bytes, 86400, max(size, 1))
    consume_limit("upload:global:day", settings.upload_global_daily_bytes, 86400, max(size, 1))
