#!/bin/bash
# web-rig-cypress.sh <env> <spec-glob> [portalUrl] [adminDashboardUrl]
# Runs one SPARK_E2E Cypress spec against deployed rig URLs. URLs default to the rig's
# production aliases; pass the preview URL web-rig-deploy.sh printed for the app under
# test. The rig projects' Protection Bypass secrets are read blind from
# spark-agent-tools/.env.vercel-rig and handed to cypress/support/e2e.js (never printed).
set -e
ENV="$1"; SPEC="$2"
PORTAL_URL="${3:-https://spark-portal-$ENV.vercel.app}"
ADMIN_URL="${4:-https://spark-admin-$ENV.vercel.app}"
[ -n "$ENV" ] && [ -n "$SPEC" ] || { echo "usage: web-rig-cypress.sh <env> <spec-glob> [portalUrl] [adminDashboardUrl]"; exit 1; }
ENV_FILE="$HOME/Code/spark-agent-tools/.env.vercel-rig"
[ -f "$ENV_FILE" ] || { echo "missing $ENV_FILE (run web-rig-bypass.sh first)"; exit 1; }
case "$PORTAL_URL$ADMIN_URL" in *localhost*|*127.0.0.1*) echo "localhost is not a test target"; exit 1 ;; esac

read_env_var() {
  local line
  line=$(grep -m1 "^$2=" "$1" 2>/dev/null) || return 1
  local val="${line#*=}"
  if [[ "$val" =~ ^\"(.*)\"$ ]]; then val="${BASH_REMATCH[1]}"; elif [[ "$val" =~ ^\'(.*)\'$ ]]; then val="${BASH_REMATCH[1]}"; fi
  printf '%s' "$val"
}
# cypress/support/e2e.js stamps ONE secret (CYPRESS_vercelBypass) on every request, so it is
# the preview's project: a portal preview URL wins, else an admin preview, else none (aliases).
BYPASS_KEY=""
if [ "$PORTAL_URL" != "https://spark-portal-$ENV.vercel.app" ]; then
  BYPASS_KEY="VERCEL_BYPASS_PORTAL_$ENV"
elif [ "$ADMIN_URL" != "https://spark-admin-$ENV.vercel.app" ]; then
  BYPASS_KEY="VERCEL_BYPASS_ADMIN_$ENV"
fi
if [ -n "$BYPASS_KEY" ]; then
  CYPRESS_vercelBypass="$(read_env_var "$ENV_FILE" "$BYPASS_KEY")" || { echo "no $BYPASS_KEY in $ENV_FILE"; exit 1; }
  export CYPRESS_vercelBypass
fi

# Agent API specs (ENG-2958) send the env's AGENT_KEY as a Bearer header; read blind, never printed.
AGENT_KEY_VALUE="$(read_env_var "$HOME/Code/SparkPos/.env.$ENV" AGENT_KEY)" || true
if [ -n "$AGENT_KEY_VALUE" ]; then
  export CYPRESS_agentKey="$AGENT_KEY_VALUE"
fi

# Perf specs time real page loads; video capture in Cypress's proxy process stalls requests 1-3 s (ENG-2879).
case "$SPEC" in *PERF*) export CYPRESS_video=false ;; esac

# SPARK_E2E_DIR=<worktree> runs that checkout's specs (a branch in a git worktree).
cd "${SPARK_E2E_DIR:-$HOME/Code/SPARK_E2E}"
# Same pairing as orchestrator.js: <PREFIX>-Z-config.json next to the spec (Finix iframes need
# experimentalModifyObstructiveThirdPartyCode, else the hosted card form never mounts).
CYPRESS_CONFIG="retries=0"
SPEC_FILE=$(find cypress/e2e -name "$SPEC.cy.js" | head -1)
if [ -n "$SPEC_FILE" ]; then
  SPEC_BASE=$(basename "$SPEC_FILE")
  SPEC_PREFIX=$(echo "$SPEC_BASE" | cut -d' ' -f1 | cut -d- -f1-2)
  Z_CONFIG="$(dirname "$SPEC_FILE")/$SPEC_PREFIX-Z-config.json"
  if [ -f "$Z_CONFIG" ]; then
    OBSTRUCTIVE=$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1])).get("experimentalModifyObstructiveThirdPartyCode", False)).lower())' "$Z_CONFIG")
    CYPRESS_CONFIG="$CYPRESS_CONFIG,experimentalModifyObstructiveThirdPartyCode=$OBSTRUCTIVE"
    echo "z-config: $Z_CONFIG (experimentalModifyObstructiveThirdPartyCode=$OBSTRUCTIVE)"
  fi
fi
echo "spec: $SPEC"
echo "portalUrl=$PORTAL_URL adminDashboardUrl=$ADMIN_URL"
npx cypress run --browser chrome --config "$CYPRESS_CONFIG" \
  --env "portalUrl=$PORTAL_URL,adminDashboardUrl=$ADMIN_URL" \
  --spec "cypress/e2e/**/$SPEC.cy.js"
