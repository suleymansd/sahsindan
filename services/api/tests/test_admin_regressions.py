from datetime import timedelta

import pytest

from app.core.config import Settings
from app.db.models import Listing, ListingPhoto, ListingState, User, UserRole, VerificationRequest
from app.services.stale import run_stale_job
from app.utils.time import utc_now


def test_review_preserves_privileged_role_and_cannot_be_repeated(client, db_session, make_user):
    target_id, _ = make_user(role=UserRole.ADMIN)
    _, moderator = make_user(role=UserRole.MODERATOR)
    with db_session() as db:
        request = VerificationRequest(user_id=target_id)
        db.add(request)
        db.commit()
        request_id = request.id
    path = f"/api/admin/verification/{request_id}"
    assert client.post(f"{path}/approve", headers=moderator, json={}).status_code == 200
    assert client.post(f"{path}/approve", headers=moderator, json={}).status_code == 409
    assert client.post(f"{path}/reject", headers=moderator, json={"reason": "Changed mind"}).status_code == 409
    with db_session() as db:
        assert db.get(User, target_id).role == UserRole.ADMIN


def test_saved_admin_settings_affect_stale_job_and_upload_limit(client, db_session, make_user, make_listing):
    owner, owner_headers = make_user()
    _, admin = make_user(role=UserRole.ADMIN)
    listing_id = make_listing(owner, last_confirmed_at=utc_now() - timedelta(days=5))
    response = client.put("/api/admin/settings", headers=admin,
                          json={"stale_days": 2, "confirm_window_days": 1, "photo_max_count": 1})
    assert response.status_code == 200
    with db_session() as db:
        assert run_stale_job(db) == 1
        assert db.get(Listing, listing_id).state == ListingState.ARCHIVED
        db.add(ListingPhoto(listing_id=listing_id, s3_key="listings/test.png"))
        db.commit()
    response = client.post(f"/api/listings/{listing_id}/photos", headers=owner_headers,
                           files={"file": ("new.png", b"photo", "image/png")})
    assert response.status_code == 400


@pytest.mark.parametrize("field", ["stale_days", "confirm_window_days", "photo_max_count", "photo_max_mb", "listing_fee"])
def test_negative_settings_are_rejected(client, make_user, field):
    _, admin = make_user(role=UserRole.ADMIN)
    assert client.put("/api/admin/settings", headers=admin, json={field: -1}).status_code == 422


def test_production_rejects_weak_or_shared_secrets():
    with pytest.raises(ValueError):
        Settings(_env_file=None, app_env="production", jwt_secret="change-me")
    with pytest.raises(ValueError):
        Settings(_env_file=None, app_env="production", jwt_secret="a" * 32, jwt_refresh_secret="a" * 32)
    with pytest.raises(ValueError):
        Settings(_env_file=None, app_env="production", jwt_secret="a" * 32, jwt_refresh_secret="b" * 32,
                 cors_origins="http://localhost, * ")
