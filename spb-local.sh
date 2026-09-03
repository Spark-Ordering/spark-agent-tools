#!/bin/bash
# spb-local — run spark_backend against a LOCAL Docker MySQL (ENG-2533 slice 3).
#
# Staging MySQL is unreachable from the Mac, so DB-backed spark_backend work runs
# here: a mysql:8.0 container seeded with the current schema (db/schema.rb) and
# the Deli House test franchise (~/Code/franchise_data.sql, dumped from staging
# 2025-06). Rails picks the DB up through DATABASE_URL, which overrides the
# socket in config/database.yml's `development` block — no repo change needed.
#
# Usage:
#   spb-local.sh up        start (or create) the container; load schema + seed if empty
#   spb-local.sh run       `up`, then rails server :3000 + delayed_job worker (development)
#   spb-local.sh status    container state + row counts
#   spb-local.sh reset     drop and rebuild the container from scratch
#   spb-local.sh down      stop the container (data kept)
#   spb-local.sh env       print the DATABASE_URL line to eval into your shell
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/repo-finder.sh"
SPB_DIR=$(find_repo "spark_backend.git")

CONTAINER=spark-mysql-local
PORT=3307
DB=SPARK
DB_USER=spark
DB_PASS=spark
export DATABASE_URL="mysql2://${DB_USER}:${DB_PASS}@127.0.0.1:${PORT}/${DB}"
export RAILS_ENV=development
SEED_DUMP="${SPB_LOCAL_SEED_DUMP:-$HOME/Code/franchise_data.sql}"
SEED_PY="$SCRIPT_DIR/spb-local-seed.py"

log() { echo -e "\033[0;32m[spb-local]\033[0m $1"; }
die() { echo -e "\033[0;31m[spb-local]\033[0m $1" >&2; exit 1; }

mysql_exec() { docker exec -i "$CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" "$@" 2> >(grep -v "Using a password" >&2); }

wait_ready() {
  # `mysqladmin ping` says alive during first-boot init (temp server, no users yet);
  # a real TCP login only works once the actual server is up.
  for _ in $(seq 1 90); do
    if docker exec "$CONTAINER" mysql -h127.0.0.1 -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1" >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  die "MySQL container did not become ready in 90s"
}

ensure_container() {
  docker info >/dev/null 2>&1 || { log "Starting Docker Desktop..."; open -a Docker; for _ in $(seq 1 60); do docker info >/dev/null 2>&1 && break; sleep 2; done; }
  docker info >/dev/null 2>&1 || die "Docker daemon not available"
  if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER"; then
    docker ps --format '{{.Names}}' | grep -qx "$CONTAINER" || { log "Starting $CONTAINER..."; docker start "$CONTAINER" >/dev/null; }
  else
    log "Creating $CONTAINER (mysql:8.0 on :$PORT)..."
    docker run -d --name "$CONTAINER" -p "$PORT:3306" \
      -e MYSQL_ROOT_PASSWORD="$DB_PASS" -e MYSQL_DATABASE="$DB" \
      -e MYSQL_USER="$DB_USER" -e MYSQL_PASSWORD="$DB_PASS" mysql:8.0 >/dev/null
  fi
  wait_ready
  docker exec "$CONTAINER" mysql -uroot -p"$DB_PASS" -e \
    "CREATE DATABASE IF NOT EXISTS ${DB}_TEST; GRANT ALL ON ${DB}_TEST.* TO '$DB_USER'@'%'; GRANT ALL ON ${DB}.* TO '$DB_USER'@'%'; FLUSH PRIVILEGES;" 2>/dev/null
}

table_count() { mysql_exec -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB'"; }
franchise_count() { mysql_exec -N "$DB" -e "SELECT COUNT(*) FROM franchises"; }

ensure_schema() {
  if [ "$(table_count)" -eq 0 ]; then
    log "Loading db/schema.rb..."
    (cd "$SPB_DIR" && bundle exec rails db:schema:load >/dev/null)
  fi
  # schema.rb lags db/migrate (2026-07-04 vs newer migrations); Rails 500s on
  # PendingMigrationError in development until they run. Idempotent.
  log "Applying pending migrations..."
  (cd "$SPB_DIR" && bundle exec rails db:migrate >/dev/null && git checkout -q -- db/schema.rb 2>/dev/null || true)
  log "Schema ready ($(table_count) tables)"
}

ensure_seed() {
  if [ "$(franchise_count)" -gt 0 ]; then log "Seed present ($(franchise_count) franchises)"; return; fi
  [ -f "$SEED_DUMP" ] || die "seed dump not found: $SEED_DUMP (set SPB_LOCAL_SEED_DUMP)"
  log "Seeding from $SEED_DUMP (columns matched to the live schema)..."
  python3 "$SEED_PY" "$SEED_DUMP" "$CONTAINER" "$DB" "$DB_USER" "$DB_PASS" > /tmp/spb-local-seed.sql
  mysql_exec "$DB" < /tmp/spb-local-seed.sql
  log "Seeded ($(franchise_count) franchises)"
}

cmd_up() { ensure_container; ensure_schema; ensure_seed; log "Ready: $DATABASE_URL"; }

cmd_status() {
  docker ps -a --filter "name=$CONTAINER" --format 'container: {{.Names}} {{.Status}}'
  docker ps --format '{{.Names}}' | grep -qx "$CONTAINER" || return 0
  mysql_exec "$DB" -e "SELECT 'franchises' t, COUNT(*) n FROM franchises UNION ALL SELECT 'restaurants', COUNT(*) FROM restaurants UNION ALL SELECT 'menu_categories', COUNT(*) FROM menu_categories UNION ALL SELECT 'orders', COUNT(*) FROM orders"
}

cmd_run() {
  cmd_up
  cd "$SPB_DIR"
  mkdir -p tmp/pids
  # Kill a previous local server/worker on this port.
  lsof -ti tcp:3000 2>/dev/null | xargs kill -9 2>/dev/null || true
  pkill -f "background_job start development" 2>/dev/null || true
  log "Starting delayed_job worker (development)..."
  ruby lib/background_job start development &
  WORKER_PID=$!
  trap "kill $WORKER_PID 2>/dev/null; pkill -f 'background_job start development' 2>/dev/null" EXIT
  log "Starting rails server on :3000 (development, local MySQL)..."
  exec bundle exec rails server -b 0.0.0.0 -p 3000
}

cmd_reset() { docker rm -f "$CONTAINER" >/dev/null 2>&1 || true; log "Removed $CONTAINER"; cmd_up; }
cmd_down() { docker stop "$CONTAINER" >/dev/null && log "Stopped $CONTAINER (data kept)"; }
cmd_env() { echo "export RAILS_ENV=development DATABASE_URL=$DATABASE_URL"; }

case "${1:-}" in
  up) cmd_up ;;
  run) cmd_run ;;
  status) cmd_status ;;
  reset) cmd_reset ;;
  down) cmd_down ;;
  env) cmd_env ;;
  *) sed -n '2,15p' "$0"; exit 1 ;;
esac
