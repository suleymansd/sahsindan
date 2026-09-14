import pytest
from starlette.websockets import WebSocketDisconnect

from app.db.models import UserRole, UserStatus


def test_verified_socket_ping(client, make_user):
    _, headers = make_user()
    with client.websocket_connect("/api/ws/connect", headers=headers) as socket:
        socket.send_text("ping")
        assert socket.receive_json() == {"type": "pong"}


@pytest.mark.parametrize("role,status", [(UserRole.BANNED, UserStatus.ACTIVE),
                                         (UserRole.USER_VERIFIED, UserStatus.SUSPENDED),
                                         (UserRole.USER_PENDING, UserStatus.ACTIVE)])
def test_socket_rejects_disabled_or_unverified_user(client, make_user, role, status):
    _, headers = make_user(role=role, status=status)
    with pytest.raises(WebSocketDisconnect) as exc:
        with client.websocket_connect("/api/ws/connect", headers=headers):
            pass
    assert exc.value.code == 1008


def test_socket_rejects_missing_token(client):
    with pytest.raises(WebSocketDisconnect) as exc:
        with client.websocket_connect("/api/ws/connect"):
            pass
    assert exc.value.code == 1008
