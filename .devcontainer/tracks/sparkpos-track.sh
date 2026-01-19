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

# Extract keys and create .env.local
echo "[sparkpos] Creating .env.local files..."
SUPABASE_STATUS=$(supabase status 2>/dev/null)
export SUPABASE_ANON_KEY=$(echo "$SUPABASE_STATUS" | grep "anon key:" | awk '{print $NF}')
export SUPABASE_SERVICE_KEY=$(echo "$SUPABASE_STATUS" | grep "service_role key:" | awk '{print $NF}')

# Fallback to well-known local keys
if [ -z "$SUPABASE_ANON_KEY" ]; then
  export SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
fi
if [ -z "$SUPABASE_SERVICE_KEY" ]; then
  export SUPABASE_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
fi

export SECRET_KEY=$(openssl rand -hex 64)

ENV_TEMPLATES="/workspaces/spark-agent-tools/.devcontainer/env-templates"
envsubst < "$ENV_TEMPLATES/sparkpos.env" > .env.local
envsubst < "$ENV_TEMPLATES/requestmanager.env" > ../RequestManager/.env.local
envsubst < "$ENV_TEMPLATES/spark_backend.env" > ../spark_backend/.env.local

# Run migrations
echo "[sparkpos] Running migrations..."
npx tsx supabase/migrations/run.ts

# Set restaurant password
echo "[sparkpos] Setting restaurant credentials..."
curl -s -X POST "http://127.0.0.1:54321/functions/v1/set-restaurant-password" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dev-secret-123" \
  -d '{"restaurantId": 113, "password": "dev123"}'

touch /tmp/sparkpos-track-done
echo "[sparkpos] Track complete!"
