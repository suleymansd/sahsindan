import base64
from datetime import timedelta
from io import BytesIO
from unittest.mock import Mock

from cryptography.fernet import Fernet
from PIL import Image
import pytest

from app.core.config import settings
from app.core.mfa import encrypt_secret, matching_counter, new_secret, totp
from app.core.security import create_refresh_token
from app.db.models import User, UserRole, VerificationRequest, VerificationStatus, VerificationAsset, StorageUsage
from app.services.retention import purge_reviewed_assets
from app.utils.time import utc_now


@pytest.mark.parametrize("timestamp, expected", [(59, "94287082"), (1111111109, "07081804"), (1111111111, "14050471"), (1234567890, "89005924"), (2000000000, "69279037"), (20000000000, "65353130")])
def test_rfc6238_sha1_vectors(timestamp, expected):
    secret = base64.b32encode(b"12345678901234567890").decode()
    assert totp(secret, timestamp // 30, digits=8) == expected


def test_mfa_clock_window_and_encryption():
    secret = new_secret()
    encrypted = encrypt_secret(secret)
    assert secret not in encrypted
    assert Fernet(settings.mfa_encryption_key.encode()).decrypt(encrypted.encode()).decode() == secret
    assert matching_counter(secret, totp(secret, 99), now=3000) == 99
    assert matching_counter(secret, totp(secret, 98), now=3000) is None
    assert matching_counter(secret, "１２３４５６", now=3000) is None


def test_production_privileged_accounts_require_enrollment(client, make_user, monkeypatch):
    _, headers = make_user(role=UserRole.ADMIN)
    monkeypatch.setattr(settings, "app_env", "production")
    response = client.post("/api/auth/login", json={"email": "audit1@example.com", "password": "Pass1234!"})
    assert response.status_code == 403
    assert client.get("/api/auth/me", headers=headers).status_code == 401


def test_mfa_login_replay_refresh_and_previous_sessions(client, make_user, db_session, monkeypatch):
    user_id, old_headers = make_user(role=UserRole.ADMIN)
    old_refresh, _, _ = create_refresh_token(user_id)
    secret = new_secret()
    with db_session() as db:
        db.get(User, user_id).mfa_secret = encrypt_secret(secret)
        db.commit()
    monkeypatch.setattr("app.core.mfa.time.time", lambda: 1800000000)
    payload = {"email": "audit1@example.com", "password": "Pass1234!"}
    assert client.post("/api/auth/login", json=payload).status_code == 401
    assert client.post("/api/auth/login", json={**payload, "otp_code": totp(secret, 59999990)}).status_code == 401
    assert client.get("/api/auth/me", headers=old_headers).status_code == 401
    assert client.post("/api/auth/refresh", json={"refresh_token": old_refresh}).status_code == 401
    payload["otp_code"] = totp(secret, 60000000)
    response = client.post("/api/auth/login", json=payload, headers={"X-Client": "mobile"})
    assert response.status_code == 200, response.text
    data = response.json()["data"]
    assert client.get("/api/auth/me", headers={"Authorization": "Bearer " + data["access_token"]}).status_code == 200
    assert client.post("/api/auth/login", json=payload).status_code == 401
    assert client.post("/api/auth/refresh", json={"refresh_token": data["refresh_token"]}).status_code == 200
    with db_session() as db:
        db.get(User, user_id).mfa_secret = encrypt_secret(new_secret())
        db.commit()
    assert client.get("/api/auth/me", headers={"Authorization": "Bearer " + data["access_token"]}).status_code == 401


@pytest.mark.postgres
def test_mfa_code_has_one_concurrent_winner(client, make_user, db_session):
    from concurrent.futures import ThreadPoolExecutor
    from fastapi import HTTPException
    from app.core.mfa import verify_login_mfa
    import time
    user_id, _ = make_user(role=UserRole.ADMIN)
    secret = new_secret()
    with db_session() as db:
        db.get(User, user_id).mfa_secret = encrypt_secret(secret)
        db.commit()
    code = totp(secret, int(time.time()) // 30)
    def attempt(_):
        with db_session() as db:
            try:
                verify_login_mfa(db, db.get(User, user_id), code)
                db.commit()
                return True
            except HTTPException:
                db.rollback()
                return False
    with ThreadPoolExecutor(max_workers=6) as pool:
        assert sum(pool.map(attempt, range(6))) == 1


def test_mfa_password_reset_does_not_remove_second_factor(client, make_user, db_session):
    user_id, _ = make_user(role=UserRole.ADMIN)
    with db_session() as db:
        db.get(User, user_id).mfa_secret = encrypt_secret(new_secret())
        db.commit()
    token = client.post("/api/auth/forgot-password", json={"email": "audit1@example.com"}).json()["data"]["reset_token"]
    assert client.post("/api/auth/reset-password", json={"token": token, "new_password": "Changed123!"}).status_code == 200
    assert client.post("/api/auth/login", json={"email": "audit1@example.com", "password": "Changed123!"}).status_code == 401


@pytest.mark.postgres
def test_authentication_returns_connection_before_endpoint_work(make_user, db_session):
    from sqlalchemy import create_engine
    from sqlalchemy.orm import Session
    from app.core.deps import get_current_user
    owner, headers = make_user()
    # Authentication must not monopolize the only connection while route execution
    # waits for a thread. Use the fixture schema on a deliberately tiny pool.
    original = db_session.kw["bind"]
    with original.connect() as connection:
        schema = connection.exec_driver_sql("SELECT current_schema()").scalar_one()
    engine = create_engine(original.url, pool_size=1, max_overflow=0, pool_timeout=.1,
                           connect_args={"options": f"-csearch_path={schema}"})
    try:
        with Session(engine) as session:
            user = get_current_user(db=session, authorization=headers["Authorization"])
            with engine.connect() as another_request:
                assert another_request.exec_driver_sql("SELECT 1").scalar_one() == 1
            assert user.id == owner and user.email == "audit1@example.com"
    finally:
        engine.dispose()


def test_retention_preserves_pending_recent_and_failed_deletions(make_user, db_session, monkeypatch):
    owner, _ = make_user()
    cutoff = utc_now() - timedelta(days=31)
    with db_session() as db:
        db.add(StorageUsage(id=1, used_bytes=40))
        for state, date, key in [(VerificationStatus.APPROVED, cutoff, "old"), (VerificationStatus.REJECTED, cutoff, "failed"), (VerificationStatus.PENDING, cutoff, "pending"), (VerificationStatus.APPROVED, utc_now(), "recent")]:
            req = VerificationRequest(user_id=owner, status=state, updated_at=date)
            req.assets = [VerificationAsset(type="identity", s3_key=key, size_bytes=10)]
            db.add(req)
        db.commit()
        def delete(key):
            if key == "failed":
                raise OSError("offline")
        mocked = Mock(side_effect=delete)
        monkeypatch.setattr("app.services.retention.delete_bytes", mocked)
        assert purge_reviewed_assets(db) == 1
        assert {a.s3_key for a in db.query(VerificationAsset)} == {"failed", "pending", "recent"}
        assert db.get(StorageUsage, 1).used_bytes == 30
        monkeypatch.setattr("app.services.retention.delete_bytes", Mock())
        assert purge_reviewed_assets(db) == 1
        assert db.get(StorageUsage, 1).used_bytes == 20
        assert purge_reviewed_assets(db) == 0


def test_pdf_rejected_before_storage(client, make_user, db_session, monkeypatch):
    owner, headers = make_user()
    with db_session() as db:
        req = VerificationRequest(user_id=owner)
        db.add(req)
        db.commit()
        request_id = req.id
    upload = Mock()
    monkeypatch.setattr("app.api.routes.verification.upload_bytes", upload)
    response = client.post(f"/api/verification/assets/upload?request_id={request_id}&type=identity", headers=headers, files={"file": ("a.pdf", b"%PDF-1.7\n%%EOF", "application/pdf")})
    assert response.status_code == 400
    upload.assert_not_called()


def test_image_metadata_and_trailing_payload_removed():
    from app.utils.file_validation import validate_upload
    output = BytesIO()
    Image.new("RGB", (10, 10)).save(output, format="PNG")
    cleaned = validate_upload(output.getvalue() + b"<script>hidden-payload</script>", "image/png")
    assert b"hidden-payload" not in cleaned
    Image.open(BytesIO(cleaned)).verify()
