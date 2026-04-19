from fastapi.testclient import TestClient

from app.core.redis import redis_client
from app.main import app


def test_login_rate_limit(db_session):
    with TestClient(app) as client:
        if hasattr(redis_client, "flushall"):
            redis_client.flushall()

        payload = {
            "email": "ratelimit@trustmarket.local",
            "phone": "5551000011",
            "password": "Pass1234!",
            "name": "Rate User",
            "city": "ISTANBUL",
        }
        reg = client.post("/api/auth/register", json=payload)
        assert reg.status_code == 200

        # 5 failed attempts are allowed, 6th should be rate-limited.
        for _ in range(5):
            res = client.post("/api/auth/login", json={"email": payload["email"], "password": "wrong-pass"})
            assert res.status_code == 401

        blocked = client.post("/api/auth/login", json={"email": payload["email"], "password": "wrong-pass"})
        assert blocked.status_code == 429
