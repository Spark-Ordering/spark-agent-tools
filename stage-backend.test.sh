#!/bin/bash
# Self-check for stage-backend.sh against a fake curl. Run: bash stage-backend.test.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/stage-backend.sh"
export FIXTURES; FIXTURES="$(mktemp -d)"
export HOME="$FIXTURES/home" PATH="$HERE/stage-backend.test:$PATH" STAGE_BACKEND_POLL_SECONDS=0
fail() { echo "FAIL: $*"; exit 1; }
mkdir -p "$HOME/.config/spark"

bash "$SCRIPT" start 2>"$FIXTURES/err" && fail "start without key file succeeded"
grep -q "stage-control.env missing" "$FIXTURES/err" || fail "missing-key message: $(cat "$FIXTURES/err")"
[ ! -f "$FIXTURES/curl.log" ] || fail "called the API without a key"

printf 'RAYCAST_API_KEY=fake-key\n' >"$HOME/.config/spark/stage-control.env"
printf '{"ok":true,"database":"starting","stage_key":"stage"}' >"$FIXTURES/body"
printf '503\n503\n200\n' >"$FIXTURES/codes"
out="$(bash "$SCRIPT" start --wait)"
grep -q "stage up: https://www.spark-stage.com 200" <<<"$out" || fail "wait: $out"
grep -q "fake-key" <<<"$out" && fail "key printed"
api="$(grep -F 'environment/start_aws_stage' "$FIXTURES/curl.log")" || fail "start not called"
grep -qF 'https://app.sparkordering.com/falcon9/environment/start_aws_stage' <<<"$api" || fail "host: $api"
grep -qF '{"stage_key":"stage"}' <<<"$api" || fail "stage key: $api"
grep -qF '/falcon9/e2e/heartbeat' "$FIXTURES/curl.log" || fail "no heartbeat after start"

printf '{"ok":false,"error":"Unauthorized"}' >"$FIXTURES/body"
bash "$SCRIPT" stop >/dev/null && fail "stop with a rejected key succeeded"

: >"$FIXTURES/curl.log"
bash "$SCRIPT" stop production >/dev/null 2>&1 || true
grep -q "production" "$FIXTURES/curl.log" && fail "an argument reached the API"
bash "$SCRIPT" restart 2>/dev/null && fail "unknown subcommand accepted"
grep -c "stage_key" "$HERE/stage-backend.sh" | grep -qx 1 || fail "stage key must appear once, hardcoded"
echo "ok: key required + never printed, stage-only payload, prod control host, heartbeat, wait, rejects"
