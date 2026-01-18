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

# 1. Clone repos fresh using git with token authentication
echo "Cloning repositories..."
git clone "https://${GH_TOKEN}@github.com/Spark-Ordering/spark_backend.git"
git clone "https://${GH_TOKEN}@github.com/Spark-Ordering/RequestManager.git"
git clone "https://${GH_TOKEN}@github.com/carlosdelivery/SparkPos.git" sparkpos

# 2. Start MySQL in Docker
echo "Starting MySQL..."
docker run -d --name mysql \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=spark_development \
  mysql:8

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
until docker exec mysql mysqladmin ping -h localhost --silent; do
  sleep 2
done
echo "MySQL is ready!"

# 3. Install Supabase CLI and start local Supabase
echo "Installing Supabase CLI..."
curl -fsSL https://supabase.com/install.sh | sh

# Wait for Docker to be fully ready
echo "Waiting for Docker to be ready..."
until docker info > /dev/null 2>&1; do
  sleep 2
done
echo "Docker is ready!"

echo "Starting Supabase..."
cd sparkpos
supabase start
cd ..

# 4. Setup spark_backend
echo "Setting up spark_backend..."
cd spark_backend
bundle install
cp .env.local.template .env.local
bundle exec rake db:create db:migrate db:seed
cd ..

# 5. Setup RequestManager
echo "Setting up RequestManager..."
cd RequestManager
mvn package -DskipTests
cd ..

# 6. Setup sparkpos
echo "Setting up sparkpos..."
cd sparkpos
npm install
cd ..

touch /tmp/setup-complete
echo ""
echo "=== Environment ready! ==="
echo "Run ./codespace/start-all.sh to start services"
