#!/bin/bash
set -e

# SparkPos Track: Supabase + npm + migrations
# Fully independent - can run in parallel with other tracks

SPARKPOS_BRANCH=${1:-master}
echo "[sparkpos] Starting track (branch: $SPARKPOS_BRANCH)..."

cd /workspaces/spark-agent-tools/sparkpos

# Checkout branch if not master
if [ "$SPARKPOS_BRANCH" != "master" ]; then
  echo "[sparkpos] Checking out branch: $SPARKPOS_BRANCH"
  git checkout "$SPARKPOS_BRANCH"
fi

# Create admin-secret.ts with dev value
cat > supabase/functions/admin-secret.ts << 'EOF'
export const ADMIN_SECRET = 'dev-secret-123';
EOF

# Start supabase and npm install in parallel
echo "[sparkpos] Starting supabase + npm install in parallel..."
supabase start &
SUPABASE_PID=$!

npm install --silent &
NPM_PID=$!

# Wait for both
wait $NPM_PID
echo "[sparkpos] npm install done"

wait $SUPABASE_PID
echo "[sparkpos] supabase start done"

# Extract keys from Supabase and create .env.local
echo "[sparkpos] Creating .env.local files..."
SUPABASE_JSON=$(supabase status --output json 2>/dev/null)
export SUPABASE_ANON_KEY=$(echo "$SUPABASE_JSON" | jq -r '.ANON_KEY')
export SUPABASE_SERVICE_KEY=$(echo "$SUPABASE_JSON" | jq -r '.SERVICE_ROLE_KEY')

export SECRET_KEY=$(openssl rand -hex 64)

ENV_TEMPLATES="/workspaces/spark-agent-tools/.devcontainer/env-templates"
envsubst < "$ENV_TEMPLATES/sparkpos.env" > .env.local
envsubst < "$ENV_TEMPLATES/requestmanager.env" > ../RequestManager/.env.local
envsubst < "$ENV_TEMPLATES/spark_backend.env" > ../spark_backend/.env.local

# Run migrations
echo "[sparkpos] Running migrations..."
npx tsx supabase/migrations/run.ts

# Create PowerSync publication (required for sync to work)
echo "[sparkpos] Creating PowerSync publication..."
docker exec supabase_db_sparkpos psql -U postgres -c "CREATE PUBLICATION powersync FOR ALL TABLES;" 2>/dev/null || echo "[sparkpos] Publication already exists"

# Default test restaurant configuration
RESTAURANT_ID=23
FRANCHISE_ID=25
RESTAURANT_NAME="Athens Wok Local"
RESTAURANT_PASSWORD="password"

# Create restaurant record
echo "[sparkpos] Creating restaurant record..."
curl -s -X POST "http://127.0.0.1:54321/functions/v1/create-restaurant" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dev-secret-123" \
  -d "{\"restaurantId\": ${RESTAURANT_ID}, \"franchiseId\": ${FRANCHISE_ID}, \"name\": \"${RESTAURANT_NAME}\"}"
echo ""

# Sync menu catalog from spark_backend
echo "[sparkpos] Syncing menu catalog..."
curl -s -X POST "http://127.0.0.1:54321/functions/v1/catalog" \
  -H "Content-Type: application/json" \
  -d "{\"restaurant_id\": ${RESTAURANT_ID}, \"pos_menu_franchise_id\": ${FRANCHISE_ID}}"
echo ""

# Set restaurant password
echo "[sparkpos] Setting restaurant credentials..."
curl -s -X POST "http://127.0.0.1:54321/functions/v1/set-restaurant-password" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dev-secret-123" \
  -d "{\"restaurantId\": ${RESTAURANT_ID}, \"password\": \"${RESTAURANT_PASSWORD}\"}"
echo ""

touch /tmp/sparkpos-track-done
echo "[sparkpos] Track complete!"
echo "[sparkpos] Login with: Restaurant ID=${RESTAURANT_ID}, Password=${RESTAURANT_PASSWORD}"
