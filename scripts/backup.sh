#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SERVER_DIR"

# Load environment
if [[ -f .env ]]; then
    source .env
fi

BACKUP_DIR="${BACKUP_DIR:-backups}"
BACKUP_KEEP_COUNT="${BACKUP_KEEP_COUNT:-10}"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="world_backup_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

# Check if world exists
if [[ ! -d "world" ]]; then
    echo "ERROR: world/ directory not found. Nothing to back up."
    exit 1
fi

echo "Creating backup: ${BACKUP_NAME}..."
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}" world/ world_nether/ world_the_end/ 2>/dev/null || \
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}" world/

BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}" | cut -f1)
echo "Backup created: ${BACKUP_DIR}/${BACKUP_NAME} (${BACKUP_SIZE})"

# Rotate old backups
BACKUP_COUNT=$(ls -1 "${BACKUP_DIR}"/world_backup_*.tar.gz 2>/dev/null | wc -l)
if [[ "$BACKUP_COUNT" -gt "$BACKUP_KEEP_COUNT" ]]; then
    REMOVE_COUNT=$((BACKUP_COUNT - BACKUP_KEEP_COUNT))
    echo "Rotating backups: removing ${REMOVE_COUNT} oldest..."
    ls -1t "${BACKUP_DIR}"/world_backup_*.tar.gz | tail -n "$REMOVE_COUNT" | xargs rm -f
fi

echo "Backups: ${BACKUP_COUNT} total (keeping last ${BACKUP_KEEP_COUNT})"
