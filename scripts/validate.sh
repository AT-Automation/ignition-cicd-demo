#!/usr/bin/env bash
# Run the same project checks locally and in CI.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "Check 1/2: project-JSON en vereiste Perspective-labels"

if python3 - <<'PY'
import json
from pathlib import Path

required = {"LabelMachine", "LabelStatus"}
seen = set()
for path in sorted(Path("projects").rglob("*.json")):
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid JSON: {path}: {exc}")
    if path.name == "view.json":
        def walk(node):
            if isinstance(node, dict):
                name = node.get("meta", {}).get("name")
                if name:
                    seen.add(name)
                for child in node.get("children", []):
                    walk(child)
        walk(value.get("root", {}))
missing = required - seen
if missing:
    raise SystemExit("Demo labels missing from view.json: " + ", ".join(sorted(missing)))
print("JSON and required Perspective labels: OK")
PY
then
  echo "PASS: project-JSON en vereiste Perspective-labels zijn geldig."
else
  status=$?
  echo "FAIL: project-JSON of vereiste Perspective-labels zijn ongeldig." >&2
  exit "$status"
fi

if command -v ign-lint >/dev/null 2>&1; then
  echo "Check 2/2: Perspective lint"
  if ign-lint --config rule_config.json --files "projects/**/view.json"; then
    echo "PASS: Perspective lint."
  else
    status=$?
    echo "FAIL: Perspective lint." >&2
    exit "$status"
  fi
else
  echo "SKIP: Perspective lint; ign-lint is niet lokaal geïnstalleerd."
fi
