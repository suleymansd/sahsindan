#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PRODUCTION_ENV_FILE:-$REPO_ROOT/infra/.env.production}"
COMPOSE=(docker compose --env-file "$ENV_FILE" -f "$REPO_ROOT/infra/compose.production.yml")
if [[ -n "${PRODUCTION_COMPOSE_OVERRIDE:-}" ]]; then COMPOSE+=(-f "$PRODUCTION_COMPOSE_OVERRIDE"); fi
if [[ -n "${COMPOSE_PROJECT_NAME:-}" ]]; then COMPOSE+=(-p "$COMPOSE_PROJECT_NAME"); fi
case "${1:-check}" in
  check)
    test -f "$ENV_FILE" || { echo "Create infra/.env.production with scripts/production_env.py first." >&2; exit 1; }
    "${COMPOSE[@]}" config --quiet
    docker info >/dev/null
    echo "Compose configuration and Docker are available. Verify DNS, SMTP, backups and release tests before deploy."
    ;;
  deploy)
    "$0" check
    "${COMPOSE[@]}" build --pull
    "${COMPOSE[@]}" up -d --wait --wait-timeout 180
    "${COMPOSE[@]}" exec -T api curl -fsS http://127.0.0.1:8000/ready
    echo "Services started. Run the documented HTTPS and signup smoke checks on your domain."
    ;;
  admin) "${COMPOSE[@]}" exec api python scripts/create_admin.py ;;
  mfa) "${COMPOSE[@]}" exec api python scripts/enroll_mfa.py ;;
  status) "${COMPOSE[@]}" ps ;;
  backup|backup-key|restore-check)
    ACTION="$1"
    shift
    if [[ "$ACTION" == "backup-key" ]]; then ACTION=key; fi
    exec python3 "$REPO_ROOT/scripts/backup.py" "$ACTION" "$@"
    ;;
  *) echo "Usage: $0 {check|deploy|admin|mfa|status|backup|backup-key|restore-check}" >&2; exit 2 ;;
esac
