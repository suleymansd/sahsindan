"""Isolated real Redis checks. Set REDIS_TEST_BINARY; never touches configured Redis."""
import asyncio
from concurrent.futures import ThreadPoolExecutor
import os
from tempfile import TemporaryDirectory
import subprocess
import time

import pytest
from redis import Redis

from app.core.config import settings
from app.core import rate_limit as limits
from app.services.realtime import RealtimeHub


@pytest.fixture()
def real_redis(tmp_path):
    binary = os.environ.get("REDIS_TEST_BINARY")
    if not binary:
        pytest.skip("Set REDIS_TEST_BINARY to run real Redis integration checks")
    short = TemporaryDirectory(prefix="tm-r-", dir="/private/tmp")
    from pathlib import Path
    socket = Path(short.name) / "r.sock"
    process = subprocess.Popen([binary, "--port", "0", "--unixsocket", str(socket),
        "--unixsocketperm", "700", "--save", "", "--appendonly", "no", "--dir", str(tmp_path)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    client = Redis(unix_socket_path=str(socket), decode_responses=True)
    try:
        for _ in range(100):
            try:
                if client.ping():
                    break
            except Exception:
                time.sleep(.02)
        else:
            pytest.fail("Disposable Redis did not start")
        yield client, f"unix://{socket}"
    finally:
        client.close()
        process.terminate()
        process.wait(timeout=10)
        short.cleanup()


def test_real_atomic_quota_and_expiry(real_redis, monkeypatch):
    client, _ = real_redis
    monkeypatch.setattr(limits, "redis_client", client)
    def attempt(_):
        try:
            limits.consume_limit("test:quota", 17, 1)
            return True
        except limits.RateLimitException:
            return False
    with ThreadPoolExecutor(max_workers=40) as pool:
        assert sum(pool.map(attempt, range(150))) == 17
    assert client.get("test:quota") == "17"
    time.sleep(1.05)
    assert attempt(0)


class Socket:
    headers = {"sec-websocket-protocol": "trustmarket, bearer.test"}
    def __init__(self):
        self.messages = []
        self.closed = None
    async def accept(self, **kwargs):
        self.accepted = kwargs
    async def send_json(self, payload):
        self.messages.append(payload)
    async def close(self, code, **kwargs):
        self.closed = code


def test_realtime_cross_worker_delivery_and_shared_socket_limit(real_redis, monkeypatch):
    client, url = real_redis
    monkeypatch.setattr(settings, "redis_url", url)
    monkeypatch.setattr(settings, "websocket_connections_per_user", 2)
    async def scenario():
        first, second = RealtimeHub(), RealtimeHub()
        await first.start()
        await second.start()
        try:
            for _ in range(100):
                if client.pubsub_numsub("trustmarket:realtime")[0][1] == 2:
                    break
                await asyncio.sleep(.02)
            else:
                pytest.fail("Workers failed to subscribe")
            a, b, rejected, replacement = Socket(), Socket(), Socket(), Socket()
            assert await first.connect(7, a)
            assert await second.connect(7, b)
            assert not await second.connect(7, rejected)
            assert rejected.closed == 1008
            assert await first.renew(a)
            await first.emit_to_many([7, 7], {"type": "new_message", "id": 123})
            for _ in range(100):
                if a.messages and b.messages:
                    break
                await asyncio.sleep(.01)
            assert a.messages == b.messages == [{"type": "new_message", "id": 123}]
            await first.disconnect(7, a)
            assert await second.connect(7, replacement)
        finally:
            await first.stop()
            await second.stop()
        assert client.zcard("ws:connections:7") == 0
    asyncio.run(scenario())
