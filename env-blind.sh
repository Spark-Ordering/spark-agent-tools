#!/bin/bash
# env-blind.sh — blind .env manipulation. NEVER prints secret values.
# The ONLY sanctioned way for Claude to touch .env files:
#   keys <file>                      list key names (no values)
#   has <file> <KEY1,KEY2,...>       report which keys exist (names only)
#   copy-keys <src> <dst> <KEYS>     append missing keys from src to dst (values never shown)
#   ensure-kid <file> [kid]          add "kid" to the POWERSYNC_PRIVATE_KEY JWK if missing
set -euo pipefail

cmd="${1:-}"; shift || true

require_file() {
  if [ ! -f "$1" ]; then echo "ERROR: no such file: $1"; exit 1; fi
}

case "$cmd" in
  keys)
    require_file "$1"
    grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' "$1" | tr -d '='
    ;;
  has)
    require_file "$1"
    IFS=',' read -ra KEYS <<< "$2"
    for k in "${KEYS[@]}"; do
      if grep -q "^${k}=" "$1"; then echo "$k: present"; else echo "$k: MISSING"; fi
    done
    ;;
  copy-keys)
    src="$1"; dst="$2"
    require_file "$src"; require_file "$dst"
    IFS=',' read -ra KEYS <<< "$3"
    for k in "${KEYS[@]}"; do
      if grep -q "^${k}=" "$dst"; then
        echo "$k: already in $(basename "$dst"), skipped"
      elif grep -q "^${k}=" "$src"; then
        grep "^${k}=" "$src" | head -1 >> "$dst"
        echo "$k: copied"
      else
        echo "$k: NOT FOUND in $(basename "$src")"
      fi
    done
    ;;
  drop-keys)
    # drop-keys <file> <KEY1,KEY2,...> — remove those keys' lines (values never shown)
    file="$1"
    require_file "$file"
    IFS=',' read -ra KEYS <<< "$2"
    for k in "${KEYS[@]}"; do
      if grep -q "^${k}=" "$file"; then
        grep -v "^${k}=" "$file" > "${file}.envblind.tmp"
        mv "${file}.envblind.tmp" "$file"
        echo "$k: dropped"
      else
        echo "$k: not present"
      fi
    done
    ;;
  matches)
    # matches <file> <KEY> <regex> — print yes/no whether KEY's value matches the regex (value never shown)
    require_file "$1"
    if grep -E "^${2}=" "$1" | head -1 | cut -d= -f2- | grep -qE "$3"; then echo "$2: yes"; else echo "$2: no"; fi
    ;;
  project-ref)
    # project-ref <file> — print only the Supabase project ref parsed from SUPABASE_URL
    require_file "$1"
    grep -E '^SUPABASE_URL=' "$1" | head -1 | grep -oE 'https://[a-z0-9-]+' | sed 's#https://##'
    ;;
  set-from-stdin)
    # set-from-stdin <file> <KEY> — value arrives on stdin (piped, never
    # printed); appends KEY=value if missing, replaces the line if present.
    file="$1"; key="$2"
    require_file "$file"
    IFS= read -r value
    if [ -z "$value" ]; then echo "ERROR: empty value on stdin"; exit 1; fi
    if grep -q "^${key}=" "$file"; then
      grep -v "^${key}=" "$file" > "${file}.envblind.tmp"
      printf '%s=%s\n' "$key" "$value" >> "${file}.envblind.tmp"
      mv "${file}.envblind.tmp" "$file"
      echo "$key: replaced"
    else
      printf '%s=%s\n' "$key" "$value" >> "$file"
      echo "$key: added"
    fi
    ;;
  alias-key)
    file="$1"; src_key="$2"; dst_key="$3"
    require_file "$file"
    if grep -q "^${dst_key}=" "$file"; then
      echo "$dst_key: already present, skipped"
    elif grep -q "^${src_key}=" "$file"; then
      val_line=$(grep "^${src_key}=" "$file" | head -1)
      echo "${dst_key}=${val_line#${src_key}=}" >> "$file"
      echo "$dst_key: added (same value as $src_key)"
    else
      echo "$src_key: NOT FOUND"
    fi
    ;;
  dupes)
    require_file "$1"
    python3 - "$1" <<'PY'
import sys, collections
groups = collections.defaultdict(list)
for line in open(sys.argv[1]):
    line = line.rstrip('\n')
    if '=' in line and line[:1].isalpha() or line[:1] == '_':
        k, _, v = line.partition('=')
        if v.strip():
            groups[v].append(k)
found = False
for v, keys in groups.items():
    if len(keys) > 1:
        print('same value: ' + ', '.join(keys))
        found = True
if not found:
    print('no duplicate values')
PY
    ;;
  ensure-kid)
    file="$1"; kid="${2:-powersync-key-1}"
    require_file "$file"
    python3 - "$file" "$kid" <<'PY'
import json, re, sys
path, kid = sys.argv[1], sys.argv[2]
lines = open(path).read().split('\n')
out, status = [], 'KEY NOT FOUND'
for line in lines:
    if line.startswith('POWERSYNC_PRIVATE_KEY='):
        raw = line[len('POWERSYNC_PRIVATE_KEY='):].strip()
        quote = ''
        if raw[:1] in ('"', "'") and raw[-1:] == raw[:1]:
            quote, raw = raw[:1], raw[1:-1]
        jwk = json.loads(raw)
        if jwk.get('kid'):
            status = f'kid already present'
        else:
            jwk = {'kid': kid, **jwk}
            line = 'POWERSYNC_PRIVATE_KEY=' + quote + json.dumps(jwk, separators=(',', ':')) + quote
            status = f'kid "{kid}" added'
    out.append(line)
open(path, 'w').write('\n'.join(out))
print(status)
PY
    ;;
  *)
    echo "usage: env-blind.sh keys|has|copy-keys|ensure-kid ..."
    exit 1
    ;;
esac
