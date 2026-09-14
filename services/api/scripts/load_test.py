"""Bounded load probe against disposable PostgreSQL + Redis + two local API workers.

Does not contact production, reuse a development DB, or publish anything.
Reports observed capacity of this machine, not a production capacity guarantee.
"""
import argparse
import base64
import secrets
from concurrent.futures import ThreadPoolExecutor
from collections import Counter
import getpass
import json
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
from tempfile import TemporaryDirectory
import time

import httpx
from sqlalchemy.engine import URL

API_ROOT = Path(__file__).resolve().parents[1]


def seed(users, listings, output):
    sys.path.insert(0, str(API_ROOT))
    from app.db.models import CarDetail, Listing, ListingState, Profile, User, UserRole
    from app.db.session import SessionLocal
    from app.core.security import hash_password, create_access_token
    hashed = hash_password("DisposableLoadTest123!")
    tokens = []
    with SessionLocal() as db:
        for index in range(users):
            user = User(email=f"load{index}@example.test", phone=f"555{index:07}", password_hash=hashed, role=UserRole.USER_VERIFIED)
            user.profile = Profile(name=f"Load user {index}", city="ISTANBUL")
            db.add(user)
            db.flush()
            tokens.append(create_access_token(user.id, user.role.value, user.password_hash))
        for index in range(listings):
            listing = Listing(owner_id=(index % users) + 1, state=ListingState.PUBLISHED, title=f"Load vehicle {index}",
                description="Disposable capacity fixture", price=100000 + index, city="ISTANBUL", district="Kadikoy")
            listing.car_details = CarDetail(brand="Audi", model="A4", year=2020, mileage=45000, transmission="Automatic", fuel="Gasoline", color="White")
            db.add(listing)
        db.commit()
    Path(output).write_text(json.dumps(tokens))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pg-bin", type=Path, required=True)
    parser.add_argument("--redis-bin", type=Path, required=True)
    parser.add_argument("--users", type=int, default=50, choices=range(1, 201), metavar="1..200")
    parser.add_argument("--requests", type=int, default=20, choices=range(1, 101), metavar="1..100")
    parser.add_argument("--duration", type=int, default=0, help="Paced mixed traffic for 10..600 seconds; zero keeps the burst probe")
    parser.add_argument("--listings", type=int, default=1000)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.duration and not 10 <= args.duration <= 600:
        parser.error("duration must be zero or 10..600 seconds")
    if not 1 <= args.listings <= 10000:
        parser.error("listings must be 1..10000")
    with TemporaryDirectory(prefix="tm-load-", dir="/private/tmp" if sys.platform == "darwin" else "/tmp") as directory:
        root = Path(directory)
        data = root / "postgres"
        processes = []
        pg_started = False
        with (root / "services.log").open("w") as log:
            try:
                subprocess.run([str(args.pg_bin / "initdb"), "-D", str(data), "-A", "trust", "--no-locale", "-E", "UTF8"], check=True, stdout=log, stderr=log)
                subprocess.run([str(args.pg_bin / "pg_ctl"), "-D", str(data), "-l", str(root / "postgres.log"), "-o", f"-k {root} -h '' -p 55492", "-w", "start"], check=True, stdout=log, stderr=log)
                pg_started = True
                redis_socket = root / "r.sock"
                processes.append(subprocess.Popen([str(args.redis_bin), "--port", "0", "--unixsocket", str(redis_socket), "--save", "", "--appendonly", "no", "--dir", str(root)], stdout=log, stderr=log))
                url = URL.create("postgresql+psycopg", username=getpass.getuser(), database="postgres", query={"host": str(root), "port": "55492"}).render_as_string(hide_password=False)
                env = dict(os.environ, DATABASE_URL=url, REDIS_URL=f"unix://{redis_socket}", APP_ENV="production", DISABLE_STALE_JOB="1", DISABLE_STORAGE="1",
                    MFA_ENCRYPTION_KEY=base64.urlsafe_b64encode(secrets.token_bytes(32)).decode(), JWT_SECRET="load-access-secret-at-least-32-characters", JWT_REFRESH_SECRET="load-refresh-secret-at-least-32-characters", PUBLIC_API_URL="https://load.example.test", PUBLIC_WEB_URL="https://load.example.test", CORS_ORIGINS="https://load.example.test",
                    SQLALCHEMY_POOL_SIZE="5", SQLALCHEMY_MAX_OVERFLOW="5", SQLALCHEMY_POOL_TIMEOUT="5")
                subprocess.run([sys.executable, "-m", "alembic", "upgrade", "head"], cwd=API_ROOT, env=env, check=True, stdout=log, stderr=log)
                token_file = root / "tokens.json"
                subprocess.run([sys.executable, str(Path(__file__).resolve()), "seed", str(args.users), str(args.listings), str(token_file)], cwd=API_ROOT, env=env, check=True, stdout=log, stderr=log)
                with socket.socket() as port_socket:
                    port_socket.bind(("127.0.0.1", 0))
                    port = port_socket.getsockname()[1]
                base = f"http://127.0.0.1:{port}"
                api = subprocess.Popen([sys.executable, "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", str(port), "--workers", "2", "--limit-concurrency", "100", "--proxy-headers", "--forwarded-allow-ips", "127.0.0.1", "--no-access-log"], cwd=API_ROOT, env=env, stdout=log, stderr=log, start_new_session=True)
                processes.append(api)
                with httpx.Client(timeout=2) as probe:
                    for _ in range(100):
                        try:
                            if probe.get(base + "/ready").status_code == 200:
                                break
                        except httpx.HTTPError:
                            pass
                        time.sleep(.1)
                    else:
                        raise RuntimeError("Disposable API did not become ready")
                tokens = json.loads(token_file.read_text())
                # Each session represents a different client behind a trusted local proxy.
                clients = [httpx.Client(base_url=base, timeout=20, headers={"Authorization": f"Bearer {token}", "X-Forwarded-For": f"10.25.{index // 250}.{index % 250 + 1}"}) for index, token in enumerate(tokens)]
                def visit(index):
                    results = []
                    request = 0
                    deadline = time.perf_counter() + args.duration
                    while (time.perf_counter() < deadline) if args.duration else (request < args.requests):
                        path = "/api/auth/me" if request % 5 == 0 else f"/api/listings?limit=24&offset={(request % 3) * 24}"
                        method = "GET"
                        # One write every 5 seconds/session; bounded below real user quotas.
                        if args.duration and request % 10 in (1, 6):
                            listing_id = ((index + 1) % args.listings) + 1
                            path = f"/api/listings/{listing_id}/favorite"
                            method = "POST" if request % 10 == 1 else "DELETE"
                        elif args.duration and request % 10 == 3:
                            path = "/api/favorites?limit=24"
                        started = time.perf_counter()
                        try:
                            response = clients[index].request(method, path)
                            status, size = str(response.status_code), len(response.content)
                            detail = response.text[:200] if response.status_code >= 400 else ""
                        except httpx.HTTPError:
                            status, size, detail = "transport_error", 0, "transport failure"
                        results.append((status, (time.perf_counter() - started) * 1000, size, method, detail))
                        request += 1
                        if args.duration:
                            time.sleep(max(0, 0.5 - (time.perf_counter() - started)))
                    return results
                started = time.perf_counter()
                try:
                    with ThreadPoolExecutor(max_workers=args.users) as pool:
                        results = [item for batch in pool.map(visit, range(args.users)) for item in batch]
                finally:
                    for client in clients:
                        client.close()
                elapsed = time.perf_counter() - started
                latency = sorted(item[1] for item in results)
                statuses = Counter(item[0] for item in results)
                report = {"environment": "disposable local PostgreSQL/Redis, 2 Uvicorn workers; direct API, no TLS/proxy, no uploads or websocket load", "concurrent_sessions": args.users, "seeded_listings": args.listings,
                    "requests": len(results), "elapsed_seconds": round(elapsed, 2), "requests_per_second": round(len(results) / elapsed, 2),
                    "latency_ms": {str(p): round(latency[min(len(latency) - 1, int(len(latency) * p / 100))], 2) for p in (50, 95, 99)},
                    "errors": dict(Counter(item[4] for item in results if item[4])), "traffic": "paced reads and favorite writes" if args.duration else "read burst", "methods": dict(Counter(item[3] for item in results)), "statuses": dict(statuses), "response_bytes": sum(item[2] for item in results), "production_capacity_guarantee": False}
                log.flush()
                diagnostic = (root / "services.log").read_text()
                args.output.with_suffix(".log").write_text(diagnostic[-20000:])
                args.output.write_text(json.dumps(report, indent=2) + "\n")
                print(json.dumps(report, indent=2))
                return 0 if statuses.get("200", 0) == len(results) else 1
            except Exception:
                log.flush()
                print((root / "services.log").read_text()[-6000:], file=sys.stderr)
                raise
            finally:
                for process in reversed(processes):
                    if process.poll() is None:
                        if process == locals().get("api"):
                            os.killpg(process.pid, signal.SIGTERM)
                        else:
                            process.terminate()
                        try:
                            process.wait(timeout=15)
                        except subprocess.TimeoutExpired:
                            process.kill()
                            process.wait()
                if pg_started:
                    subprocess.run([str(args.pg_bin / "pg_ctl"), "-D", str(data), "-m", "fast", "-w", "stop"], stdout=log, stderr=log, check=True)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "seed":
        seed(int(sys.argv[2]), int(sys.argv[3]), sys.argv[4])
    else:
        raise SystemExit(main())
