#!/bin/bash
set -e

# Rails Track: apt-get + bundle + MySQL + migrations
# Fully independent - can run in parallel with other tracks

echo "[rails] Starting track..."

# Start MySQL container (will pull image if needed)
echo "[rails] Starting MySQL container..."
docker run -d --name mysql \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=spark_development \
  mysql:8

# Install system dependencies (needed for mysql2 gem)
echo "[rails] Installing system dependencies..."
sudo apt-get update && sudo apt-get install -y gettext-base default-libmysqlclient-dev

# Bundle install (parallel)
echo "[rails] Running bundle install..."
cd /workspaces/spark-agent-tools/spark_backend
bundle install --quiet --jobs $(nproc)

# Wait for MySQL to be ready
echo "[rails] Waiting for MySQL..."
until docker exec mysql mysqladmin ping -h localhost --silent 2>/dev/null; do
  sleep 2
done
echo "[rails] MySQL ready!"

# Wait for .env.local (created by sparkpos track)
echo "[rails] Waiting for .env.local..."
while [ ! -f .env.local ]; do sleep 1; done
echo "[rails] .env.local found!"

# Configure Rails for Codespace
echo 'Rails.application.config.hosts << /.*\.app\.github\.dev/' >> config/environments/development.rb

# Copy database.yml
cp /workspaces/spark-agent-tools/.devcontainer/env-templates/database.yml config/database.yml

# Run migrations
echo "[rails] Running db:create db:migrate db:seed..."
bundle exec rake db:create db:migrate db:seed

# Seed test restaurant data (Athens Wok Local)
echo "[rails] Seeding test restaurant data..."
/workspaces/spark-agent-tools/seed-test-restaurant.sh

echo "[rails] Running assets:precompile..."
bundle exec rake assets:precompile

touch /tmp/rails-track-done
echo "[rails] Track complete!"
