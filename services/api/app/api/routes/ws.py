from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core.security import decode_access_token
from app.db.models import User
from app.db.session import SessionLocal
from app.services.realtime import realtime_hub

router = APIRouter()


def _extract_token(websocket: WebSocket) -> str | None:
    query_token = websocket.query_params.get("token")
    if query_token:
        return query_token

    auth_header = websocket.headers.get("authorization")
    if auth_header and auth_header.lower().startswith("bearer "):
        return auth_header.split(" ", 1)[1]

    return None


def _validate_user_id(token: str | None) -> int | None:
    if not token:
        return None
    try:
        payload = decode_access_token(token)
        return int(payload["sub"])
    except Exception:  # noqa: BLE001
        return None


@router.websocket("/connect")
async def ws_connect(websocket: WebSocket):
    token = _extract_token(websocket)
    user_id = _validate_user_id(token)
    if user_id is None:
        await websocket.close(code=1008, reason="Invalid token")
        return

    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
    finally:
        db.close()
    if not user:
        await websocket.close(code=1008, reason="User not found")
        return

    await realtime_hub.connect(user_id, websocket)
    try:
        while True:
            message = await websocket.receive_text()
            if message.lower() == "ping":
                await websocket.send_json({"type": "pong"})
    except WebSocketDisconnect:
        pass
    except Exception:  # noqa: BLE001
        pass
    finally:
        await realtime_hub.disconnect(user_id, websocket)

