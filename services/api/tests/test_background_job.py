import asyncio
from unittest.mock import Mock

import pytest

import app.main as main


def test_stale_loop_recovers_after_transient_failure(monkeypatch):
    db = Mock()
    job = Mock(side_effect=[RuntimeError("Temporary database outage"), 0])
    monkeypatch.setattr(main, "SessionLocal", lambda: db)
    monkeypatch.setattr(main, "run_stale_job", job)

    async def next_interval(_):
        if job.call_count == 2:
            raise asyncio.CancelledError()

    monkeypatch.setattr(main.asyncio, "sleep", next_interval)
    with pytest.raises(asyncio.CancelledError):
        asyncio.run(main.stale_job_loop())
    assert job.call_count == 2
    db.rollback.assert_called_once()
    assert db.close.call_count == 2
