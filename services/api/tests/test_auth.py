from fastapi.testclient import TestClient


def _extract_refresh_token(response) -> str | None:
    cookie_header = response.headers.get("set-cookie")
    if not cookie_header:
        return None
    for part in cookie_header.split(";"):
        part = part.strip()
        if part.startswith("refresh_token="):
            return part.split("=", 1)[1]
    return None

from app.main import app


def test_auth_flow(db_session):
    with TestClient(app) as client:
        payload = {
            "email": "new@trustmarket.local",
            "phone": "5551000000",
            "password": "Pass1234!",
            "name": "Test User",
            "city": "ISTANBUL",
        }
        res = client.post("/api/auth/register", json=payload)
        assert res.status_code == 200
        access = res.json()["data"]["access_token"]
        assert access

        login = client.post("/api/auth/login", json={"email": payload["email"], "password": payload["password"]})
        assert login.status_code == 200

        refresh_token = _extract_refresh_token(login)
        assert refresh_token
        refresh = client.post("/api/auth/refresh", params={"refresh_token": refresh_token})
        assert refresh.status_code == 200

        logout = client.post("/api/auth/logout")
        assert logout.status_code == 200
