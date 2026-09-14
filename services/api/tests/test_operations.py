import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock

import pytest
from pydantic import ValidationError

from app.core.config import Settings


@pytest.mark.parametrize("sender, starttls", [("", True), ("sender@example.test", False)])
def test_production_rejects_incomplete_or_unencrypted_smtp(sender, starttls):
    with pytest.raises(ValidationError, match="Production SMTP"):
        Settings(_env_file=None, app_env="production", database_url="postgresql+psycopg://test/test",
                 redis_url="redis://localhost", public_api_url="https://app.example.test",
                 public_web_url="https://app.example.test", smtp_host="smtp.example.test",
                 smtp_sender=sender, smtp_starttls=starttls)


def test_monitor_detects_missing_backup_disk_pressure_and_stopped_service(tmp_path, monkeypatch):
    scripts = Path(__file__).resolve().parents[3] / "scripts"
    monkeypatch.syspath_prepend(str(scripts))
    spec = importlib.util.spec_from_file_location("audit_monitor", scripts / "monitor.py")
    monitor = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(monitor)
    response = Mock(status=200)
    response.geturl.return_value = "https://app.example.test/ready"
    response.__enter__ = Mock(return_value=response)
    response.__exit__ = Mock(return_value=False)
    monkeypatch.setattr(monitor.urllib.request, "urlopen", Mock(return_value=response))
    rows = [{"Service": service, "State": "running", "Health": "healthy"} for service in ("api", "maintenance", "web", "edge", "postgres", "redis")]
    command = Mock(return_value=SimpleNamespace(stdout=json.dumps(rows)))
    monkeypatch.setattr(monitor.subprocess, "run", command)
    monkeypatch.setattr(monitor.shutil, "disk_usage", lambda _: SimpleNamespace(free=3 * 1024 ** 3))
    assert monitor.inspect("https://app.example.test/ready", tmp_path, 2, tmp_path)["checks"]["backup_recent"] is False
    (tmp_path / "snapshot.tar.age").write_bytes(b"synthetic fixture")
    assert monitor.inspect("https://app.example.test/ready", tmp_path, 2, tmp_path)["ok"] is True
    rows[0]["State"] = "exited"
    command.return_value.stdout = json.dumps(rows)
    monkeypatch.setattr(monitor.shutil, "disk_usage", lambda _: SimpleNamespace(free=1024))
    result = monitor.inspect("https://app.example.test/ready", tmp_path, 2, tmp_path)
    assert not result["ok"] and not result["checks"]["disk"] and not result["checks"]["containers"]
    response.geturl.return_value = "http://app.example.test/ready"
    assert not monitor.inspect("https://app.example.test/ready", tmp_path, 2, tmp_path)["checks"]["https_ready"]
