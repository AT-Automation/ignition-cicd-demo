#!/usr/bin/env bash
# Introduce the deliberately small lint error used in demo step 5.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

view_file="projects/demo-project/com.inductiveautomation.perspective/views/demo/view.json"
expected='"name": "LabelMachine"'
seeded='"name": "machine"'

if grep -Fq "$seeded" "$view_file"; then
  echo "De demo-lintfout is al aanwezig in $view_file."
  exit 0
fi

grep -Fq "$expected" "$view_file" || {
  echo "Kan de verwachte componentnaam niet vinden; er is niets gewijzigd." >&2
  exit 1
}

python3 - "$view_file" "$expected" "$seeded" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
before, after = sys.argv[2:]
text = path.read_bytes().decode("utf-8")
if text.count(before) != 1:
    raise SystemExit("De componentnaam komt niet precies één keer voor; er is niets gewijzigd.")
path.write_bytes(text.replace(before, after, 1).encode("utf-8"))
PY

echo "Lintfout toegevoegd: LabelMachine is veranderd naar machine."
