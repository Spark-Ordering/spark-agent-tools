#!/bin/bash
# env-drop-key.sh <develop-env> <KEY> — remove ONE key line from SparkPos/.env.<env>.
# Dev envs only (develop, develop1..N); never prints a value; no-op if absent.
set -euo pipefail

env="${1:-}"; key="${2:-}"
if [ -z "$env" ] || [ -z "$key" ]; then
  echo "usage: env-drop-key.sh <develop-env> <KEY>" >&2; exit 2
fi
if ! [[ "$env" =~ ^develop[0-9]*$ ]]; then
  echo "refused: '$env' is not a develop env (develop, develop1..N only)" >&2; exit 3
fi
if ! [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  echo "refused: '$key' is not a single env var name" >&2; exit 4
fi

file="${ENV_DIR:-$HOME/Code/SparkPos}/.env.$env"
if [ ! -f "$file" ]; then echo "no such file: .env.$env" >&2; exit 1; fi

if ! grep -q "^${key}=" "$file"; then
  echo "$key: not present in .env.$env"; exit 0
fi
grep -v "^${key}=" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
echo "$key: dropped from .env.$env"
