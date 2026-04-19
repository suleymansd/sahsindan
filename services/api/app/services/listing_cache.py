import hashlib
import json
from typing import Any

from app.core.config import settings
from app.core.redis import redis_client

_LISTINGS_CACHE_VERSION_KEY = "cache:listings:version"


def _cache_enabled() -> bool:
    return settings.listings_cache_enabled and settings.listings_cache_ttl_seconds > 0


def _cache_version() -> int:
    try:
        raw = redis_client.get(_LISTINGS_CACHE_VERSION_KEY)
        if raw is None:
            redis_client.set(_LISTINGS_CACHE_VERSION_KEY, "1")
            return 1
        return int(raw)
    except Exception:
        return 1


def _cache_key(filters: dict[str, Any]) -> str:
    fingerprint = hashlib.sha256(
        json.dumps(filters, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
    ).hexdigest()
    return f"cache:listings:v{_cache_version()}:{fingerprint}"


def get_cached_public_listings(filters: dict[str, Any]) -> list[dict] | None:
    if not _cache_enabled():
        return None
    key = _cache_key(filters)
    try:
        raw = redis_client.get(key)
    except Exception:
        return None
    if not raw:
        return None
    try:
        parsed = json.loads(raw)
    except Exception:
        return None
    if isinstance(parsed, list):
        return parsed
    return None


def set_cached_public_listings(filters: dict[str, Any], payload: list[dict]) -> None:
    if not _cache_enabled():
        return
    key = _cache_key(filters)
    try:
        redis_client.set(key, json.dumps(payload, separators=(",", ":"), ensure_ascii=False), ex=settings.listings_cache_ttl_seconds)
    except Exception:
        return


def invalidate_listings_cache() -> None:
    try:
        redis_client.incr(_LISTINGS_CACHE_VERSION_KEY)
    except Exception:
        return
