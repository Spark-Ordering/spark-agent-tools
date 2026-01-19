#!/bin/bash
set -e

echo "=== Spark Development Environment Setup ==="

# Debug: Check if GH_TOKEN is available
echo "Checking for GH_TOKEN..."
if [ -z "$GH_TOKEN" ]; then
  echo "ERROR: GH_TOKEN not found. Available env vars:"
  env | grep -i token || echo "No token vars found"
  env | grep -i gh || echo "No GH vars found"
  exit 1
fi
echo "GH_TOKEN found (length: ${#GH_TOKEN})"

# 1. Clone repos in parallel
echo "Cloning repositories..."
git clone "https://${GH_TOKEN}@github.com/Spark-Ordering/spark_backend.git" &
git clone "https://${GH_TOKEN}@github.com/Spark-Ordering/RequestManager.git" &
git clone "https://${GH_TOKEN}@github.com/carlosdelivery/SparkPos.git" sparkpos &
wait
echo "Repos cloned!"

# 2. Start MySQL in Docker (runs in background, we'll wait later)
echo "Starting MySQL..."
docker run -d --name mysql \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=spark_development \
  mysql:8

# 3. Install Supabase CLI and Chromium (for React Native DevTools)
echo "Installing Supabase CLI and Chromium..."
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

# Background job 1: Supabase (pulls many Docker images) - runs independently
(
  echo "[supabase] Starting Supabase..."
  cd sparkpos

  # Create admin-secret.ts with dev value
  cat > supabase/functions/admin-secret.ts << 'SECRETEOF'
export const ADMIN_SECRET = 'dev-secret-123';
SECRETEOF

  supabase start

  # Wait for npm install to complete (we need dependencies for migrations)
  while [ ! -f /tmp/npm-done ]; do
    sleep 2
  done

  echo "[supabase] Running SparkPos migrations..."
  DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres" npx tsx supabase/migrations/run.ts

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

  # Configure Rails for local development
  cat > .env.local << 'ENVEOF'
RAILS_ENV=development
ENVEOF

  echo 'Rails.application.config.hosts << /.*\.app\.github\.dev/' >> config/environments/development.rb

  cat > config/database.yml << 'DBEOF'
default: &default
  adapter: mysql2
  encoding: utf8
  pool: 5
  timeout: 5000

development:
  <<: *default
  database: SPARK
  host: 127.0.0.1
  port: 3306
  username: root
  password: root

test:
  <<: *default
  database: SPARK_TEST
  host: 127.0.0.1
  port: 3306
  username: root
  password: root
DBEOF

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
