import os
from datetime import timedelta
from pathlib import Path
from contextlib import suppress
import uuid
import jwt

from app.core.config import settings
from app.utils.time import utc_now

_s3_client = None
_storage_available = not settings.disable_storage
# Repo-level storage directory (services/api/storage).
_local_storage_dir = Path(__file__).resolve().parents[2] / "storage"


def _local_path(key: str) -> Path:
    target = (_local_storage_dir / key).resolve()
    if not target.is_relative_to(_local_storage_dir.resolve()) or target == _local_storage_dir.resolve():
        raise ValueError("Invalid storage key")
    return target


def upload_key(prefix: str, content_type: str) -> str:
    extension = {"image/jpeg": "jpg", "image/png": "png", "application/pdf": "pdf"}[content_type]
    return f"{prefix}/{uuid.uuid4().hex}.{extension}"


def _absolute_storage_url(path: str) -> str:
    base = settings.public_api_url.rstrip("/")
    normalized = path if path.startswith("/") else f"/{path}"
    return f"{base}{normalized}"


def _get_s3_client():
    global _s3_client
    if _s3_client is None:
        import boto3
        from botocore.config import Config

        os.environ.setdefault("AWS_EC2_METADATA_DISABLED", "true")
        _s3_client = boto3.client(
            "s3",
            endpoint_url=settings.minio_endpoint,
            aws_access_key_id=settings.minio_access_key,
            aws_secret_access_key=settings.minio_secret_key,
            region_name="us-east-1",
            use_ssl=settings.minio_secure,
            config=Config(connect_timeout=2, read_timeout=3, retries={"max_attempts": 2}),
        )
    return _s3_client


def ensure_bucket():
    if not _storage_available:
        _local_storage_dir.mkdir(parents=True, exist_ok=True)
        return
    s3 = _get_s3_client()
    existing = s3.list_buckets().get("Buckets", [])
    if not any(b["Name"] == settings.minio_bucket for b in existing):
        s3.create_bucket(Bucket=settings.minio_bucket)


def upload_bytes(key: str, body: bytes, content_type: str):
    if not _storage_available:
        target = _local_path(key)
        temporary = target.with_suffix(f".{uuid.uuid4().hex}.part")
        try:
            target.parent.mkdir(parents=True, exist_ok=True)
            with temporary.open("xb") as stream:
                stream.write(body)
                stream.flush()
                os.fsync(stream.fileno())
            temporary.replace(target)
            return key
        except OSError:
            # A disk-full/permission failure must not expose a partially written photo.
            return None
        finally:
            with suppress(OSError):
                temporary.unlink(missing_ok=True)
    try:
        s3 = _get_s3_client()
        ensure_bucket()
        s3.put_object(Bucket=settings.minio_bucket, Key=key, Body=body, ContentType=content_type)
        return key
    except Exception:
        return None


def presigned_url(key: str) -> str:
    if not _storage_available:
        local_path = _local_path(key)
        if local_path.exists():
            return _absolute_storage_url(f"/storage/{key}")
        return settings.fallback_image_url
    token = jwt.encode({"purpose": "listing_photo", "key": key,
                        "exp": utc_now() + timedelta(hours=1)}, settings.jwt_secret, algorithm="HS256")
    return f"{settings.public_api_url.rstrip('/')}/api/listings/photos/content?token={token}"


def signed_url(key: str) -> str:
    if key.startswith("verification/"):
        token = jwt.encode({"purpose": "verification_download", "key": key,
                            "exp": utc_now() + timedelta(minutes=5)}, settings.jwt_secret, algorithm="HS256")
        return f"{settings.public_api_url.rstrip('/')}/api/verification/assets/download?token={token}"
    return presigned_url(key)


def read_private_bytes(key: str) -> bytes:
    if not key.startswith("verification/"):
        raise ValueError("Invalid private key")
    return _read_bytes(key)


def read_listing_bytes(key: str) -> bytes:
    if not key.startswith("listings/"):
        raise ValueError("Invalid photo key")
    return _read_bytes(key)


def _read_bytes(key: str) -> bytes:
    if not _storage_available:
        return _local_path(key).read_bytes()
    body = _get_s3_client().get_object(Bucket=settings.minio_bucket, Key=key)["Body"]
    try:
        return body.read()
    finally:
        body.close()



def delete_bytes(key: str):
    if not _storage_available:
        _local_path(key).unlink(missing_ok=True)
    else:
        _get_s3_client().delete_object(Bucket=settings.minio_bucket, Key=key)
