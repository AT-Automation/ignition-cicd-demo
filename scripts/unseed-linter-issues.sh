#!/usr/bin/env bash
# Restore the deliberately seeded lint error from demo step 5.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

view_file="projects/demo-project/com.inductiveautomation.perspective/views/demo/view.json"
seeded='"name": "machine"'
restored='"name": "LabelMachine"'

if grep -Fq "$restored" "$view_file"; then
  echo "De demo-lintfout is al hersteld in $view_file."
  exit 0
fi

grep -Fq "$seeded" "$view_file" || {
  echo "Kan de gezaaide componentnaam niet vinden; er is niets gewijzigd." >&2
  exit 1
}

python3 - "$view_file" "$seeded" "$restored" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
before, after = sys.argv[2:]
text = path.read_bytes().decode("utf-8")
if text.count(before) != 1:
    raise SystemExit("De componentnaam komt niet precies één keer voor; er is niets gewijzigd.")
path.write_bytes(text.replace(before, after, 1).encode("utf-8"))
PY

echo "Lintfout hersteld: machine is terug veranderd naar LabelMachine."
