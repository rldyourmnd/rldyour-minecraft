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

# List available backups or use argument
if [[ $# -eq 0 ]]; then
    echo "Available backups:"
    echo ""
    ls -1t "${BACKUP_DIR}"/world_backup_*.tar.gz 2>/dev/null | while read -r f; do
        SIZE=$(du -h "$f" | cut -f1)
        NAME=$(basename "$f")
        echo "  ${NAME} (${SIZE})"
    done
    echo ""
    echo "Usage: $0 <backup_filename>"
    echo "Example: $0 world_backup_2026-03-15_12-00-00.tar.gz"
    exit 0
fi

BACKUP_FILE="${BACKUP_DIR}/$1"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "ERROR: Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

# Safety check
echo "WARNING: This will replace the current world data!"
echo "Backup: $1"
read -p "Continue? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted."
    exit 0
fi

# Remove current world data
echo "Removing current world data..."
rm -rf world/ world_nether/ world_the_end/

# Restore from backup
echo "Restoring from ${1}..."
tar -xzf "$BACKUP_FILE"

echo "Restore complete. Start the server to verify."
