#!/bin/bash
# Self-check for env-drop-key.sh against a temp dir (never touches real env files).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
printf 'A=1\nB=secret\nC=3\n' > "$tmp/.env.develop2"
printf 'A=1\n' > "$tmp/.env.staging"

run() { ENV_DIR="$tmp" "$here/env-drop-key.sh" "$@"; }

run develop2 B | grep -q "B: dropped"
[ "$(cat "$tmp/.env.develop2")" = $'A=1\nC=3' ]              # only B removed, order kept
run develop2 B | grep -q "not present"                        # idempotent
! run staging A 2>/dev/null                                   # non-develop env refused
[ "$(cat "$tmp/.env.staging")" = "A=1" ]
! run develop2 "A,C" 2>/dev/null                              # one key at a time
! run develop2 "A; rm -rf /" 2>/dev/null
[ "$(cat "$tmp/.env.develop2")" = $'A=1\nC=3' ]
echo "env-drop-key: 7/7 ok"
