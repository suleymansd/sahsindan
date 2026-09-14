"""Run migrations and tests against an automatically removed local PostgreSQL cluster."""
import argparse
import getpass
import os
from pathlib import Path
import shutil
import subprocess
import sys
from tempfile import TemporaryDirectory

from sqlalchemy.engine import URL


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pg-bin", type=Path, help="Directory containing initdb and pg_ctl")
    args, pytest_args = parser.parse_known_args()
    pg_bin = args.pg_bin
    if pg_bin is None:
        initdb = shutil.which("initdb")
        if not initdb:
            parser.error("initdb was not found; supply --pg-bin")
        pg_bin = Path(initdb).parent
    api_root = Path(__file__).resolve().parents[1]
    with TemporaryDirectory(prefix="trustmarket-pg-") as directory:
        root = Path(directory)
        data = root / "data"
        subprocess.run([str(pg_bin / "initdb"), "-D", str(data), "-A", "trust", "--no-locale", "-E", "UTF8"],
                       check=True, stdout=subprocess.DEVNULL)
        try:
            # Unique, owner-only socket directory; no TCP listener or existing database is used.
            subprocess.run([str(pg_bin / "pg_ctl"), "-D", str(data), "-l", str(root / "postgres.log"),
                            "-o", f"-k {root} -h '' -p 55491", "-w", "start"], check=True)
            url = URL.create("postgresql+psycopg", username=getpass.getuser(), database="postgres",
                             query={"host": str(root), "port": "55491"}).render_as_string(hide_password=False)
            env = dict(os.environ, DATABASE_URL=url, REDIS_URL="memory://", DISABLE_STALE_JOB="1",
                       APP_ENV="development", JWT_SECRET="postgres-test-access-secret-at-least-32-chars",
                       JWT_REFRESH_SECRET="postgres-test-refresh-secret-at-least-32-chars")
            subprocess.run([sys.executable, "-m", "alembic", "upgrade", "head"], cwd=api_root, env=env, check=True)
            result = subprocess.run([sys.executable, "-m", "pytest", "--postgres-url", url, *pytest_args],
                                    cwd=api_root, env=env)
            return result.returncode
        finally:
            if (data / "postmaster.pid").exists():
                subprocess.run([str(pg_bin / "pg_ctl"), "-D", str(data), "-m", "fast", "-w", "stop"], check=True)


if __name__ == "__main__":
    raise SystemExit(main())
