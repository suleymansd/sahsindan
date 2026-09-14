from unittest.mock import Mock
from io import BytesIO
from PIL import Image

_image = BytesIO()
Image.new("RGB", (2, 2), "white").save(_image, format="PNG")
VALID_PNG = _image.getvalue()
from datetime import timedelta
from urllib.parse import urlsplit

from fastapi import FastAPI
from fastapi.testclient import TestClient
import jwt
import pytest

from app.core.config import settings
from app.db.models import ListingPhoto, VerificationAsset, VerificationRequest, UserRole
from app.main import mount_public_storage
from app.utils import storage
from app.utils.time import utc_now


def test_local_storage_rejects_path_escape(tmp_path, monkeypatch):
    monkeypatch.setattr(storage, "_storage_available", False)
    monkeypatch.setattr(storage, "_local_storage_dir", tmp_path / "storage")
    with pytest.raises(ValueError):
        storage.upload_bytes("../escaped.txt", b"private", "text/plain")
    assert not (tmp_path / "escaped.txt").exists()


def test_s3_failure_does_not_silently_switch_to_local(tmp_path, monkeypatch):
    monkeypatch.setattr(storage, "_storage_available", True)
    monkeypatch.setattr(storage, "_local_storage_dir", tmp_path)
    s3 = Mock()
    s3.list_buckets.side_effect = OSError("Storage unavailable")
    monkeypatch.setattr(storage, "_get_s3_client", lambda: s3)
    assert storage.upload_bytes("listings/1/a.png", b"photo", "image/png") is None
    assert storage.upload_bytes("listings/1/b.png", b"photo", "image/png") is None
    assert not (tmp_path / "listings/1/b.png").exists()


def test_verification_upload_failure_creates_no_asset(client, db_session, make_user, monkeypatch):
    user_id, headers = make_user(role=UserRole.USER_PENDING)
    with db_session() as db:
        request = VerificationRequest(user_id=user_id)
        db.add(request)
        db.commit()
        request_id = request.id
    monkeypatch.setattr("app.api.routes.verification.upload_bytes", lambda *args: None)
    response = client.post("/api/verification/assets/upload", params={"request_id": request_id, "type": "selfie"},
                           headers=headers, files={"file": ("selfie.png", VALID_PNG, "image/png")})
    assert response.status_code == 503
    with db_session() as db:
        assert db.query(VerificationAsset).count() == 0


def test_duplicate_photo_names_have_distinct_keys(client, make_user, make_listing, monkeypatch):
    owner, headers = make_user()
    listing_id = make_listing(owner)
    keys = []
    def upload(key, *args):
        keys.append(key)
        return key
    monkeypatch.setattr("app.api.routes.listings.upload_bytes", upload)
    for _ in range(2):
        response = client.post(f"/api/listings/{listing_id}/photos", headers=headers,
                               files={"file": ("../../photo.png", VALID_PNG, "image/png")})
        assert response.status_code == 200
    assert keys[0] != keys[1]
    assert all(".." not in key for key in keys)


def test_static_server_exposes_only_listing_photos(tmp_path):
    (tmp_path / "verification").mkdir()
    (tmp_path / "verification" / "id.png").write_bytes(b"private")
    (tmp_path / "dev_local.sqlite3").write_bytes(b"database")
    app = FastAPI()
    mount_public_storage(app, tmp_path)
    (tmp_path / "listings" / "photo.png").write_bytes(b"photo")
    with TestClient(app) as client:
        assert client.get("/storage/listings/photo.png").content == b"photo"
        assert client.get("/storage/dev_local.sqlite3").status_code == 404
        assert client.get("/storage/verification/id.png").status_code == 404
        assert client.get("/storage/listings/%2e%2e/verification/id.png").status_code == 404


def test_private_download_requires_admin_issued_expiring_link(client, db_session, make_user, tmp_path, monkeypatch):
    user_id, owner = make_user(role=UserRole.USER_PENDING)
    _, admin = make_user(role=UserRole.ADMIN)
    key = "verification/1/1/id_front/document.png"
    monkeypatch.setattr(storage, "_storage_available", False)
    monkeypatch.setattr(storage, "_local_storage_dir", tmp_path)
    storage.upload_bytes(key, b"private document", "image/png")
    with db_session() as db:
        request = VerificationRequest(user_id=user_id)
        db.add(request)
        db.flush()
        asset = VerificationAsset(request_id=request.id, type="id_front", s3_key=key)
        db.add(asset)
        db.commit()
        path = f"/api/admin/verification/{request.id}/assets/{asset.id}/signed-url"
    assert client.get(path, headers=owner).status_code == 403
    signed = client.get(path, headers=admin)
    assert signed.status_code == 200
    url = urlsplit(signed.json()["data"]["url"])
    response = client.get(f"{url.path}?{url.query}")
    assert response.status_code == 200
    assert response.content == b"private document"
    assert response.headers["cache-control"] == "no-store"
    expired = jwt.encode({"purpose": "verification_download", "key": key,
                          "exp": utc_now() - timedelta(seconds=1)}, settings.jwt_secret, algorithm="HS256")
    assert client.get("/api/verification/assets/download", params={"token": expired}).status_code == 401


def test_remote_photo_uses_signed_api_url_and_reads_private_bucket(client, db_session, make_user, make_listing, monkeypatch):
    owner, _ = make_user()
    listing_id = make_listing(owner)
    key = f"listings/{listing_id}/photo.png"
    with db_session() as db:
        db.add(ListingPhoto(listing_id=listing_id, s3_key=key))
        db.commit()
    monkeypatch.setattr(storage, "_storage_available", True)
    s3 = Mock()
    body = Mock()
    body.read.return_value = b"photo bytes"
    s3.get_object.return_value = {"Body": body}
    monkeypatch.setattr(storage, "_get_s3_client", lambda: s3)
    url = urlsplit(storage.presigned_url(key))
    assert url.path == "/api/listings/photos/content"
    response = client.get(f"{url.path}?{url.query}")
    assert response.status_code == 200
    assert response.content == b"photo bytes"
    assert response.headers["content-type"] == "image/png"
    body.close.assert_called_once()
    assert client.get(f"{url.path}?token=invalid").status_code == 401


def test_local_disk_failure_returns_503_without_partial_file_or_quota(client, db_session, make_user, make_listing, tmp_path, monkeypatch):
    from app.db.models import StorageUsage
    owner, headers = make_user()
    listing = make_listing(owner)
    monkeypatch.setattr(storage, "_storage_available", False)
    monkeypatch.setattr(storage, "_local_storage_dir", tmp_path)
    monkeypatch.setattr(storage.os, "fsync", Mock(side_effect=OSError("No space left on device")))
    response = client.post(f"/api/listings/{listing}/photos", headers=headers,
        files={"file": ("photo.png", VALID_PNG, "image/png")})
    assert response.status_code == 503
    assert not [path for path in tmp_path.rglob("*") if path.is_file()]
    with db_session() as db:
        assert db.query(ListingPhoto).count() == 0
        usage = db.get(StorageUsage, 1)
        assert usage is None or usage.used_bytes == 0
