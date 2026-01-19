#!/bin/bash
set -e

# Usage: ./setup.sh [sparkpos-branch]
SPARKPOS_BRANCH=${1:-master}

echo "=== Spark Development Environment Setup ==="
echo "SparkPos branch: $SPARKPOS_BRANCH"

# 1. Clone repos using GitHub token
if [ -z "$GH_TOKEN" ]; then
  echo "ERROR: GH_TOKEN environment variable not set"
  echo "Pass it via: GH_TOKEN='your_token' ./setup.sh"
  exit 1
fi

echo "Cloning repositories..."
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
  mysql:8 &
MYSQL_START_PID=$!

# 3. Install Supabase CLI and gettext (for envsubst) - in background
(
  echo "[deps] Installing Supabase CLI and dependencies..."
  sudo apt-get update && sudo apt-get install -y gettext-base default-libmysqlclient-dev
  SUPABASE_DEB_URL=$(curl -sL https://api.github.com/repos/supabase/cli/releases/latest | grep -oE 'https://[^"]+linux_amd64\.deb' | head -1)
  curl -fsSL -o /tmp/supabase.deb "$SUPABASE_DEB_URL"
  sudo dpkg -i /tmp/supabase.deb
  touch /tmp/deps-done
  echo "[deps] Done!"
) &
DEPS_PID=$!

# Wait for Docker to be fully ready
echo "Waiting for Docker to be ready..."
until docker info > /dev/null 2>&1; do
  sleep 2
done
echo "Docker is ready!"

# Wait for MySQL container to start
wait $MYSQL_START_PID

# 4. MAXIMUM PARALLEL SETUP - Run everything concurrently
echo "Starting parallel setup (maximizing parallelization)..."

# Background job 1: Supabase start (pulls Docker images) - ONLY starts containers + creates .env files
(
  echo "[supabase] Starting Supabase..."
  cd sparkpos

  # Create admin-secret.ts with dev value
  cat > supabase/functions/admin-secret.ts << 'SECRETEOF'
export const ADMIN_SECRET = 'dev-secret-123';
SECRETEOF

  supabase start
  touch /tmp/supabase-containers-ready

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

  echo "[supabase] Creating .env.local files..."
  envsubst < "$ENV_TEMPLATES/sparkpos.env" > .env.local
  envsubst < "$ENV_TEMPLATES/requestmanager.env" > ../RequestManager/.env.local
  envsubst < "$ENV_TEMPLATES/spark_backend.env" > ../spark_backend/.env.local

  # Signal that .env.local files are ready - this unblocks Rails and SparkPos migrations
  touch /tmp/env-files-done
  echo "[supabase] Containers ready and .env files created!"
) &
SUPABASE_PID=$!

# Background job 2: Java setup
(
  echo "[java] Running mvn package (parallel)..."
  cd RequestManager
  mvn package -DskipTests -q -T 1C
  echo "[java] Done!"
) &
JAVA_PID=$!

# Background job 3: Node setup
(
  echo "[node] Running npm install..."
  cd sparkpos
  npm install --silent
  touch /tmp/npm-done
  echo "[node] Done!"
) &
NODE_PID=$!

# Background job 4: Ruby bundle install (starts immediately, doesn't wait for anything)
(
  echo "[ruby] Waiting for MySQL dev libraries..."
  while [ ! -f /tmp/deps-done ]; do sleep 1; done

  echo "[ruby] Running bundle install (parallel)..."
  cd spark_backend
  bundle install --quiet --jobs $(nproc)
  touch /tmp/bundle-done
  echo "[ruby] Bundle done!"
) &
BUNDLE_PID=$!

# Background job 5: Rails migrations (waits for: MySQL ready + bundle done + env-files)
(
  echo "[rails-migrate] Waiting for dependencies..."

  # Wait for bundle install
  while [ ! -f /tmp/bundle-done ]; do sleep 1; done

  # Wait for .env.local files
  while [ ! -f /tmp/env-files-done ]; do sleep 1; done

  # Wait for MySQL to be ready
  echo "[rails-migrate] Waiting for MySQL..."
  until docker exec mysql mysqladmin ping -h localhost --silent 2>/dev/null; do
    sleep 2
  done
  echo "[rails-migrate] MySQL ready!"

  cd spark_backend

  # Allow Codespace URLs in Rails
  echo 'Rails.application.config.hosts << /.*\.app\.github\.dev/' >> config/environments/development.rb

  # Create database.yml for local MySQL (from template)
  cp /workspaces/spark-agent-tools/.devcontainer/env-templates/database.yml config/database.yml

  # Run migrations
  echo "[rails-migrate] Running db:create db:migrate db:seed..."
  bundle exec rake db:create db:migrate db:seed

  echo "[rails-migrate] Running assets:precompile..."
  bundle exec rake assets:precompile

  touch /tmp/rails-done
  echo "[rails-migrate] Rails migrations complete!"
) &
RAILS_MIGRATE_PID=$!

# Background job 6: SparkPos migrations (waits for: npm done + env-files done)
# Runs IN PARALLEL with Rails migrations since they use different databases!
(
  echo "[sparkpos-migrate] Waiting for dependencies..."

  # Wait for npm install
  while [ ! -f /tmp/npm-done ]; do sleep 1; done

  # Wait for .env.local files (also means Supabase is up)
  while [ ! -f /tmp/env-files-done ]; do sleep 1; done

  cd sparkpos

  echo "[sparkpos-migrate] Running SparkPos migrations..."
  npx tsx supabase/migrations/run.ts

  echo "[sparkpos-migrate] Setting up default restaurant credentials..."
  curl -s -X POST "http://127.0.0.1:54321/functions/v1/set-restaurant-password" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer dev-secret-123" \
    -d '{"restaurantId": 113, "password": "dev123"}' \
    && echo "[sparkpos-migrate] Restaurant credentials set (id=113, password=dev123)"

  touch /tmp/sparkpos-done
  echo "[sparkpos-migrate] SparkPos migrations complete!"
) &
SPARKPOS_MIGRATE_PID=$!

# Wait for all jobs
echo "Waiting for all parallel jobs to complete..."

wait $DEPS_PID
echo "✓ Dependencies installed"

wait $SUPABASE_PID
echo "✓ Supabase containers ready"

wait $JAVA_PID
echo "✓ Java build complete"

wait $NODE_PID
echo "✓ Node install complete"

wait $BUNDLE_PID
echo "✓ Ruby bundle complete"

wait $RAILS_MIGRATE_PID
echo "✓ Rails migrations complete"

wait $SPARKPOS_MIGRATE_PID
echo "✓ SparkPos migrations complete"

touch /tmp/setup-complete
echo ""
echo "=== Environment ready! ==="
echo "Run ./codespace/start-all.sh to start services"
