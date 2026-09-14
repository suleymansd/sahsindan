from __future__ import annotations

import asyncio
from collections import defaultdict
from contextlib import suppress
import json
import logging
import uuid

from fastapi import WebSocket
from app.core.config import settings

logger = logging.getLogger(__name__)

# Redis server time avoids clock skew between workers; expired leases recover
# capacity after a worker crash. A live socket renews before its next auth check.
_LEASE = """
local time = redis.call('TIME')
local now = tonumber(time[1])
redis.call('ZREMRANGEBYSCORE', KEYS[1], '-inf', now)
if not redis.call('ZSCORE', KEYS[1], ARGV[1]) and redis.call('ZCARD', KEYS[1]) >= tonumber(ARGV[2]) then
  return 0
end
redis.call('ZADD', KEYS[1], now + tonumber(ARGV[3]), ARGV[1])
redis.call('EXPIRE', KEYS[1], ARGV[3])
return 1
"""


class RealtimeHub:
    def __init__(self) -> None:
        self._connections: dict[int, set[WebSocket]] = defaultdict(set)
        self._lock = asyncio.Lock()
        self._redis = None
        self._listener = None
        self._channel = "trustmarket:realtime"
        self._leases = {}

    async def start(self):
        if settings.redis_url.startswith("memory://"):
            return
        from redis.asyncio import Redis
        self._redis = Redis.from_url(settings.redis_url, decode_responses=True, socket_connect_timeout=2)
        self._listener = asyncio.create_task(self._listen())

    async def stop(self):
        if self._listener:
            self._listener.cancel()
            with suppress(asyncio.CancelledError):
                await self._listener
        for user_id, sockets in list(self._connections.items()):
            for socket in list(sockets):
                with suppress(Exception):
                    await socket.close(code=1012)
                await self.disconnect(user_id, socket)
        self._connections.clear()
        if self._redis:
            await self._redis.aclose()
            self._redis = None

    async def _listen(self):
        while True:
            try:
                async with self._redis.pubsub() as subscription:
                    await subscription.subscribe(self._channel)
                    async for message in subscription.listen():
                        if message["type"] == "message":
                            event = json.loads(message["data"])
                            await asyncio.gather(*(self.emit_to_user(uid, event["payload"]) for uid in event["users"]))
            except asyncio.CancelledError:
                raise
            except Exception:
                logger.warning("Realtime subscription unavailable; retrying")
                await asyncio.sleep(2)

    async def connect(self, user_id: int, websocket: WebSocket) -> bool:
        async with self._lock:
            lease = uuid.uuid4().hex
            allowed = len(self._connections.get(user_id, ())) < settings.websocket_connections_per_user
            if allowed and self._redis:
                try:
                    allowed = bool(await asyncio.wait_for(self._redis.eval(_LEASE, 1, f"ws:connections:{user_id}", lease,
                        settings.websocket_connections_per_user, settings.websocket_auth_check_seconds * 3), timeout=2))
                except Exception:
                    await websocket.close(code=1013, reason="Temporarily unavailable")
                    return False
            if not allowed:
                await websocket.close(code=1008, reason="Connection limit reached")
                return False
            self._leases[websocket] = (user_id, lease)
            protocols = websocket.headers.get("sec-websocket-protocol", "")
            try:
                await websocket.accept(subprotocol="trustmarket" if "trustmarket" in [p.strip() for p in protocols.split(",")] else None)
            except Exception:
                self._leases.pop(websocket, None)
                if self._redis:
                    with suppress(Exception):
                        await asyncio.wait_for(self._redis.zrem(f"ws:connections:{user_id}", lease), timeout=2)
                raise
            self._connections[user_id].add(websocket)
            return True

    async def renew(self, websocket: WebSocket) -> bool:
        if not self._redis:
            return True
        user_id, lease = self._leases[websocket]
        return bool(await asyncio.wait_for(self._redis.eval(_LEASE, 1, f"ws:connections:{user_id}", lease,
            settings.websocket_connections_per_user, settings.websocket_auth_check_seconds * 3), timeout=2))

    async def disconnect(self, user_id: int, websocket: WebSocket) -> None:
        async with self._lock:
            sockets = self._connections.get(user_id)
            if sockets:
                sockets.discard(websocket)
                if not sockets:
                    self._connections.pop(user_id, None)
            lease = self._leases.pop(websocket, None)
        if lease and self._redis:
            with suppress(Exception):
                await asyncio.wait_for(self._redis.zrem(f"ws:connections:{user_id}", lease[1]), timeout=2)

    async def emit_to_user(self, user_id: int, payload: dict) -> None:
        async with self._lock:
            sockets = list(self._connections.get(user_id, set()))

        async def deliver(socket):
            try:
                await asyncio.wait_for(socket.send_json(payload), timeout=2)
            except Exception:
                await self.disconnect(user_id, socket)
                with suppress(Exception):
                    await socket.close(code=1013)
        await asyncio.gather(*(deliver(socket) for socket in sockets))

    async def emit_to_many(self, user_ids: list[int], payload: dict) -> None:
        ids = list(set(user_ids))
        if self._redis:
            try:
                await asyncio.wait_for(self._redis.publish(self._channel, json.dumps({"users": ids, "payload": payload})), timeout=2)
                return
            except Exception:
                logger.warning("Realtime publish unavailable; clients can recover from persisted messages")
        await asyncio.gather(*(self.emit_to_user(uid, payload) for uid in ids))


realtime_hub = RealtimeHub()
