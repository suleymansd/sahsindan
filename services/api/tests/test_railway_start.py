import importlib.util
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "railway_start.py"
spec = importlib.util.spec_from_file_location("railway_start", SCRIPT)
runtime = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runtime)


def test_start_rejects_ephemeral_storage(tmp_path, monkeypatch):
    monkeypatch.setenv("RAILWAY_VOLUME_MOUNT_PATH", str(tmp_path))
    with pytest.raises(RuntimeError, match="persistent Railway volume"):
        runtime.prepare_storage(tmp_path)


def test_start_drops_privileges_before_using_volume(tmp_path, monkeypatch):
    monkeypatch.setenv("RAILWAY_VOLUME_MOUNT_PATH", str(tmp_path))
    monkeypatch.setattr(Path, "is_mount", lambda _: True)
    monkeypatch.setattr(os, "geteuid", lambda: 0)
    calls = []
    for name in ("chown", "setgroups", "setgid", "setuid"):
        monkeypatch.setattr(os, name, lambda *args, name=name: calls.append((name, args)))
    monkeypatch.setattr(os, "access", lambda *_: True)
    runtime.prepare_storage(tmp_path)
    assert calls == [("chown", (tmp_path, 10001, 10001)), ("setgroups", ([],)),
                     ("setgid", (10001,)), ("setuid", (10001,))]


def test_start_rejects_readonly_volume(tmp_path, monkeypatch):
    monkeypatch.setenv("RAILWAY_VOLUME_MOUNT_PATH", str(tmp_path))
    monkeypatch.setattr(Path, "is_mount", lambda _: True)
    monkeypatch.setattr(os, "geteuid", lambda: 10001)
    monkeypatch.setattr(os, "access", lambda *_: False)
    with pytest.raises(RuntimeError, match="not writable"):
        runtime.prepare_storage(tmp_path)


@pytest.mark.parametrize("code", [0, 1])
def test_any_child_exit_stops_peer_and_fails_container(tmp_path, code):
    pidfile = tmp_path / "peer.pid"
    peer = [sys.executable, "-c",
            "import os,pathlib,time; pathlib.Path('peer.pid').write_text(str(os.getpid())); time.sleep(30)"]
    failing = [sys.executable, "-c",
               f"import pathlib,time;\nwhile not pathlib.Path('peer.pid').exists(): time.sleep(.01)\nraise SystemExit({code})"]
    assert runtime.supervise([peer, failing], cwd=tmp_path, stop_timeout=2) == 1
    with pytest.raises(ProcessLookupError):
        os.kill(int(pidfile.read_text()), 0)


def test_sigterm_stops_children_and_supervisor(tmp_path):
    harness = tmp_path / "harness.py"
    harness.write_text(
        "import importlib.util,sys\n"
        f"spec=importlib.util.spec_from_file_location('runtime', {str(SCRIPT)!r})\n"
        "runtime=importlib.util.module_from_spec(spec); spec.loader.exec_module(runtime)\n"
        "child=[sys.executable,'-c',\"import os,pathlib,time; pathlib.Path('child.pid').write_text(str(os.getpid())); time.sleep(30)\"]\n"
        "raise SystemExit(runtime.supervise([child], stop_timeout=2, cwd='.'))\n"
    )
    process = subprocess.Popen([sys.executable, str(harness)], cwd=tmp_path)
    try:
        deadline = time.monotonic() + 5
        while not (tmp_path / "child.pid").exists():
            assert process.poll() is None and time.monotonic() < deadline
            time.sleep(.02)
        process.send_signal(signal.SIGTERM)
        assert process.wait(timeout=5) == 0
        with pytest.raises(ProcessLookupError):
            os.kill(int((tmp_path / "child.pid").read_text()), 0)
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()


def test_invalid_port_never_starts_services(monkeypatch):
    monkeypatch.setenv("PORT", "0")
    with pytest.raises(ValueError, match="PORT"):
        runtime.main()
