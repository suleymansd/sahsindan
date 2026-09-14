import asyncio
import hashlib
import hmac

from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from starlette.concurrency import run_in_threadpool

from app.core.config import settings
from app.core.mfa import session_mfa_valid
from app.core.rate_limit import consume_limit
from app.core.security import decode_access_token
from app.db.models import User, UserRole, UserStatus
from app.db.session import get_db
from app.services.realtime import realtime_hub

router = APIRouter()


def _extract_token(websocket: WebSocket) -> str | None:
    auth = websocket.headers.get("authorization", "")
    if auth.lower().startswith("bearer "):
        return auth.split(" ", 1)[1]
    for protocol in websocket.headers.get("sec-websocket-protocol", "").split(","):
        if protocol.strip().startswith("bearer."):
            return protocol.strip()[7:]
    if settings.app_env == "development":
        return websocket.query_params.get("token")
    return None


def _allowed(token, bind):
    try:
        payload = decode_access_token(token)
        with Session(bind=bind) as db:
            user = db.get(User, int(payload["sub"]))
            if not user or user.status != UserStatus.ACTIVE or user.role not in [UserRole.USER_VERIFIED, UserRole.ADMIN, UserRole.MODERATOR]:
                return None
            if not session_mfa_valid(user, payload):
                return None
            version = payload.get("pv")
            if (settings.app_env == "production" and not version) or (version and not hmac.compare_digest(str(version), hashlib.sha256(user.password_hash.encode()).hexdigest())):
                return None
            return user.id
    except Exception:
        return None


@router.websocket("/connect")
async def ws_connect(websocket: WebSocket, db: Session = Depends(get_db)):
    origin = websocket.headers.get("origin")
    if origin and origin not in [item.strip() for item in settings.cors_origins.split(",")]:
        await websocket.close(code=1008, reason="Origin denied")
        return
    token = _extract_token(websocket)
    try:
        address = websocket.client.host if websocket.client else "unknown"
        await run_in_threadpool(consume_limit, f"ws:handshake:{address}", 30, 60)
    except Exception:
        await websocket.close(code=1013, reason="Connection rate exceeded")
        return
    bind = db.get_bind()
    db.close()
    user_id = await run_in_threadpool(_allowed, token, bind) if token else None
    if user_id is None:
        await websocket.close(code=1008, reason="Access denied")
        return
    if not await realtime_hub.connect(user_id, websocket):
        return
    try:
        while True:
            if not await realtime_hub.renew(websocket):
                await websocket.close(code=1008, reason="Connection limit reached")
                break
            # Recheck expiry and disabled accounts even if the client is idle.
            if await run_in_threadpool(_allowed, token, bind) != user_id:
                await websocket.close(code=1008, reason="Session expired")
                break
            try:
                message = await asyncio.wait_for(websocket.receive_text(), timeout=settings.websocket_auth_check_seconds)
            except asyncio.TimeoutError:
                continue
            if len(message) > 1024:
                await websocket.close(code=1009, reason="Message too large")
                break
            await run_in_threadpool(consume_limit, f"ws:messages:{user_id}", 60, 60)
            if message.lower() == "ping":
                await websocket.send_json({"type": "pong"})
    except WebSocketDisconnect:
        pass
    except Exception:
        await websocket.close(code=1013, reason="Temporarily unavailable")
    finally:
        await realtime_hub.disconnect(user_id, websocket)
