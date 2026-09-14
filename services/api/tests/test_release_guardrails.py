from concurrent.futures import ThreadPoolExecutor
from io import BytesIO
from unittest.mock import Mock

from PIL import Image
import pytest

from app.core.config import Settings, settings
from app.core.redis import _MemoryRedis
from app.db.models import ListingPhoto, StorageUsage, User, UserRole, VerificationRequest


@pytest.fixture
def png():
    output = BytesIO()
    Image.new("RGB", (16, 16), "blue").save(output, format="PNG")
    return output.getvalue()


def test_atomic_limit_never_overadmits_concurrent_requests():
    counters = _MemoryRedis()
    with ThreadPoolExecutor(max_workers=20) as pool:
        results = list(pool.map(lambda _: counters.consume_limit("budget", 1, 7, 60)[0], range(100)))
    assert sum(results) == 7
    assert counters.get("budget") == "7"


def test_rate_limit_outage_fails_closed_with_retry_after(client, monkeypatch):
    broken = Mock()
    broken.consume_limit.side_effect = ConnectionError()
    monkeypatch.setattr("app.core.rate_limit.redis_client", broken)
    response = client.post("/api/auth/login", json={"email": "x@example.com", "password": "wrong"})
    assert response.status_code == 503
    assert response.headers["retry-after"] == "30"


def test_register_budget_has_retry_after(client):
    for _ in range(5):
        assert client.post("/api/auth/register", json={}).status_code == 422
    response = client.post("/api/auth/register", json={})
    assert response.status_code == 429
    assert int(response.headers["retry-after"]) > 0


def test_global_budget_survives_changing_endpoint(client, make_user, monkeypatch):
    _, headers = make_user()
    monkeypatch.setattr(settings, "app_env", "production")
    monkeypatch.setattr(settings, "api_daily_request_limit", 2)
    assert client.get("/api/auth/me", headers=headers).status_code == 200
    assert client.get("/api/listings", headers=headers).status_code == 200
    assert client.get("/api/auth/me", headers=headers).status_code == 429


def test_body_size_and_validation_do_not_echo_password(client, monkeypatch):
    monkeypatch.setattr(settings, "max_request_bytes", 1024)
    assert client.post("/api/auth/login", content=b"x" * 1025).status_code == 413
    response = client.post("/api/auth/login", json={"email": "invalid", "password": "secret-never-echo"})
    assert response.status_code == 422
    assert "secret-never-echo" not in response.text
    assert '"input"' not in response.text


def test_password_reset_revokes_existing_access_token(client, make_user):
    _, headers = make_user()
    token = client.post("/api/auth/forgot-password", json={"email": "audit1@example.com"}).json()["data"]["reset_token"]
    assert client.post("/api/auth/reset-password", json={"token": token, "new_password": "Changed123!"}).status_code == 200
    assert client.get("/api/auth/me", headers=headers).status_code == 401


def test_mobile_refresh_uses_body_in_production(client, make_user, monkeypatch):
    make_user()
    response = client.post("/api/auth/login", headers={"X-Client": "mobile"}, json={"email": "audit1@example.com", "password": "Pass1234!"})
    token = response.json()["data"]["refresh_token"]
    client.cookies.clear()
    monkeypatch.setattr(settings, "app_env", "production")
    assert client.post("/api/auth/refresh", params={"refresh_token": token}).status_code == 401
    assert client.post("/api/auth/refresh", json={"refresh_token": token}, headers={"X-Client": "mobile"}).status_code == 200


def test_listing_pages_are_bounded_stable_and_independently_cached(client, make_user, make_listing):
    owner, headers = make_user()
    for _ in range(3):
        make_listing(owner)
    first = client.get("/api/listings?limit=2", headers=headers).json()
    second = client.get("/api/listings?limit=2&offset=2", headers=headers).json()
    assert len(first["data"]) == 2 and first["meta"]["has_more"]
    assert len(second["data"]) == 1 and not second["meta"]["has_more"]
    assert not ({item["id"] for item in first["data"]} & {item["id"] for item in second["data"]})
    assert client.get("/api/listings?limit=100000", headers=headers).status_code == 422


def test_fake_image_rejected_before_storage(client, make_user, make_listing, monkeypatch):
    owner, headers = make_user()
    listing = make_listing(owner)
    upload = Mock()
    monkeypatch.setattr("app.api.routes.listings.upload_bytes", upload)
    response = client.post(f"/api/listings/{listing}/photos", headers=headers, files={"file": ("a.png", b"<script>bad</script>", "image/png")})
    assert response.status_code == 400
    upload.assert_not_called()


def test_storage_budget_blocks_before_write(client, make_user, make_listing, monkeypatch, png):
    owner, headers = make_user()
    listing = make_listing(owner)
    monkeypatch.setattr(settings, "storage_budget_bytes", 10)
    upload = Mock()
    monkeypatch.setattr("app.api.routes.listings.upload_bytes", upload)
    response = client.post(f"/api/listings/{listing}/photos", headers=headers, files={"file": ("a.png", png, "image/png")})
    assert response.status_code == 507
    upload.assert_not_called()


def test_failed_upload_rolls_back_persistent_reservation(client, db_session, make_user, make_listing, monkeypatch, png):
    owner, headers = make_user()
    listing = make_listing(owner)
    monkeypatch.setattr("app.api.routes.listings.upload_bytes", lambda *args: None)
    response = client.post(f"/api/listings/{listing}/photos", headers=headers, files={"file": ("a.png", png, "image/png")})
    assert response.status_code == 503
    with db_session() as db:
        usage = db.get(StorageUsage, 1)
        assert usage is None or usage.used_bytes == 0
        assert db.query(ListingPhoto).count() == 0


def test_production_review_requires_documents(client, make_user, db_session, monkeypatch):
    target, _ = make_user(role=UserRole.USER_PENDING)
    from app.core.mfa import encrypt_secret, new_secret
    _, admin = make_user(role=UserRole.ADMIN, mfa_secret=encrypt_secret(new_secret()))
    with db_session() as db:
        req = VerificationRequest(user_id=target)
        db.add(req)
        db.commit()
        request_id = req.id
    monkeypatch.setattr(settings, "app_env", "production")
    assert client.post(f"/api/admin/verification/{request_id}/approve", headers=admin, json={}).status_code == 409
    with db_session() as db:
        assert db.get(User, target).role == UserRole.USER_PENDING


def test_production_settings_reject_local_or_weak_setup():
    with pytest.raises(ValueError):
        Settings(_env_file=None, app_env="production", jwt_secret="short")
    with pytest.raises(ValueError):
        Settings(_env_file=None, app_env="production", database_url="sqlite:///local.db", redis_url="memory://")


def test_cache_invalidation_during_query_cannot_restore_stale_results():
    from app.services.listing_cache import cache_version, get_cached_public_listings, invalidate_listings_cache, set_cached_public_listings
    generation = cache_version()
    invalidate_listings_cache()
    set_cached_public_listings({"q": "race"}, [{"id": 99}], version=generation)
    assert get_cached_public_listings({"q": "race"}) is None
    set_cached_public_listings({"q": "race"}, [{"id": 100}], version=cache_version())
    assert get_cached_public_listings({"q": "race"}) == [{"id": 100}]


def test_corrupt_png_checksum_returns_client_error(client, make_user, make_listing):
    import base64
    owner, headers = make_user()
    listing = make_listing(owner)
    corrupt = base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/l9sAAAAASUVORK5CYII=")
    assert client.post(f"/api/listings/{listing}/photos", headers=headers,
        files={"file": ("corrupt.png", corrupt, "image/png")}).status_code == 400


def test_listing_edit_updates_car_details_and_rejects_oversized_fields(client, make_user, make_listing):
    owner, headers = make_user()
    listing = make_listing(owner)
    details = {"brand": "Volvo", "model": "S60", "year": 2022, "mileage": 50000, "transmission": "Automatic", "fuel": "Gasoline", "color": "Blue"}
    response = client.put(f"/api/listings/{listing}", headers=headers, json={"car_details": details})
    assert response.status_code == 200
    assert response.json()["data"]["car_details"]["model"] == "S60"
    details["brand"] = "x" * 121
    assert client.put(f"/api/listings/{listing}", headers=headers, json={"car_details": details}).status_code == 422


def test_production_download_budget_blocks_body_before_transfer(client, make_user, monkeypatch):
    _, headers = make_user()
    monkeypatch.setattr(settings, "app_env", "production")
    monkeypatch.setattr(settings, "api_daily_response_bytes", 1)
    response = client.get("/api/auth/me", headers=headers)
    assert response.status_code == 429
    assert response.headers["retry-after"]
    assert "email" not in response.text


def test_smtp_global_budget_blocks_without_sending_mail(client, make_user, monkeypatch):
    make_user()
    monkeypatch.setattr(settings, "smtp_host", "local-relay")
    monkeypatch.setattr(settings, "smtp_daily_message_limit", 1)
    mail = Mock()
    monkeypatch.setattr("app.api.routes.auth.send_password_reset", mail)
    assert client.post("/api/auth/forgot-password", json={"email": "audit1@example.com"}).status_code == 200
    assert client.post("/api/auth/forgot-password", json={"email": "different@example.com"}).status_code == 429
    mail.assert_called_once()


def test_favorites_pages_and_compact_ids_preserve_all_saved_items(client, make_user, make_listing):
    owner, headers = make_user()
    ids = [make_listing(owner) for _ in range(3)]
    for listing_id in ids:
        assert client.post(f"/api/listings/{listing_id}/favorite", headers=headers).status_code == 200
    first = client.get("/api/favorites?limit=2", headers=headers).json()
    second = client.get("/api/favorites?limit=2&offset=2", headers=headers).json()
    assert len(first["data"]) == 2 and first["meta"]["has_more"]
    assert len(second["data"]) == 1 and not second["meta"]["has_more"]
    assert set(client.get("/api/favorites/ids", headers=headers).json()["data"]) == set(ids)
    assert client.get("/api/favorites?limit=101", headers=headers).status_code == 422


def test_appointment_pages_do_not_lose_history(client, db_session, make_user, make_listing):
    from app.db.models import Appointment
    from app.utils.time import utc_now
    seller, _ = make_user()
    buyer, headers = make_user()
    listing_id = make_listing(seller)
    with db_session() as db:
        db.add_all([Appointment(listing_id=listing_id, buyer_id=buyer, seller_id=seller, scheduled_at=utc_now(), location="Test") for _ in range(3)])
        db.commit()
    first = client.get("/api/appointments/inbox?limit=2", headers=headers).json()
    second = client.get("/api/appointments/inbox?limit=2&offset=2", headers=headers).json()
    assert len(first["data"]) == 2 and first["meta"]["has_more"]
    assert len(second["data"]) == 1
    assert not ({row["id"] for row in first["data"]} & {row["id"] for row in second["data"]})


def test_admin_bootstrap_rejects_weak_password_before_database_access(monkeypatch):
    from scripts import create_admin
    answers = iter(["admin@example.com", "5559999000", "Admin"])
    monkeypatch.setattr("builtins.input", lambda _: next(answers))
    monkeypatch.setattr(create_admin, "getpass", lambda _: "short")
    database = Mock()
    monkeypatch.setattr(create_admin, "SessionLocal", database)
    with pytest.raises(SystemExit, match="at least 12"):
        create_admin.main()
    database.assert_not_called()


def test_admin_bootstrap_never_promotes_existing_user(make_user, db_session, monkeypatch):
    from scripts import create_admin
    user_id, _ = make_user(role=UserRole.USER_PENDING)
    answers = iter(["audit1@example.com", "5559999000", "Admin"])
    monkeypatch.setattr("builtins.input", lambda _: next(answers))
    monkeypatch.setattr(create_admin, "getpass", lambda _: "StrongAdminPassword123!")
    monkeypatch.setattr(create_admin, "SessionLocal", db_session)
    with pytest.raises(SystemExit, match="no role was changed"):
        create_admin.main()
    with db_session() as db:
        assert db.get(User, user_id).role == UserRole.USER_PENDING
        assert db.query(User).count() == 1
