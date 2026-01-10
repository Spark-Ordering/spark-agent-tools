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

    # Start worker in background
    log_info "Starting worker via start_worker_dev.py..."
    python3 "$SPB_DIR/start_worker_dev.py" &
    local worker_pid=$!

    trap "log_info 'Stopping worker...'; kill $worker_pid 2>/dev/null; pkill -f 'delayed_job' 2>/dev/null" EXIT

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
