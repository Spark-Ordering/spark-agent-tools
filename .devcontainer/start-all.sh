#!/bin/bash
# Runs on every Codespace start (postStartCommand)
# Starts all services in the background

set -e

WORKDIR="/workspaces/spark-agent-tools"

echo "=== Starting Spark Services ==="

# Wait for setup to be complete (in case postStartCommand runs before postCreateCommand finishes)
if [ ! -f /tmp/setup-complete ]; then
  echo "Waiting for setup to complete..."
  while [ ! -f /tmp/setup-complete ]; do
    sleep 2
  done
fi

# Start MySQL if not running
if ! docker ps | grep -q mysql; then
  echo "Starting MySQL..."
  docker start mysql 2>/dev/null || docker run -d --name mysql \
    -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD=root \
    -e MYSQL_DATABASE=spark_development \
    mysql:8
fi

# Start Supabase if not running
if ! docker ps | grep -q supabase_db_sparkpos; then
  echo "Starting Supabase..."
  cd "$WORKDIR/sparkpos"
  supabase start
fi

# Start Rails server
echo "Starting Rails server on port 3000..."
cd "$WORKDIR/spark_backend"
pkill -f "rails server" 2>/dev/null || true
nohup bundle exec rails server -p 3000 -b 0.0.0.0 > /tmp/rails.log 2>&1 &

# NOTE: Metro is NOT started here - spawn-env.sh opens it interactively in a terminal window
# This avoids port conflicts when the user wants interactive Metro (R to reload, D for dev menu, etc.)

# Mark services as started
touch /tmp/services-started

echo ""
echo "=== Services Started ==="
echo "  Rails:    http://localhost:3000"
echo "  Supabase: http://localhost:54322"
echo ""
echo "Logs:"
echo "  Rails: /tmp/rails.log"
echo ""
echo "Metro: Run manually or use spawn-env.sh (opens in interactive terminal)"
