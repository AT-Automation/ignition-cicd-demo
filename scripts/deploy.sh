#!/usr/bin/env bash
# File-based production deploy. Run by the short-lived Compose runner.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# The runner mounts the ignored local .env at /runner-env/.env. A locally run
# troubleshooting command can use the repository's .env instead. An explicitly
# exported value always wins.
if [ -z "${IGNITION_API_KEY:-}" ]; then
  for env_file in /runner-env/.env .env; do
    if [ -f "$env_file" ]; then
      IGNITION_API_KEY="$(sed -n 's/^IGNITION_API_KEY=//p' "$env_file" | head -n 1 | tr -d '\r')"
      [ -n "$IGNITION_API_KEY" ] && export IGNITION_API_KEY && break
    fi
  done
fi

container="${IGNITION_CONTAINER:-ignition-demo-production}"
gateway_url="${IGNITION_URL:-http://localhost:8090}"
gateway_data="/usr/local/bin/ignition/data"

command -v docker >/dev/null || { echo "docker CLI is required" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
docker inspect "$container" >/dev/null 2>&1 || { echo "Container not found: $container" >&2; exit 1; }
test "$(docker inspect -f '{{.State.Running}}' "$container")" = "true" || {
  echo "Container is not running: $container" >&2; exit 1;
}
test -n "${IGNITION_API_KEY:-}" || {
  echo "IGNITION_API_KEY is required for the hot project scan." >&2; exit 1;
}

echo "Shipping demo-project to $container"
docker exec "$container" sh -c "rm -rf '$gateway_data/projects/demo-project' && mkdir -p '$gateway_data/projects'"
docker cp projects/demo-project "$container:$gateway_data/projects/"
docker exec -u root "$container" sh -c "chown -R 2003:0 '$gateway_data/projects/demo-project'"

echo "Triggering project scan"
curl --fail --silent --show-error --max-time 30 -X POST \
  -H "X-Ignition-API-Token: $IGNITION_API_KEY" \
  "$gateway_url/data/api/v1/scan/projects"
echo

echo "Smoke-checking production gateway"
curl --fail --silent --show-error --max-time 15 "$gateway_url/StatusPing" | grep -q RUNNING
echo "Deployment complete: $gateway_url/data/perspective/client/demo-project/"
