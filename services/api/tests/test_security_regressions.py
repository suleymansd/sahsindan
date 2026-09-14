from datetime import timedelta

import jwt
import pytest

from app.core.config import settings
from app.core.security import create_refresh_token
from app.db.models import RefreshToken, User, UserRole, UserStatus
from app.utils.time import utc_now


def test_reset_token_cannot_authenticate(client, make_user):
    user_id, _ = make_user()
    token = jwt.encode({"sub": str(user_id), "purpose": "password_reset",
                        "exp": utc_now() + timedelta(minutes=10)}, settings.jwt_secret, algorithm="HS256")
    assert client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"}).status_code == 401


@pytest.mark.parametrize("claims", [{}, {"sub": "not-an-id"}, {"sub": "1"}])
def test_malformed_access_claims_return_401(client, claims):
    token = jwt.encode(claims, settings.jwt_secret, algorithm="HS256")
    assert client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"}).status_code == 401


@pytest.mark.parametrize("role,status", [(UserRole.BANNED, UserStatus.ACTIVE),
                                         (UserRole.USER_VERIFIED, UserStatus.SUSPENDED)])
def test_disabled_accounts_cannot_login_refresh_or_access(client, make_user, db_session, role, status):
    user_id, headers = make_user(role=role, status=status)
    token, jti, expires_at = create_refresh_token(user_id)
    with db_session() as db:
        db.add(RefreshToken(user_id=user_id, jti=jti, expires_at=expires_at))
        db.commit()
    assert client.post("/api/auth/login", json={"email": "audit1@example.com", "password": "Pass1234!"}).status_code == 403
    assert client.post("/api/auth/refresh", params={"refresh_token": token}).status_code == 403
    assert client.get("/api/auth/me", headers=headers).status_code == 403


def test_refresh_rotation_rejects_replay(client, make_user):
    make_user()
    login = client.post("/api/auth/login", headers={"X-Client": "mobile"},
                        json={"email": "audit1@example.com", "password": "Pass1234!"})
    token = login.json()["data"]["refresh_token"]
    client.cookies.clear()
    rotated = client.post("/api/auth/refresh", params={"refresh_token": token})
    assert rotated.status_code == 200
    client.cookies.clear()
    assert client.post("/api/auth/refresh", params={"refresh_token": token}).status_code == 401


def test_logout_deletes_invalid_cookie(client):
    client.cookies.set("refresh_token", "invalid")
    response = client.post("/api/auth/logout")
    assert response.status_code == 200
    assert "Max-Age=0" in response.headers.get("set-cookie", "")


def test_reset_is_single_use_and_revokes_refresh(client, make_user):
    make_user()
    login = client.post("/api/auth/login", json={"email": "audit1@example.com", "password": "Pass1234!"})
    assert login.status_code == 200
    token = client.post("/api/auth/forgot-password", json={"email": "audit1@example.com"}).json()["data"]["reset_token"]
    payload = {"token": token, "new_password": "Changed123!"}
    assert client.post("/api/auth/reset-password", json=payload).status_code == 200
    assert client.post("/api/auth/reset-password", json=payload).status_code == 400
    assert client.post("/api/auth/refresh").status_code == 401


def test_production_reset_never_returns_token(client, make_user, monkeypatch):
    make_user()
    monkeypatch.setattr(settings, "app_env", "production")
    known = client.post("/api/auth/forgot-password", json={"email": "audit1@example.com"})
    unknown = client.post("/api/auth/forgot-password", json={"email": "absent@example.com"})
    assert known.status_code == 503
    assert known.json() == unknown.json()
    assert "reset_token" not in known.text


def test_manual_review_does_not_trust_self_asserted_profession(client, make_user, db_session):
    user_id, headers = make_user(role=UserRole.USER_PENDING)
    payload = {"phone_otp": "123456", "selfie_passed": False, "background_consent": True}
    assert client.post("/api/verification/submit", json=payload, headers=headers).status_code == 200
    payload.update(selfie_passed=True, profession_proof="I claim to be a doctor")
    assert client.post("/api/verification/submit", json=payload, headers=headers).status_code == 200
    with db_session() as db:
        assert not db.get(User, user_id).profile.profession_verified


def test_production_manual_review_never_self_verifies(client, make_user, monkeypatch):
    _, headers = make_user(role=UserRole.USER_PENDING)
    monkeypatch.setattr(settings, "app_env", "production")
    response = client.post("/api/verification/submit", headers=headers, json={
        "phone_otp": "123456", "selfie_passed": True, "background_consent": True})
    assert response.status_code == 200
    assert response.json()["data"]["status"] == "PENDING"
    assert client.get("/api/auth/me", headers=headers).json()["data"]["role"] == "USER_PENDING"


def test_registration_normalizes_email_and_rejects_bcrypt_truncation(client):
    payload = {"email": " Audit@Example.com ", "phone": "5551234567", "password": "ü" * 37,
               "name": "Audit", "city": "ISTANBUL"}
    assert client.post("/api/auth/register", json=payload).status_code == 422
    payload["password"] = "Pass1234!"
    response = client.post("/api/auth/register", json=payload)
    assert response.status_code == 200
    assert response.json()["data"]["user"]["email"] == "audit@example.com"
