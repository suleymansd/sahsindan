#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

API_URL="http://127.0.0.1:8080/openapi.json"
WEB_URL="http://127.0.0.1:3005/"

cleanup() {
  if [[ -n "${API_PID:-}" ]] && kill -0 "$API_PID" 2>/dev/null; then
    kill "$API_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

cd "$REPO_ROOT"

echo "[dev_mobile_web] Starting API (docker-free, sqlite) ..."
nohup services/api/scripts/dev_local.sh > /tmp/trustmarket_api.log 2>&1 &
API_PID="$!"

echo "[dev_mobile_web] Waiting for API: $API_URL"
for i in {1..40}; do
  if curl -fsS "$API_URL" >/dev/null 2>&1; then
    echo "[dev_mobile_web] API is up."
    break
  fi
  sleep 0.25
done

if ! curl -fsS "$API_URL" >/dev/null 2>&1; then
  echo "[dev_mobile_web] API did not start. Tail log:"
  tail -n 60 /tmp/trustmarket_api.log || true
  exit 1
fi

echo "[dev_mobile_web] Starting Flutter web on $WEB_URL"
echo "[dev_mobile_web] If Chrome doesn't auto-open, open: $WEB_URL"
cd "$REPO_ROOT/apps/mobile"
if [[ ! -f .env ]]; then
  cp .env.example .env
fi

# Prefer Chrome if available; fallback to web-server.
if flutter devices 2>/dev/null | rg -q "Chrome \\(web\\)"; then
  flutter run -d chrome --web-port=3005 --web-hostname=127.0.0.1
else
  flutter run -d web-server --web-port=3005 --web-hostname=127.0.0.1
fi
