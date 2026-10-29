#!/bin/bash
# web-rig-deploy.sh <portal|admin-dashboard> <env>
# Deploys the app to its detached dev-rig Vercel project (spark-portal-<env> /
# spark-admin-<env>) as a PREVIEW deployment and prints the deployment URL on the
# last line. No production target anywhere: env vars go to the `preview` scope,
# the deploy is `vercel deploy`. The live projects are never linked or touched.
set -e

APP="$1"
ENV="$2"
ROOT_DIR="$HOME/Code/SparkPos"
# WEB_RIG_SRC=<checkout> deploys that checkout's app (a git worktree); env files stay ROOT_DIR's.
SRC_DIR="${WEB_RIG_SRC:-$ROOT_DIR}"
RIG_SCOPE="carlos-6143s-projects"

case "$APP" in
  portal) PROJECT="spark-portal-$ENV"; APP_DIR="$SRC_DIR/portal" ;;
  admin-dashboard) PROJECT="spark-admin-$ENV"; APP_DIR="$SRC_DIR/admin-dashboard" ;;
  *) echo "usage: web-rig-deploy.sh <portal|admin-dashboard> <env>"; exit 1 ;;
esac
if [ -z "$ENV" ] || [ "$ENV" = "production" ]; then
  echo "env must be a dev env (develop1, staging, ...), never production"; exit 1
fi
ENV_FILE="$ROOT_DIR/.env.$ENV"
[ -f "$ENV_FILE" ] || { echo "missing $ENV_FILE"; exit 1; }

# Both apps sign PowerSync tokens (portal: ENG-2766 menu editor).
node "$ROOT_DIR/scripts/checks/checkPowersyncKid.js" "$ENV_FILE" || exit 1

# Both apps import packages/menu-editor (ENG-2766) from outside their folder, so the upload is a
# mini-monorepo (<app>/ + packages/menu-editor/) and the rig project's Root Directory is <app>.
DEPLOY_DIR="${TMPDIR:-/tmp}/spark-rig/$APP-$ENV-preview-root"
mkdir -p "$DEPLOY_DIR/$APP" "$DEPLOY_DIR/packages/menu-editor"
rsync -a --delete --exclude .vercel --exclude node_modules --exclude .next --exclude '.env*' \
  "$APP_DIR/" "$DEPLOY_DIR/$APP/"
rsync -a --delete --exclude node_modules "$SRC_DIR/packages/menu-editor/" "$DEPLOY_DIR/packages/menu-editor/"
# admin's portalPermissions test imports ../portal/lib; Next 16.4's build type-checks it.
if [ "$APP" = "admin-dashboard" ]; then
  mkdir -p "$DEPLOY_DIR/portal/lib"
  rsync -a --delete "$SRC_DIR/portal/lib/" "$DEPLOY_DIR/portal/lib/"
fi
cd "$DEPLOY_DIR"
vercel link --project "$PROJECT" --scope "$RIG_SCOPE" --yes > /dev/null
grep -q "prj_1U9VnykW0qMwWhEF56tINU8tzMJW\|prj_tYl3q5FCZRCPAjFcqOhqTPMow7tz" .vercel/project.json && {
  echo "Refusing: linked to a LIVE project"; exit 1; }
PROJECT_ID=$(node -e 'console.log(require("./.vercel/project.json").projectId)')
vercel api "/v9/projects/$PROJECT_ID" -X PATCH --scope "$RIG_SCOPE" -f "rootDirectory=$APP" \
  -F sourceFilesOutsideRootDirectory=true --silent
echo "Preview deploy of $APP ($ENV) -> $(cat .vercel/project.json), root directory $APP"

read_env_var() {
  local line
  line=$(grep -m1 "^$2=" "$1" 2>/dev/null) || return 1
  local val="${line#*=}"
  if [[ "$val" =~ ^\"(.*)\"$ ]]; then val="${BASH_REMATCH[1]}"; elif [[ "$val" =~ ^\'(.*)\'$ ]]; then val="${BASH_REMATCH[1]}"; fi
  printf '%s' "$val"
}
push_var() {
  local val
  val=$(read_env_var "$ENV_FILE" "$1") || true
  if [ -n "$val" ]; then
    printf '%s' "$val" | vercel env add "${2:-$1}" preview --force > /dev/null 2>&1 || true
    echo "  ✓ ${2:-$1}"
  else
    echo "  ⚠ $1 not in $ENV_FILE, skipped"
  fi
}

echo "Pushing env vars (preview scope)..."
# ENG-2879: page-load timing to Datadog (browser intake, public client token), both apps.
push_var DATADOG_CLIENT_TOKEN NEXT_PUBLIC_DATADOG_CLIENT_TOKEN; push_var DATADOG_ENV NEXT_PUBLIC_DATADOG_ENV
if [ "$APP" = "portal" ]; then
  push_var SUPABASE_URL; push_var SUPABASE_URL NEXT_PUBLIC_SUPABASE_URL
  push_var SUPABASE_ANON_KEY; push_var SUPABASE_ANON_KEY NEXT_PUBLIC_SUPABASE_ANON_KEY
  push_var SUPABASE_SECRET_KEY; push_var PORTAL_MFA_SECRET; push_var PORTAL_SHADOW_SECRET
  push_var SUPA_BASE_BACKEND_SECRET_KEY; push_var DATABASE_URL; push_var OPENAI_API_KEY
  push_var SPARK_BACKEND_URL; push_var SPARK_POS_API_KEY
  push_var POWERSYNC_URL; push_var POWERSYNC_PRIVATE_KEY
else
  push_var SUPABASE_URL; push_var SUPABASE_URL NEXT_PUBLIC_SUPABASE_URL
  push_var SUPABASE_ANON_KEY; push_var SUPABASE_ANON_KEY NEXT_PUBLIC_SUPABASE_ANON_KEY
  push_var SUPABASE_SECRET_KEY; push_var SUPA_BASE_BACKEND_SECRET_KEY; push_var DATABASE_URL
  push_var SESSION_SECRET; push_var ADMIN_SECRET; push_var ADMIN_MFA_SECRET
  push_var PORTAL_SHADOW_SECRET; push_var ORDER_PAYMENT_LINK_SECRET; push_var ADMIN_MFA_E2E_CODE
  push_var PORTAL_BASE_URL; push_var MAILGUN_DOMAIN; push_var MAILGUN_API_KEY
  push_var POWERSYNC_URL NEXT_PUBLIC_POWERSYNC_URL; push_var POWERSYNC_PRIVATE_KEY
  push_var AD_FINIX_USERNAME; push_var AD_FINIX_PASSWORD; push_var AD_FINIX_BASE_URL
  push_var AD_FINIX_API_VERSION; push_var AD_FINIX_DEFAULT_MERCHANT_ID
  push_var AD_FINIX_APPLICATION_ID NEXT_PUBLIC_FINIX_APPLICATION_ID
  push_var AD_FINIX_APPLICATION_ID FINIX_APPLICATION_ID
  # POS Finix creds (ENG-2595): finixCardOnFile bills the card that paid the order.
  push_var FINIX_USERNAME; push_var FINIX_PASSWORD; push_var FINIX_BASE_URL
  push_var SPARK_MERCHANT_ID; push_var OPENAI_API_KEY
  # spark_backend MySQL + its S3 file bucket (ENG-2863 Website Photos).
  push_var SPARK_BACKEND_MYSQL_URL; push_var S3_ACCESS_KEY_ID; push_var S3_SECRET_ACCESS_KEY
  push_var S3_BUCKET; push_var S3_REGION; push_var FILE_SERVER_URL; push_var WEBSITE_PHOTOS_S3_PREFIX
  # /api/agent/* + /api/mcp shared secret (ENG-2958).
  push_var AGENT_KEY
fi

echo "Building and deploying (preview)..."
vercel deploy --yes > "$DEPLOY_DIR/.deploy.log" 2>&1 || { echo "deploy failed:"; tail -20 "$DEPLOY_DIR/.deploy.log"; exit 1; }
URL=$(grep -o 'https://[a-z0-9.-]*\.vercel\.app' "$DEPLOY_DIR/.deploy.log" | tail -1)
[ -n "$URL" ] || { echo "no deployment URL in output:"; tail -20 "$DEPLOY_DIR/.deploy.log"; exit 1; }

# Previews sit behind Vercel Authentication; the project's Protection Bypass for
# Automation secret (VERCEL_BYPASS_<PORTAL|ADMIN>_<env> in spark-agent-tools/.env.vercel-rig,
# written by web-rig-bypass.sh) gets through.
if [ "$APP" = "portal" ]; then BYPASS_KEY="VERCEL_BYPASS_PORTAL_$ENV"; else BYPASS_KEY="VERCEL_BYPASS_ADMIN_$ENV"; fi
BYPASS=$(read_env_var "$HOME/Code/spark-agent-tools/.env.vercel-rig" "$BYPASS_KEY") || true
if [ -n "$BYPASS" ]; then HDR=(-H "x-vercel-protection-bypass: $BYPASS"); else HDR=(); fi
REDIRECT=$(curl -s -o /dev/null -w '%{redirect_url}' "${HDR[@]}" "$URL/login")
case "$REDIRECT" in
  *vercel.com/sso-api*)
    echo "BLOCKED: $PROJECT previews sit behind Vercel Authentication and no working bypass."
    echo "One-time, Carlos's terminal: ~/Code/spark-agent-tools/web-rig-bypass.sh $APP $ENV"
    exit 1 ;;
esac
echo "GET $URL/login -> reachable"
echo "$URL" > "$DEPLOY_DIR/.last-url"
echo "$URL"
