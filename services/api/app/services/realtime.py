from __future__ import annotations

import asyncio
from collections import defaultdict

from fastapi import WebSocket


class RealtimeHub:
    def __init__(self) -> None:
        self._connections: dict[int, set[WebSocket]] = defaultdict(set)
        self._lock = asyncio.Lock()

    async def connect(self, user_id: int, websocket: WebSocket) -> None:
        await websocket.accept()
        async with self._lock:
            self._connections[user_id].add(websocket)

    async def disconnect(self, user_id: int, websocket: WebSocket) -> None:
        async with self._lock:
            sockets = self._connections.get(user_id)
            if not sockets:
                return
            sockets.discard(websocket)
            if not sockets:
                self._connections.pop(user_id, None)

    async def emit_to_user(self, user_id: int, payload: dict) -> None:
        async with self._lock:
            sockets = list(self._connections.get(user_id, set()))
        if not sockets:
            return

        stale: list[WebSocket] = []
        for socket in sockets:
            try:
                await socket.send_json(payload)
            except Exception:  # noqa: BLE001
                stale.append(socket)

        for socket in stale:
            await self.disconnect(user_id, socket)

    async def emit_to_many(self, user_ids: list[int], payload: dict) -> None:
        unique_ids = list(set(user_ids))
        if not unique_ids:
            return
        await asyncio.gather(*(self.emit_to_user(user_id, payload) for user_id in unique_ids))


realtime_hub = RealtimeHub()

