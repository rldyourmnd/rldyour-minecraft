#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ $# != 2 ]]; then
    echo "Usage: $0 <client-input.zip> <sha256>" >&2
    exit 2
fi
python3 "$root/scripts/install_pack.py" "$1" "$2" "$root/deployment/server.env" "$root/deployment/pack-policy.json" "$root/deployment/artifacts.json"
