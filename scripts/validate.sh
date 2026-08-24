#!/usr/bin/env bash
# Fast local counterpart of CI: JSON parsing plus the Perspective linter when installed.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

python3 - <<'PY'
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

if command -v ign-lint >/dev/null 2>&1; then
  ign-lint --config rule_config.json --files "projects/**/view.json"
else
  echo "ign-lint not installed locally (CI installs ign-lint==0.6.1)."
fi
