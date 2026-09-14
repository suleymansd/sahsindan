#!/usr/bin/env bash
set -euo pipefail

# Docker-free local dev runner:
# - SQLite DB file
# - In-memory "redis"
# - Local /storage (served by FastAPI)
# - Uvicorn on :8080; API routes use /api in both direct and Nginx modes.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$API_ROOT"

# Prefer repo venv if present.
PY_BIN="${PY_BIN:-}"
if [[ -z "$PY_BIN" ]]; then
  if [[ -x ".venv/bin/python" ]]; then
    PY_BIN=".venv/bin/python"
  else
    PY_BIN="python3"
  fi
fi

export PYTHONPATH="$API_ROOT"

# Defaults (can be overridden by environment).
export DATABASE_URL="${DATABASE_URL:-sqlite+pysqlite:///$API_ROOT/storage/dev_local.sqlite3}"
export REDIS_URL="${REDIS_URL:-memory://}"
export DISABLE_STORAGE="${DISABLE_STORAGE:-1}"
export DISABLE_STALE_JOB="${DISABLE_STALE_JOB:-1}"
export PUBLIC_API_URL="${PUBLIC_API_URL:-http://localhost:8080}"
export SQLALCHEMY_POOL_SIZE="${SQLALCHEMY_POOL_SIZE:-40}"
export SQLALCHEMY_MAX_OVERFLOW="${SQLALCHEMY_MAX_OVERFLOW:-80}"
export SQLALCHEMY_POOL_TIMEOUT="${SQLALCHEMY_POOL_TIMEOUT:-60}"
export SQLALCHEMY_POOL_RECYCLE="${SQLALCHEMY_POOL_RECYCLE:-1800}"
export SQLITE_BUSY_TIMEOUT_SECONDS="${SQLITE_BUSY_TIMEOUT_SECONDS:-30}"
export LISTINGS_CACHE_ENABLED="${LISTINGS_CACHE_ENABLED:-1}"
export LISTINGS_CACHE_TTL_SECONDS="${LISTINGS_CACHE_TTL_SECONDS:-15}"

# CORS: allow Flutter web (default port 3005) and common web ports.
export CORS_ORIGINS="${CORS_ORIGINS:-http://localhost:3000,http://127.0.0.1:3000,http://localhost:3001,http://127.0.0.1:3001,http://localhost:3002,http://127.0.0.1:3002,http://localhost:3003,http://127.0.0.1:3003,http://localhost:3005,http://127.0.0.1:3005}"

mkdir -p "$API_ROOT/storage"

echo "[dev_local] Using PY_BIN=$PY_BIN"
echo "[dev_local] DATABASE_URL=$DATABASE_URL"
echo "[dev_local] REDIS_URL=$REDIS_URL"
echo "[dev_local] DISABLE_STORAGE=$DISABLE_STORAGE"
echo "[dev_local] DISABLE_STALE_JOB=$DISABLE_STALE_JOB"
echo "[dev_local] SQLALCHEMY_POOL_SIZE=$SQLALCHEMY_POOL_SIZE"
echo "[dev_local] SQLALCHEMY_MAX_OVERFLOW=$SQLALCHEMY_MAX_OVERFLOW"
echo "[dev_local] SQLALCHEMY_POOL_TIMEOUT=$SQLALCHEMY_POOL_TIMEOUT"
echo "[dev_local] SQLITE_BUSY_TIMEOUT_SECONDS=$SQLITE_BUSY_TIMEOUT_SECONDS"
echo "[dev_local] LISTINGS_CACHE_ENABLED=$LISTINGS_CACHE_ENABLED"
echo "[dev_local] LISTINGS_CACHE_TTL_SECONDS=$LISTINGS_CACHE_TTL_SECONDS"

"$PY_BIN" -m alembic upgrade head
"$PY_BIN" scripts/seed.py

UVICORN_ARGS=("--host" "127.0.0.1" "--port" "8080")
# File watching can fail under restricted environments; keep reload opt-in.
if [[ "${RELOAD:-0}" == "1" ]]; then
  UVICORN_ARGS+=("--reload")
fi

exec "$PY_BIN" -m uvicorn app.main:app "${UVICORN_ARGS[@]}"
