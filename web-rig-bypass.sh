#!/bin/bash
# web-rig-bypass.sh <portal|admin-dashboard> <env>
# Ensures spark-agent-tools/.env.vercel-rig carries the rig project's Protection Bypass
# for Automation secret (VERCEL_BYPASS_PORTAL_<env> / VERCEL_BYPASS_ADMIN_<env>):
# generates one on the rig project via the Vercel API when missing. Dev-rig projects
# only; the value is never printed. (Not in SparkPos .env.<env>: deploy.sh's required-key
# check rejects extra keys there.)
set -e
APP="$1"; ENV="$2"
TEAM_ID="team_Ybfyk5PdbWIVJ04rmqwnXDJo"   # carlos-6143s-projects (rig projects only)
case "$APP" in
  portal) PROJECT="spark-portal-$ENV"; KEY="VERCEL_BYPASS_PORTAL_$ENV" ;;
  admin-dashboard) PROJECT="spark-admin-$ENV"; KEY="VERCEL_BYPASS_ADMIN_$ENV" ;;
  *) echo "usage: web-rig-bypass.sh <portal|admin-dashboard> <env>"; exit 1 ;;
esac
if [ -z "$ENV" ] || [ "$ENV" = "production" ]; then echo "dev envs only"; exit 1; fi
ENV_FILE="$HOME/Code/spark-agent-tools/.env.vercel-rig"
touch "$ENV_FILE"
BLIND="$HOME/Code/spark-agent-tools/env-blind.sh"

if grep -q "^$KEY=" "$ENV_FILE"; then echo "$KEY: present"; exit 0; fi

TOKEN=$(jq -r .token "$HOME/Library/Application Support/com.vercel.cli/auth.json")
# Resolve by name and refuse anything outside the rig team.
NAME=$(curl -s "https://api.vercel.com/v9/projects/$PROJECT?teamId=$TEAM_ID" -H "Authorization: Bearer $TOKEN" | jq -r '.name // empty')
[ "$NAME" = "$PROJECT" ] || { echo "project $PROJECT not found in rig team"; exit 1; }

OUT=$(curl -s -X PATCH "https://api.vercel.com/v1/projects/$PROJECT/protection-bypass?teamId=$TEAM_ID" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"generate": {"note": "SPARK_E2E cypress vs preview deployments"}}')
ERR=$(printf '%s' "$OUT" | jq -r '.error.message // empty')
[ -z "$ERR" ] || { echo "ERROR: $ERR"; exit 1; }
printf '%s' "$OUT" | jq -r '.protectionBypass | to_entries | max_by(.value.createdAt) | .["key"]' \
  | "$BLIND" set-from-stdin "$ENV_FILE" "$KEY"
