import os
from io import BytesIO
from pathlib import Path
from typing import IO

from app.core.config import settings

_s3_client = None
_storage_available = not settings.disable_storage
# Repo-level storage directory (services/api/storage).
_local_storage_dir = Path(__file__).resolve().parents[2] / "storage"


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
    global _storage_available
    if not _storage_available:
        ensure_bucket()
        target = _local_storage_dir / key
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(body)
        return key
    try:
        s3 = _get_s3_client()
        ensure_bucket()
        s3.put_object(Bucket=settings.minio_bucket, Key=key, Body=body, ContentType=content_type)
        return key
    except Exception:
        _storage_available = False
        return None


def presigned_url(key: str) -> str:
    if not _storage_available:
        local_path = _local_storage_dir / key
        if local_path.exists():
            return _absolute_storage_url(f"/storage/{key}")
        return settings.fallback_image_url
    return _absolute_storage_url(f"/storage/{settings.minio_bucket}/{key}")


def signed_url(key: str) -> str:
    return presigned_url(key)


def scan_file_placeholder(_: bytes) -> None:
    return None
