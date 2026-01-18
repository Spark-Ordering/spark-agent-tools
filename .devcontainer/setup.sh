#!/bin/bash
set -e

echo "=== Spark Development Environment Setup ==="

# Export GH_TOKEN as GITHUB_TOKEN for gh CLI authentication
export GITHUB_TOKEN="${GH_TOKEN}"

# 1. Clone repos fresh (using gh CLI which handles auth automatically)
echo "Cloning repositories..."
gh repo clone tecno40/spark_backend
gh repo clone Spark-Ordering/RequestManager
gh repo clone carlosdelivery/SparkPos sparkpos

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

# 3. Start local Supabase (Postgres + Edge Functions)
echo "Starting Supabase..."
cd sparkpos
npm install -g supabase
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
