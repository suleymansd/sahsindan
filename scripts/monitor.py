"""Free host-side readiness/disk/container checks; nonzero exit for systemd/cron."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import shutil
import subprocess
import urllib.request

from backup import compose


def inspect(url, disk_path, minimum_free_gib, backup_dir):
    checks = {}
    try:
        with urllib.request.urlopen(url, timeout=10) as response:
            checks["https_ready"] = response.status == 200 and url.startswith("https://") and response.geturl().startswith("https://")
    except Exception:
        checks["https_ready"] = False
    free = shutil.disk_usage(disk_path).free
    checks["disk"] = free >= minimum_free_gib * 1024 ** 3
    try:
        result = subprocess.run(compose() + ["ps", "--all", "--format", "json"], check=True, capture_output=True, text=True, timeout=20)
        raw = result.stdout.strip()
        rows = json.loads(raw) if raw.startswith("[") else [json.loads(line) for line in raw.splitlines() if line]
        states = {row["Service"]: row for row in rows}
        checks["containers"] = all(states.get(name, {}).get("State") == "running" and states[name].get("Health") in ("", "healthy", None) for name in ("api", "maintenance", "web", "edge", "postgres", "redis"))
    except Exception:
        checks["containers"] = False
    snapshots = list(backup_dir.glob("*.tar.age")) if backup_dir.exists() else []
    now = datetime.now(timezone.utc).timestamp()
    checks["backup_recent"] = bool(snapshots) and now - max(path.stat().st_mtime for path in snapshots) < 36 * 3600
    return {"time": datetime.now(timezone.utc).isoformat(), "ok": all(checks.values()), "checks": checks, "free_gib": round(free / 1024 ** 3, 2)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", required=True, help="Public HTTPS /ready URL")
    parser.add_argument("--disk", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--minimum-free-gib", type=int, default=2)
    parser.add_argument("--backup-dir", type=Path, default=Path(__file__).resolve().parents[1] / "backups")
    args = parser.parse_args()
    result = inspect(args.url, args.disk, args.minimum_free_gib, args.backup_dir)
    print(json.dumps(result))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
