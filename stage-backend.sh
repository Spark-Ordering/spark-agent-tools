#!/bin/bash
# stage-backend.sh — turn the Stage1 spark_backend (www.spark-stage.com) on/off via the prod API.
# Stage only: the stage key and host are hardcoded, nothing here can touch production. Docs: docs/stage-backend.md
#   start [--wait]   scale Stage1 EB envs to 1 (+ start the stage DB); --wait blocks until stage answers
#   stop             scale Stage1 EB envs to 0 (+ stop the stage DB 10 min later)
#   status           HTTP code of www.spark-stage.com (503 = off)
#   heartbeat        keep stage up through the 3 AM ET nightly shutdown (1 hour per beat)
set -euo pipefail

CONTROL_URL="https://app.sparkordering.com/falcon9"
STAGE_KEY="stage"
STAGE_URL="https://www.spark-stage.com"
KEY_FILE="$HOME/.config/spark/stage-control.env"
WAIT_SECONDS="${STAGE_BACKEND_WAIT_SECONDS:-1500}"
POLL_SECONDS="${STAGE_BACKEND_POLL_SECONDS:-30}"

stage_code() {
  curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$STAGE_URL/" || true
}

control() { # control <endpoint>: POST with the bearer key, print the JSON body, fail on non-ok
  if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: $KEY_FILE missing. One-time setup: put RAYCAST_API_KEY=<key> in it (same value as SPARK_E2E envControlApiKey)." >&2
    exit 1
  fi
  local RAYCAST_API_KEY=""
  # shellcheck disable=SC1090
  source "$KEY_FILE"
  if [ -z "$RAYCAST_API_KEY" ]; then
    echo "ERROR: RAYCAST_API_KEY is empty in $KEY_FILE" >&2
    exit 1
  fi
  local body
  body="$(curl -s --max-time 30 -X POST "$CONTROL_URL/environment/$1" \
    -H "Authorization: Bearer $RAYCAST_API_KEY" -H 'Content-Type: application/json' \
    -d "{\"stage_key\":\"$STAGE_KEY\"}")"
  echo "$body"
  grep -q '"ok":true' <<<"$body" || exit 1
}

heartbeat() {
  curl -s -o /dev/null --max-time 20 -X POST "$CONTROL_URL/e2e/heartbeat" || true
  echo "heartbeat sent"
}

wait_until_up() {
  local waited=0 code
  code="$(stage_code)"
  # ponytail: "up" = anything but 503/000 at the root URL; a deeper health check if this proves loose
  while [ "$code" = "503" ] || [ "$code" = "000" ]; do
    if [ "$waited" -ge "$WAIT_SECONDS" ]; then
      echo "ERROR: $STAGE_URL still $code after ${waited}s" >&2
      exit 1
    fi
    sleep "$POLL_SECONDS"
    waited=$((waited + POLL_SECONDS))
    code="$(stage_code)"
  done
  echo "stage up: $STAGE_URL $code after ${waited}s"
}

case "${1:-}" in
  start)
    control start_aws_stage
    heartbeat
    if [ "${2:-}" = "--wait" ]; then wait_until_up; fi
    ;;
  stop)
    control stop_aws_stage
    ;;
  status)
    echo "$STAGE_URL $(stage_code)"
    ;;
  heartbeat)
    heartbeat
    ;;
  *)
    echo "usage: stage-backend.sh start [--wait] | stop | status | heartbeat" >&2
    exit 2
    ;;
esac
