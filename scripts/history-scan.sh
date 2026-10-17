#!/bin/sh
# Full-history secret scan. Prints rule, path, and commit only.
# Does not print a match, does not rewrite history, does not change visibility.
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VER=8.28.0
SUM=a65b5253807a68ac0cafa4414031fd740aeb55f54fb7e55f386acb52e6a840eb
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

archive="gitleaks_${VER}_linux_x64.tar.gz"
url="https://github.com/gitleaks/gitleaks/releases/download/v${VER}/${archive}"
curl --proto '=https' --tlsv1.2 -fsSL -o "$tmp/$archive" "$url"
echo "${SUM}  $tmp/$archive" | sha256sum -c -
tar -xzf "$tmp/$archive" -C "$tmp" gitleaks

set +e
"$tmp/gitleaks" detect \
  --source "$ROOT" \
  --log-opts="--all" \
  --redact \
  --no-banner \
  --report-format json \
  --report-path "$tmp/gl.json"
status=$?
set -e

python3 - "$tmp/gl.json" << 'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)
print(f"FINDINGS {len(data)}")
seen = set()
for item in data:
    rule = str(item.get("RuleID") or item.get("rule") or "?")
    file = str(item.get("File") or item.get("file") or "?")
    commit = str(item.get("Commit") or item.get("commit") or "?")
    key = (rule, file, commit)
    if key in seen:
        continue
    seen.add(key)
    print(f"{rule}\t{file}\t{commit}")
print(f"UNIQUE {len(seen)}")
PY

exit "$status"
