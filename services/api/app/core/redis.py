from threading import RLock
from app.core.config import settings
from app.utils.time import utc_now

try:
    import redis  # type: ignore
except ModuleNotFoundError:  # pragma: no cover - fallback for tests
    redis = None


class _MemoryRedis:
    def __init__(self):
        self._lock = RLock()
        self._store: dict[str, str] = {}
        self._exp: dict[str, float] = {}

    def ping(self) -> bool:
        return True

    def _purge_if_expired(self, key: str) -> None:
        exp = self._exp.get(key)
        if exp is None:
            return
        if exp <= utc_now().timestamp():
            self._store.pop(key, None)
            self._exp.pop(key, None)

    def consume_limit(self, key, amount, limit, seconds):
        with self._lock:
            # Sweep expired development counters so arbitrary keys cannot leak memory.
            for item in list(self._exp):
                self._purge_if_expired(item)
            current = int(self._store.get(key, "0"))
            if current + amount > limit:
                ttl = max(1, int(self._exp.get(key, utc_now().timestamp() + seconds) - utc_now().timestamp()))
                return 0, ttl
            self._store[key] = str(current + amount)
            self._exp.setdefault(key, utc_now().timestamp() + seconds)
            return 1, seconds

    def incr(self, key: str) -> int:
        with self._lock:
            self._purge_if_expired(key)
            current = int(self._store.get(key, "0"))
            current += 1
            self._store[key] = str(current)
            return current

    def expire(self, key: str, seconds: int) -> bool:
        with self._lock:
            self._purge_if_expired(key)
            if key not in self._store:
                return False
            self._exp[key] = utc_now().timestamp() + seconds
            return True

    def get(self, key: str) -> str | None:
        with self._lock:
            self._purge_if_expired(key)
            return self._store.get(key)

    def set(self, key: str, value: str, ex: int | None = None) -> bool:
        with self._lock:
            self._store[key] = value
            if ex is not None:
                self._exp[key] = utc_now().timestamp() + ex
            else:
                self._exp.pop(key, None)
            return True

    def setex(self, key: str, seconds: int, value: str) -> bool:
        return self.set(key, value, ex=seconds)

    def delete(self, key: str) -> int:
        with self._lock:
            existed = key in self._store
            self._store.pop(key, None)
            self._exp.pop(key, None)
            return 1 if existed else 0

    def flushall(self) -> bool:
        with self._lock:
            self._store.clear()
            self._exp.clear()
            return True


if redis and not settings.redis_url.startswith("memory://"):
    redis_client = redis.Redis.from_url(
        settings.redis_url,
        decode_responses=True,
        socket_connect_timeout=0.2,
        socket_timeout=0.2,
        retry_on_timeout=False,
    )
else:
    redis_client = _MemoryRedis()
