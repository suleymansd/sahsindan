"""Encrypted local snapshots and a restore drill in a disposable PostgreSQL container.

Uses age's authenticated encryption, not a home-grown encryption format.
Never overwrites the live database. The identity belongs on a separate existing device.
"""
import argparse
import csv
import fcntl
from datetime import datetime, timezone
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]


def run(command, **kwargs):
    return subprocess.run(command, check=True, **kwargs)


def compose():
    result = ["docker", "compose", "--env-file", os.environ.get("PRODUCTION_ENV_FILE", str(ROOT / "infra/.env.production")), "-f", str(ROOT / "infra/compose.production.yml")]
    if os.environ.get("PRODUCTION_COMPOSE_OVERRIDE"):
        result += ["-f", os.environ["PRODUCTION_COMPOSE_OVERRIDE"]]
    if os.environ.get("COMPOSE_PROJECT_NAME"):
        result += ["-p", os.environ["COMPOSE_PROJECT_NAME"]]
    return result


def api_tool(*args, mounts=()):
    return compose() + ["run", "--rm", "--no-deps", "-T", "--user", "0", *mounts, "api", *args]


def make_key(identity):
    identity.parent.mkdir(parents=True, exist_ok=True)
    with identity.open("xb") as output:
        os.chmod(identity, 0o600)
        try:
            run(api_tool("age-keygen"), stdout=output)
        except Exception:
            identity.unlink(missing_ok=True)
            raise
    with identity.open("rb") as source:
        public = run(api_tool("age-keygen", "-y", "/dev/stdin"), stdin=source, capture_output=True).stdout.decode().strip()
    identity.with_suffix(identity.suffix + ".pub").write_text(public + "\n")
    print("Created private identity and public .pub file. Keep the identity off the server; never commit it.")


def snapshot(destination, recipient):
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists():
        raise ValueError("Snapshot already exists")
    if not recipient.startswith("age1") or len(recipient) > 100:
        raise ValueError("Supply an age public recipient (the .pub file contents)")
    # No automatic deletion of older backups; an operator controls retention/off-device copies.
    database_size = int(run(compose() + ["exec", "-T", "postgres", "psql", "-U", "trustmarket", "-d", "trustmarket", "-Atc", "SELECT pg_database_size(current_database())"], capture_output=True, text=True).stdout.strip())
    uploads_size = int(run(api_tool("python", "-c", "from pathlib import Path; print(sum(p.stat().st_size for p in Path('/app/storage').rglob('*') if p.is_file()))"), capture_output=True, text=True).stdout.strip())
    redis_size = int(run(compose() + ["exec", "-T", "redis", "du", "-sk", "/data"], capture_output=True, text=True).stdout.split()[0]) * 1024
    if shutil.disk_usage(destination.parent).free < 2 * (database_size + uploads_size + redis_size) + 256 * 1024 ** 2:
        raise ValueError("Insufficient free disk for plaintext staging plus encrypted output; services were not stopped")
    with tempfile.TemporaryDirectory(prefix=".snapshot-", dir=destination.parent) as directory:
        stage = Path(directory)
        active = run(compose() + ["ps", "--services", "--status", "running"], capture_output=True, text=True).stdout.split()
        resume = [service for service in ("api", "maintenance", "redis") if service in active]
        if "api" not in active or "redis" not in active or "postgres" not in active:
            raise ValueError("API, PostgreSQL and Redis must be running for a consistent snapshot")
        resume_ids = [run(compose() + ["ps", "-aq", service], capture_output=True, text=True).stdout.strip() for service in reversed(resume)]
        try:
            run(compose() + ["stop", *resume], stdout=subprocess.DEVNULL)
            with (stage / "database.dump").open("wb") as output:
                run(compose() + ["exec", "-T", "postgres", "pg_dump", "-U", "trustmarket", "-Fc", "trustmarket"], stdout=output)
            with (stage / "uploads.tar.gz").open("wb") as output:
                run(api_tool("tar", "-C", "/app/storage", "-czf", "-", "."), stdout=output)
            redis_id = run(compose() + ["ps", "-aq", "redis"], capture_output=True, text=True).stdout.strip()
            run(["docker", "cp", redis_id + ":/data", str(stage / "redis")], stdout=subprocess.DEVNULL)
        finally:
            run(["docker", "start", *resume_ids], stdout=subprocess.DEVNULL)
        (stage / "manifest.json").write_text(json.dumps({"version": 1, "created_at": datetime.now(timezone.utc).isoformat(), "contains": ["postgresql", "uploads", "redis_budgets"]}))
        partial = destination.with_suffix(destination.suffix + ".partial")
        try:
            with partial.open("xb") as output:
                os.chmod(partial, 0o600)
                process = subprocess.Popen(api_tool("age", "-r", recipient), stdin=subprocess.PIPE, stdout=output)
                try:
                    with tarfile.open(fileobj=process.stdin, mode="w|") as archive:
                        for name in ("database.dump", "uploads.tar.gz", "manifest.json", "redis"):
                            archive.add(stage / name, arcname=name, recursive=True)
                    process.stdin.close()
                    if process.wait() != 0:
                        raise RuntimeError("age encryption failed")
                    output.flush()
                    os.fsync(output.fileno())
                finally:
                    if process.poll() is None:
                        process.kill()
                        process.wait()
            # Hard-link prevents concurrent callers from replacing an existing backup.
            os.link(partial, destination)
        finally:
            partial.unlink(missing_ok=True)
    print("Encrypted snapshot created: " + str(destination))


def restore_check(snapshot_file, identity):
    """Actually restore SQL and validate every referenced file; always remove the drill."""
    if shutil.disk_usage(tempfile.gettempdir()).free < 2 * snapshot_file.stat().st_size + 256 * 1024 ** 2:
        raise ValueError("Insufficient temporary disk for restore verification")
    name = "trustmarket-restore-" + uuid.uuid4().hex[:12]
    with tempfile.TemporaryDirectory(prefix="trustmarket-restore-") as directory:
        stage = Path(directory)
        with snapshot_file.open("rb") as source, (stage / "snapshot.tar").open("wb") as output:
            run(api_tool("age", "--decrypt", "-i", "/run/backup-identity", mounts=("-v", str(identity.resolve()) + ":/run/backup-identity:ro")), stdin=source, stdout=output)
        # Decryption authenticates the entire stream before any database is touched.
        with tarfile.open(stage / "snapshot.tar") as archive:
            for member in archive.getmembers():
                parts = Path(member.name).parts
                if not parts or member.name.startswith("/") or ".." in parts or not (member.isfile() or member.isdir()) or parts[0] not in {"database.dump", "uploads.tar.gz", "manifest.json", "redis"}:
                    raise ValueError("Unexpected snapshot member")
            archive.extractall(stage, filter="data")
        if json.loads((stage / "manifest.json").read_text())["version"] != 1:
            raise ValueError("Unsupported snapshot version")
        uploads = {}
        with tarfile.open(stage / "uploads.tar.gz") as archive:
            for member in archive:
                parts = Path(member.name).parts
                if member.name.startswith("/") or ".." in parts or not (member.isfile() or member.isdir()):
                    raise ValueError("Unsafe upload archive member")
                if member.isfile():
                    # Read every byte to exercise gzip CRC and detect truncated archives.
                    file = archive.extractfile(member)
                    size = 0
                    while chunk := file.read(1024 * 1024):
                        size += len(chunk)
                    uploads[str(Path(member.name))] = size
        started = False
        redis_started = False
        redis_name = name + "-redis"
        try:
            run(["docker", "run", "-d", "--name", name, "--network", "none", "--memory", "512m", "--cpus", "1", "--tmpfs", "/var/lib/postgresql/data", "-e", "POSTGRES_HOST_AUTH_METHOD=trust", "-e", "POSTGRES_USER=trustmarket", "-e", "POSTGRES_DB=trustmarket", "postgres:16-alpine"], stdout=subprocess.DEVNULL)
            started = True
            for _ in range(60):
                if subprocess.run(["docker", "exec", name, "pg_isready", "-h", "127.0.0.1", "-U", "trustmarket"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
                    break
                time.sleep(1)
            else:
                raise RuntimeError("Restore database did not become ready")
            with (stage / "database.dump").open("rb") as source:
                run(["docker", "exec", "-i", name, "pg_restore", "--exit-on-error", "--no-owner", "-U", "trustmarket", "-d", "trustmarket"], stdin=source)
            sql = "COPY (SELECT s3_key, size_bytes FROM listing_photos UNION ALL SELECT s3_key, size_bytes FROM verification_assets) TO STDOUT WITH CSV"
            rows = run(["docker", "exec", name, "psql", "-U", "trustmarket", "-d", "trustmarket", "-c", sql], capture_output=True, text=True).stdout
            checked = 0
            for key, size in csv.reader(io.StringIO(rows)):
                if key not in uploads or (int(size) > 0 and uploads[key] != int(size)):
                    raise ValueError("Restored database references a missing or incorrectly sized file")
                checked += 1
            # Redis files are included so restoring budgets need not reset billing caps.
            if not any(path.is_file() for path in (stage / "redis").rglob("*")):
                raise ValueError("Snapshot lacks persisted Redis budgets")
            run(["docker", "create", "--name", redis_name, "--network", "none", "--memory", "192m", "redis:7.4.11-alpine", "redis-server", "--appendonly", "yes", "--maxmemory", "128mb", "--maxmemory-policy", "noeviction"], stdout=subprocess.DEVNULL)
            redis_started = True
            run(["docker", "cp", str(stage / "redis") + "/.", redis_name + ":/data"], stdout=subprocess.DEVNULL)
            run(["docker", "start", redis_name], stdout=subprocess.DEVNULL)
            for _ in range(30):
                probe = subprocess.run(["docker", "exec", redis_name, "redis-cli", "ping"], capture_output=True, text=True)
                if probe.returncode == 0 and probe.stdout.strip() == "PONG":
                    break
                time.sleep(1)
            else:
                raise RuntimeError("Restored Redis persistence did not load")
            info = run(["docker", "exec", redis_name, "redis-cli", "INFO", "persistence"], capture_output=True, text=True).stdout
            assert "aof_enabled:1" in info
            restored_keys = int(run(["docker", "exec", redis_name, "redis-cli", "DBSIZE"], capture_output=True, text=True).stdout.strip())
            print(json.dumps({"restored_redis_keys": restored_keys, "redis_restore": "passed", "database_restore": "passed", "referenced_files_checked": checked, "upload_files_checked": len(uploads), "encryption": "age authenticated", "live_data_changed": False}))
        finally:
            if redis_started:
                run(["docker", "rm", "-fv", redis_name], stdout=subprocess.DEVNULL)
            if started:
                run(["docker", "rm", "-f", name], stdout=subprocess.DEVNULL)


def main():
    os.umask(0o077)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["key", "backup", "restore-check"])
    parser.add_argument("--identity", type=Path)
    parser.add_argument("--snapshot", type=Path)
    parser.add_argument("--recipient")
    args = parser.parse_args()
    if args.action == "key" and args.identity:
        make_key(args.identity)
    elif args.action == "backup" and args.snapshot and args.recipient:
        lock_dir = ROOT / "backups"
        lock_dir.mkdir(mode=0o700, exist_ok=True)
        with (lock_dir / ".snapshot.lock").open("a") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                parser.error("Another snapshot is already running")
            snapshot(args.snapshot, args.recipient)
    elif args.action == "restore-check" and args.snapshot and args.identity:
        restore_check(args.snapshot, args.identity)
    else:
        parser.error("key needs --identity; backup needs --snapshot/--recipient; restore-check needs --snapshot/--identity")


if __name__ == "__main__":
    main()
