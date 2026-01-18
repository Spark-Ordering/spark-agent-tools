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

# 3. Install Supabase CLI
echo "Installing Supabase CLI..."
SUPABASE_DEB_URL=$(curl -sL https://api.github.com/repos/supabase/cli/releases/latest | grep -oE 'https://[^"]+linux_amd64\.deb' | head -1)
curl -fsSL -o /tmp/supabase.deb "$SUPABASE_DEB_URL"
sudo dpkg -i /tmp/supabase.deb

# Wait for Docker to be fully ready
echo "Waiting for Docker to be ready..."
until docker info > /dev/null 2>&1; do
  sleep 2
done
echo "Docker is ready!"

# 4. PARALLEL SETUP - Run all heavy tasks concurrently
echo "Starting parallel setup..."

# Background job 1: Supabase (pulls many Docker images)
(
  echo "[supabase] Starting Supabase..."
  cd sparkpos
  supabase start
  echo "[supabase] Done!"
) &
SUPABASE_PID=$!

# Background job 2: Ruby setup (apt-get + bundle install)
(
  echo "[ruby] Installing MySQL dev libraries..."
  sudo apt-get update && sudo apt-get install -y default-libmysqlclient-dev
  echo "[ruby] Running bundle install..."
  cd spark_backend
  bundle install
  echo "[ruby] Done!"
) &
RUBY_PID=$!

# Background job 3: Java setup
(
  echo "[java] Running mvn package..."
  cd RequestManager
  mvn package -DskipTests
  echo "[java] Done!"
) &
JAVA_PID=$!

# Background job 4: Node setup
(
  echo "[node] Running npm install..."
  cd sparkpos
  npm install
  echo "[node] Done!"
) &
NODE_PID=$!

# Wait for all parallel jobs
echo "Waiting for parallel jobs to complete..."
wait $RUBY_PID
echo "Ruby setup complete!"
wait $JAVA_PID
echo "Java setup complete!"
wait $NODE_PID
echo "Node setup complete!"
wait $SUPABASE_PID
echo "Supabase setup complete!"

# 5. Wait for MySQL and run migrations (depends on bundle install being done)
echo "Waiting for MySQL to be ready..."
until docker exec mysql mysqladmin ping -h localhost --silent; do
  sleep 2
done
echo "MySQL is ready!"

echo "Setting up spark_backend database..."
cd spark_backend

# Create .env.local with local MySQL config
cat > .env.local << 'ENVEOF'
RAILS_ENV=development
ENVEOF

# Patch database.yml to use TCP connection to Docker MySQL (remove socket, set credentials)
# The original uses Rails.application.secrets and socket, we override for local Docker
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

bundle exec rake db:create db:migrate db:seed
cd ..

touch /tmp/setup-complete
echo ""
echo "=== Environment ready! ==="
echo "Run ./codespace/start-all.sh to start services"
