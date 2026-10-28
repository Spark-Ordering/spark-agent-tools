#!/bin/bash
# dev-secrets.sh — blind secret plumbing for DEVELOP envs only. Never prints a value.
#   seed-jira <env>            copy JIRA_EMAIL/JIRA_API_TOKEN from the Atlassian MCP config
#                              (~/.claude.json) into ~/Code/SparkPos/.env.<env> (skips keys already there)
#   push <env> <KEY1,KEY2,…>   supabase secrets set those keys on <env>'s project from its env file
#   list <env>                 print the NAMES of function secrets set on <env>
# Refuses production and staging: prod secrets are Carlos's, done his own way.
set -euo pipefail

cmd="${1:-}"; env_name="${2:-}"
repo="$HOME/Code/SparkPos"

usage() { sed -n '2,8p' "$0"; exit 1; }
[ -n "$cmd" ] && [ -n "$env_name" ] || usage

case "$env_name" in
  develop|develop[0-9]*) ;;
  *) echo "refused: $env_name is not a develop env"; exit 2 ;;
esac

envfile="$repo/.env.$env_name"
[ -f "$envfile" ] || { echo "no env file for $env_name"; exit 1; }

project_ref() {
  grep '^SUPABASE_URL=' "$envfile" | head -1 | cut -d= -f2- | tr -d '"' | cut -d/ -f3 | cut -d. -f1
}

case "$cmd" in
  seed-jira)
    tmp="$(mktemp)"; chmod 600 "$tmp"; trap 'rm -f "$tmp"' EXIT
    python3 - "$tmp" <<'PY'
import json, os, sys
cfg = json.load(open(os.path.expanduser('~/.claude.json')))
def walk(o):
    if isinstance(o, dict):
        if o.get('JIRA_API_TOKEN') and o.get('JIRA_USERNAME'):
            return o
        for v in o.values():
            r = walk(v)
            if r: return r
    if isinstance(o, list):
        for v in o:
            r = walk(v)
            if r: return r
    return None
env = walk(cfg)
if not env:
    print('no JIRA_USERNAME/JIRA_API_TOKEN pair in ~/.claude.json'); sys.exit(1)
with open(sys.argv[1], 'w') as out:
    out.write('JIRA_EMAIL=%s\nJIRA_API_TOKEN=%s\n' % (env['JIRA_USERNAME'], env['JIRA_API_TOKEN']))
PY
    for k in JIRA_EMAIL JIRA_API_TOKEN; do
      if grep -q "^${k}=" "$envfile"; then echo "$k: already in .env.$env_name"
      else grep "^${k}=" "$tmp" >> "$envfile"; echo "$k: appended to .env.$env_name"; fi
    done
    ;;
  push)
    keys="${3:?usage: push <env> <KEY1,KEY2,…>}"
    tmp="$(mktemp)"; chmod 600 "$tmp"; trap 'rm -f "$tmp"' EXIT
    IFS=',' read -ra KEYS <<< "$keys"
    for k in "${KEYS[@]}"; do
      grep "^${k}=" "$envfile" | head -1 >> "$tmp" || { echo "$k: MISSING in .env.$env_name"; exit 1; }
    done
    ref="$(project_ref)"
    ( cd "$repo" && npx supabase secrets set --env-file "$tmp" --project-ref "$ref" >/dev/null 2>&1 ) \
      && echo "pushed ${#KEYS[@]} key(s) to $env_name ($ref)" \
      || { echo "supabase secrets set FAILED on $env_name ($ref)"; exit 1; }
    ;;
  list)
    ref="$(project_ref)"
    ( cd "$repo" && npx supabase secrets list --project-ref "$ref" 2>/dev/null ) \
      | awk -F'|' 'NR>2 {gsub(/ /,"",$1); if ($1!="") print $1}' | sort
    ;;
  *) usage ;;
esac
