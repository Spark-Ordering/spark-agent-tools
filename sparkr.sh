#!/bin/bash

# sparkr - Build and run Spark backend or RequestManager from source
# Usage:
#   sparkr spb              - Build and run spark_backend
#   sparkr rq               - Build and run RequestManager

set -e

# Load repo finder utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/repo-finder.sh"

# Source directories
SPB_DIR=$(find_repo "spark_backend.git")
RQ_DIR=$(find_repo "RequestManager.git")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[sparkr]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[sparkr]${NC} $1"
}

log_error() {
    echo -e "${RED}[sparkr]${NC} $1"
}

# Load .env.local from a specific project directory
load_env_from() {
    local project_dir="$1"
    local env_file="$project_dir/.env.local"

    if [[ ! -f "$env_file" ]]; then
        log_error "Env file not found: $env_file"
        exit 1
    fi

    log_info "Loading env from: $env_file"
    set -a
    source "$env_file"
    set +a
}

# Kill previous RequestManager instances
kill_requestmanager() {
    local pids=$(pgrep -f "java.*RequestManager" 2>/dev/null)
    if [[ -n "$pids" ]]; then
        log_info "Killing previous RequestManager instances..."
        pkill -f "java.*RequestManager" 2>/dev/null || true
        sleep 1
    fi
}

# Kill previous spark_backend instances (server + worker)
kill_spark_backend() {
    local port_pids=$(lsof -ti tcp:3000 2>/dev/null)
    if [[ -n "$port_pids" ]]; then
        log_info "Killing processes on port 3000..."
        echo "$port_pids" | xargs kill -9 2>/dev/null || true
    fi

    pkill -f "delayed_job" 2>/dev/null || true
    pkill -f "background_job" 2>/dev/null || true
    pkill -f "start_worker_dev" 2>/dev/null || true
    sleep 1
}

# Kill existing ngrok processes
kill_ngrok() {
    pkill -f "ngrok" 2>/dev/null || true
    sleep 1
}

# Start ngrok and update Supabase secrets
setup_ngrok() {
    local supabase_project_ref="zwlmfjkauvgnphnayoup"  # Dev environment

    kill_ngrok

    log_info "Starting ngrok tunnel to port 3000..."
    ngrok http 3000 > /tmp/ngrok.log 2>&1 &
    local ngrok_pid=$!

    # Wait for ngrok to start
    sleep 3

    # Get the public URL
    local ngrok_url=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"https://[^"]*"' | head -1 | cut -d'"' -f4)

    if [[ -z "$ngrok_url" ]]; then
        log_error "Failed to get ngrok URL"
        return 1
    fi

    log_info "ngrok URL: $ngrok_url"

    # Get the API key from spark_backend .env.local
    local api_key=$(grep "SPARK_POS_API_KEY" "$SPB_DIR/.env.local" 2>/dev/null | cut -d'=' -f2 | tr -d '"')

    # Update Supabase secrets
    log_info "Updating Supabase secrets..."
    supabase secrets set SPARK_BACKEND_URL="$ngrok_url" SPARK_BACKEND_API_KEY="$api_key" --project-ref "$supabase_project_ref" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        log_info "Supabase secrets updated (URL + API key)"
    else
        log_warn "Failed to update Supabase secrets (supabase CLI may not be installed)"
    fi

    echo "$ngrok_pid"
}

# Build and run RequestManager
run_requestmanager() {
    kill_requestmanager
    load_env_from "$RQ_DIR"

    cd "$RQ_DIR"

    log_info "Building RequestManager (mvn package)..."
    mvn package -q

    log_info "Starting RequestManager..."
    log_info "Overriding SPARK_BACKEND_URL -> http://localhost:3000"
    export SPARK_BACKEND_URL="http://localhost:3000"

    # Auto-restart loop
    local run_count=0
    while true; do
        run_count=$((run_count + 1))
        log_info "Starting RequestManager (run #$run_count)..."
        java -jar dist/RequestManager.jar
        log_warn "RequestManager exited. Restarting in 5 seconds... (Ctrl+C to stop)"
        sleep 5
    done
}

# Build and run spark_backend
run_spark_backend() {
    kill_spark_backend
    load_env_from "$SPB_DIR"

    cd "$SPB_DIR"

    # Ensure tmp/pids directory exists for DelayedJob
    mkdir -p tmp/pids

    log_info "Installing gems..."
    bundle install --quiet

    log_info "Precompiling assets..."
    bundle exec rake assets:precompile --quiet

    # Clear stale delayed_jobs to ensure fresh start
    log_info "Clearing stale delayed_jobs..."
    bundle exec rails r "ActiveRecord::Base.connection.execute('DELETE FROM delayed_jobs')" 2>/dev/null || true

    # Start ngrok and update Supabase secret
    setup_ngrok

    # Start worker in background (must use staging to match Rails server)
    log_info "Starting delayed_job worker in staging environment..."
    bundle exec rails r lib/start_jobs.rb
    ruby lib/background_job start staging &
    local worker_pid=$!

    trap "log_info 'Stopping worker...'; kill $worker_pid 2>/dev/null; pkill -f 'delayed_job' 2>/dev/null; kill_ngrok" EXIT

    log_info "Starting rails server on port 3000..."
    bundle exec rails server -b 0.0.0.0 -p 3000
}

# Show usage
show_usage() {
    echo "sparkr - Build and run Spark apps from source"
    echo ""
    echo "Usage:"
    echo "  sparkr spb             Build and run spark_backend"
    echo "  sparkr rq              Build and run RequestManager"
}

# Main
main() {
    local arg="$1"

    if [[ -z "$arg" ]]; then
        show_usage
        exit 0
    fi

    if [[ "$arg" == "spb" ]]; then
        run_spark_backend
    elif [[ "$arg" == "rq" ]]; then
        run_requestmanager
    else
        log_error "Unknown argument: $arg"
        show_usage
        exit 1
    fi
}

main "$@"
