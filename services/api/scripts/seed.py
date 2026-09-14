import os
import subprocess
import sys


def _load_env(path: str) -> dict[str, str]:
    env = {}
    if not os.path.exists(path):
        return env
    with open(path, "r", encoding="utf-8") as handle:
        for line in handle:
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.strip().split("=", 1)
            env[key] = value
    return env


def main():
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    env = os.environ.copy()
    file_env = _load_env(env_path)
    for key, value in file_env.items():
        env.setdefault(key, value)
    if env.get("APP_ENV", "development").strip().lower() == "production":
        raise SystemExit("Demo seed is disabled in production")
    db_url = env.get("DATABASE_URL", "")
    if db_url.startswith("sqlite"):
        script_path = os.path.join(os.path.dirname(__file__), "seed_sqlite.py")
        subprocess.run([sys.executable, script_path], check=True, env=env)
        return
    if db_url.startswith("postgresql+psycopg://"):
        db_url = "postgresql://" + db_url.split("postgresql+psycopg://", 1)[1]
    seed_sql = os.path.join(os.path.dirname(__file__), "seed.sql")
    if not db_url:
        raise SystemExit("DATABASE_URL is missing in services/api/.env")
    if not os.path.exists(seed_sql):
        raise SystemExit("seed.sql not found in services/api/scripts")
    subprocess.run(["psql", db_url, "-f", seed_sql], check=True, env=env)


if __name__ == "__main__":
    main()
