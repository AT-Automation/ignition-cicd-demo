#!/usr/bin/env bash
# Tell the local Gateway to reload the file-based project after an edit.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

test -f .env || { echo "Maak eerst .env: cp .env.example .env" >&2; exit 1; }
set -a
. ./.env
set +a

test -n "${IGNITION_API_KEY_LOCAL:-}" || {
  echo "Vul eerst IGNITION_API_KEY_LOCAL in .env in." >&2
  exit 1
}

gateway_url="${IGNITION_URL_LOCAL:-http://localhost:8088}"
response_file="$(mktemp)"
trap 'rm -f "$response_file"' EXIT
http_code="$(curl --silent --show-error --output "$response_file" --write-out '%{http_code}' \
  -X POST \
  -H "X-Ignition-API-Token: $IGNITION_API_KEY_LOCAL" \
  "$gateway_url/data/api/v1/scan/projects")"

if [ "$http_code" = "403" ]; then
  echo "403 Verboden: deze API key heeft geen Gateway Write Permission." >&2
  echo "Maak een eigen Security Level, koppel dat bij Gateway Write Permissions," >&2
  echo "en selecteer hetzelfde level op de API key. Zie demo-stap 2." >&2
  exit 1
fi
if [ "$http_code" -lt 200 ] || [ "$http_code" -ge 300 ]; then
  echo "De projectscan is mislukt met HTTP-status $http_code." >&2
  cat "$response_file" >&2
  exit 1
fi
echo
echo "Lokale Gateway is gescand: $gateway_url"
