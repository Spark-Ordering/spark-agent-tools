#!/bin/bash
# Start spark_backend with workers for Codespace
# Logs: /tmp/rails.log, /tmp/worker.log

cd /workspaces/spark-agent-tools/spark_backend

# Source environment
if [ -f .env.local ]; then
    set -a
    source .env.local
    set +a
fi

# Ensure tmp/pids directory exists
mkdir -p tmp/pids

# Kill any existing processes
pkill -f "puma.*spark_backend" 2>/dev/null || true
pkill -f "delayed_job" 2>/dev/null || true
pkill -f "background_job" 2>/dev/null || true
sleep 1

# Start Rails server
echo "Starting Rails server..."
nohup bundle exec rails s -b 0.0.0.0 -p 3000 >> /tmp/rails.log 2>&1 &

# Wait for Rails to start
sleep 3

# Start workers
echo "Starting delayed_job workers..."
nohup bundle exec rails r lib/start_jobs.rb >> /tmp/worker.log 2>&1 &
nohup ruby lib/background_job start development >> /tmp/worker.log 2>&1 &

echo "spark_backend started. Logs:"
echo "  Rails:  /tmp/rails.log"
echo "  Worker: /tmp/worker.log"
