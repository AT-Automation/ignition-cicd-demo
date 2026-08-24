#!/usr/bin/env bash
# Tell the local Gateway to reload the file-based project after an edit.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

test -f .env || { echo "Create .env first: cp .env.example .env" >&2; exit 1; }
set -a
. ./.env
set +a

test -n "${IGNITION_API_KEY_LOCAL:-}" || {
  echo "Add IGNITION_API_KEY_LOCAL to .env first." >&2
  exit 1
}

gateway_url="${IGNITION_URL_LOCAL:-http://localhost:8088}"
curl --fail --silent --show-error -X POST \
  -H "X-Ignition-API-Token: $IGNITION_API_KEY_LOCAL" \
  "$gateway_url/data/api/v1/scan/projects"
echo
echo "Local Gateway scanned: $gateway_url"
