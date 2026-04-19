#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT/infra"

docker compose up -d --build

# Wait for API container to be ready
sleep 3

docker compose exec api sh -c "cd /app && PYTHONPATH=/app alembic upgrade head"

docker compose exec api sh -c "cd /app && PYTHONPATH=/app python scripts/seed.py"

printf "\nAll services are up. API: http://localhost:8080/api\n"
