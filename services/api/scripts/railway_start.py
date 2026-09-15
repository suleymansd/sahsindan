"""Run one API worker and maintenance against the same Railway volume.

Railway mounts volumes as root. Only directory ownership is initialized as
root; both long-running processes run as the existing unprivileged app user.
"""
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

API_ROOT = Path(__file__).resolve().parents[1]


def prepare_storage(root: Path):
    if os.environ.get("RAILWAY_VOLUME_MOUNT_PATH") != str(root) or not root.is_mount():
        raise RuntimeError("A persistent Railway volume must be mounted at /app/storage")
    if root.is_symlink():
        raise RuntimeError("Storage mount must not be a symlink")
    if os.geteuid() == 0:
        os.chown(root, 10001, 10001)
        os.setgroups([])
        os.setgid(10001)
        os.setuid(10001)
    if not os.access(root, os.W_OK | os.X_OK):
        raise RuntimeError("Storage mount is not writable by the application user")


def supervise(commands, *, cwd=API_ROOT, stop_timeout=10):
    children = []
    stopping = False

    def request_stop(signum, frame):  # noqa: ARG001
        nonlocal stopping
        stopping = True

    previous = {sig: signal.signal(sig, request_stop) for sig in (signal.SIGTERM, signal.SIGINT)}
    try:
        for command in commands:
            if stopping:
                break
            children.append(subprocess.Popen(command, cwd=cwd, start_new_session=True))
        while not stopping:
            if any(child.poll() is not None for child in children):
                # Even a clean early exit is unexpected for these two services.
                # Restart the whole container; never leave only one running.
                return 1
            time.sleep(0.2)
        return 0
    finally:
        for child in children:
            try:
                os.killpg(child.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
        deadline = time.monotonic() + stop_timeout
        for child in children:
            try:
                child.wait(timeout=max(0, deadline - time.monotonic()))
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(child.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                child.wait()
        for sig, handler in previous.items():
            signal.signal(sig, handler)


def main():
    port = int(os.environ.get("PORT", "8000"))
    if not 1 <= port <= 65535:
        raise ValueError("PORT must be between 1 and 65535")
    prepare_storage(API_ROOT / "storage")
    # This prevents duplicate maintenance if an operator changes the env.
    os.environ["DISABLE_STALE_JOB"] = "true"
    os.environ["DISABLE_STORAGE"] = "true"
    return supervise([
        [sys.executable, "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0",
         "--port", str(port), "--workers", "1", "--limit-concurrency", "40",
         "--backlog", "64", "--timeout-keep-alive", "5", "--ws-max-size", "2048",
         "--proxy-headers", "--forwarded-allow-ips", "*", "--no-access-log"],
        [sys.executable, "scripts/maintenance.py"],
    ])


if __name__ == "__main__":
    raise SystemExit(main())
