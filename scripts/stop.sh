#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec docker compose --env-file "$root/deployment/server.env" -f "$root/deployment/compose.yaml" stop
