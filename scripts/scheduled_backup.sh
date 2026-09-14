#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${BACKUP_RECIPIENT:?Set the age PUBLIC recipient in infra/.env.operations}"
BACKUP_DIR="${BACKUP_DIR:-$REPO_ROOT/backups}"
umask 077
mkdir -p "$BACKUP_DIR"
# Do not prune user snapshots automatically. Alert before disk exhaustion.
exec python3 "$REPO_ROOT/scripts/backup.py" backup --recipient "$BACKUP_RECIPIENT" --snapshot "$BACKUP_DIR/$(date -u +%Y%m%dT%H%M%SZ).tar.age"
