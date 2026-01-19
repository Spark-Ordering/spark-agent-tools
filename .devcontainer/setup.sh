#!/bin/bash
set -e

# Usage: ./setup.sh [sparkpos-branch]
SPARKPOS_BRANCH=${1:-master}

echo "=== Spark Development Environment Setup ==="
echo "SparkPos branch: $SPARKPOS_BRANCH"

# 1. Clone repos using GitHub token
echo "DEBUG: GH_TOKEN length = ${#GH_TOKEN}"
echo "DEBUG: GH_TOKEN starts with = ${GH_TOKEN:0:4}..."
if [ -z "$GH_TOKEN" ]; then
  echo "ERROR: GH_TOKEN environment variable not set"
  echo "Pass it via: GH_TOKEN='your_token' ./setup.sh"
  exit 1
fi

echo "Cloning repositories..."
echo "DEBUG: Clone URL will be: https://[token]@github.com/..."
git clone "https://${GH_TOKEN}@github.com/Spark-Ordering/spark_backend.git" &
git clone "https://${GH_TOKEN}@github.com/Spark-Ordering/RequestManager.git" &
git clone "https://${GH_TOKEN}@github.com/carlosdelivery/SparkPos.git" sparkpos &
wait
echo "Repos cloned!"

# Checkout SparkPos branch if not master
if [ "$SPARKPOS_BRANCH" != "master" ]; then
  echo "Checking out SparkPos branch: $SPARKPOS_BRANCH"
  cd sparkpos && git checkout "$SPARKPOS_BRANCH" && cd ..
fi

# 2. Start MySQL in Docker (runs in background, we'll wait later)
echo "Starting MySQL..."
docker run -d --name mysql \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=spark_development \
  mysql:8

# 3. Install Supabase CLI and gettext (for envsubst)
echo "Installing Supabase CLI and dependencies..."
sudo apt-get update && sudo apt-get install -y gettext-base
SUPABASE_DEB_URL=$(curl -sL https://api.github.com/repos/supabase/cli/releases/latest | grep -oE 'https://[^"]+linux_amd64\.deb' | head -1)
curl -fsSL -o /tmp/supabase.deb "$SUPABASE_DEB_URL"
sudo dpkg -i /tmp/supabase.deb

# Note: React Native DevTools opens in your LOCAL browser via port forwarding
# Don't set EDGE_PATH in Codespace - there's no display server
# Press J in Metro, then open http://localhost:8081/debugger-ui/ on your Mac

# Wait for Docker to be fully ready
echo "Waiting for Docker to be ready..."
until docker info > /dev/null 2>&1; do
  sleep 2
done
echo "Docker is ready!"

# 4. PARALLEL SETUP - Run all heavy tasks concurrently
echo "Starting parallel setup..."

# Background job 1: Supabase (pulls many Docker images) - creates .env.local files
(
  echo "[supabase] Starting Supabase..."
  cd sparkpos

  # Create admin-secret.ts with dev value
  cat > supabase/functions/admin-secret.ts << 'SECRETEOF'
export const ADMIN_SECRET = 'dev-secret-123';
SECRETEOF

  supabase start

  # Extract Supabase keys from status output
  echo "[supabase] Extracting Supabase keys..."
  SUPABASE_STATUS=$(supabase status 2>/dev/null)
  export SUPABASE_ANON_KEY=$(echo "$SUPABASE_STATUS" | grep "anon key:" | awk '{print $NF}')
  export SUPABASE_SERVICE_KEY=$(echo "$SUPABASE_STATUS" | grep "service_role key:" | awk '{print $NF}')

  # Fallback to well-known local Supabase keys if extraction failed
  if [ -z "$SUPABASE_ANON_KEY" ]; then
    export SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
    echo "[supabase] Using default local anon key"
  fi
  if [ -z "$SUPABASE_SERVICE_KEY" ]; then
    export SUPABASE_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
    echo "[supabase] Using default local service role key"
  fi

  # Generate Rails secret key
  export SECRET_KEY=$(openssl rand -hex 64)

  # Create .env.local files from templates (substituting variables)
  ENV_TEMPLATES="/workspaces/spark-agent-tools/.devcontainer/env-templates"

  echo "[supabase] Creating SparkPos .env.local..."
  envsubst < "$ENV_TEMPLATES/sparkpos.env" > .env.local

  echo "[supabase] Creating RequestManager .env.local..."
  envsubst < "$ENV_TEMPLATES/requestmanager.env" > ../RequestManager/.env.local

  echo "[supabase] Creating spark_backend .env.local..."
  envsubst < "$ENV_TEMPLATES/spark_backend.env" > ../spark_backend/.env.local

  echo "[supabase] All .env.local files created"

  # Signal that .env.local files are ready
  touch /tmp/env-files-done

  # Wait for npm install to complete (we need dependencies for migrations)
  while [ ! -f /tmp/npm-done ]; do
    sleep 2
  done

  echo "[supabase] Running SparkPos migrations..."
  npx tsx supabase/migrations/run.ts

  echo "[supabase] Setting up default restaurant credentials..."
  # Call the edge function to set password (restaurant_id=113, password=dev123)
  curl -s -X POST "http://127.0.0.1:54321/functions/v1/set-restaurant-password" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer dev-secret-123" \
    -d '{"restaurantId": 113, "password": "dev123"}' \
    && echo "[supabase] Restaurant credentials set (id=113, password=dev123)"

  touch /tmp/supabase-done
  echo "[supabase] Done!"
) &
SUPABASE_PID=$!

# Background job 2: Java setup
(
  echo "[java] Running mvn package..."
  cd RequestManager
  mvn package -DskipTests
  echo "[java] Done!"
) &
JAVA_PID=$!

# Background job 3: Node setup
(
  echo "[node] Running npm install..."
  cd sparkpos
  npm install
  touch /tmp/npm-done
  echo "[node] Done!"
) &
NODE_PID=$!

# Background job 4: Ruby setup -> immediately followed by rake tasks
# This is the critical path, so we chain bundle -> rake without waiting for others
(
  echo "[ruby] Installing MySQL dev libraries..."
  sudo apt-get update && sudo apt-get install -y default-libmysqlclient-dev
  echo "[ruby] Running bundle install..."
  cd spark_backend
  bundle install
  echo "[ruby] Bundle done! Starting Rails setup..."

  # Wait for MySQL to be ready (needed for rake tasks)
  echo "[ruby] Waiting for MySQL..."
  until docker exec mysql mysqladmin ping -h localhost --silent 2>/dev/null; do
    sleep 2
  done
  echo "[ruby] MySQL ready!"

  # Wait for .env.local to be created by Supabase job
  echo "[ruby] Waiting for .env.local files..."
  while [ ! -f /tmp/env-files-done ]; do
    sleep 2
  done
  echo "[ruby] .env.local ready!"

  # Allow Codespace URLs in Rails
  echo 'Rails.application.config.hosts << /.*\.app\.github\.dev/' >> config/environments/development.rb

  # Create database.yml for local MySQL (from template)
  cp /workspaces/spark-agent-tools/.devcontainer/env-templates/database.yml config/database.yml

  # Run migrations and asset precompilation
  echo "[ruby] Running db:create db:migrate db:seed..."
  bundle exec rake db:create db:migrate db:seed
  echo "[ruby] Running assets:precompile..."
  bundle exec rake assets:precompile
  touch /tmp/rails-done
  echo "[ruby] Rails setup complete!"
) &
RUBY_PID=$!

# Wait for independent jobs (Java, Node)
wait $JAVA_PID
echo "Java setup complete!"
wait $NODE_PID
echo "Node setup complete!"

# Wait for Ruby (critical path - includes rake tasks)
wait $RUBY_PID
echo "Ruby + Rails setup complete!"

# Wait for Supabase if still running (it's independent but we want clean exit)
if [ ! -f /tmp/supabase-done ]; then
  echo "Waiting for Supabase to finish..."
  wait $SUPABASE_PID
fi
echo "Supabase setup complete!"

touch /tmp/setup-complete
echo ""
echo "=== Environment ready! ==="
echo "Run ./codespace/start-all.sh to start services"
