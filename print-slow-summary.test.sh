#!/bin/bash
# Self-check for print-slow-summary.sh against a fake curl + slack-bot. Run: bash print-slow-summary.test.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/print-slow-summary.sh"
export FIXTURES; FIXTURES="$(mktemp -d)"
export PRINT_SLOW_SUMMARY_LOG="$FIXTURES/run.log" PRINT_SLOW_SUMMARY_STATE="$FIXTURES/state"
export DD_ENV_FILE="$FIXTURES/env" SLACK_BOT="$HERE/print-slow-summary.test/slack-bot.sh"
export NOW_EPOCH=1791327600 # 2026-10-06 16:00 PT
export PATH="$HERE/print-slow-summary.test:$PATH"
fail() { echo "FAIL: $*"; exit 1; }
printf 'DD_API_KEY=fake-api\nDD_APP_KEY=fake-app\nOTHER=x\n' >"$FIXTURES/env"

ev() { # ev restaurant elapsed outcome jobs_created claimed connection_checked instructions_built sent
  jq -cn --arg r "$1" --argjson e "$2" --arg o "$3" --argjson j "$4" --argjson c "$5" --argjson k "$6" --argjson b "$7" --argjson s "$8" \
    '{attributes:{attributes:{restaurant_name:$r,elapsed_ms:$e,outcome:$o,jobs_created_ms:$j,claimed_ms:$c,
      connection_checked_ms:$k,instructions_built_ms:$b,sent_ms:$s}}}'
}
# SubWing: 3 slow (send dominates), 1 of them failed. Cafe X: 1 slow (build dominates) + 1 fast failure.
jq -cs '{data:., meta:{page:{after:"CUR2"}}}' \
  <(ev SubWing 1200 completed 50 100 300 400 1150; ev SubWing 2500 failed 50 150 350 500 2400) >"$FIXTURES/page1.json"
jq -cs '{data:., meta:{page:{}}}' \
  <(ev SubWing 16100 completed 60 120 320 520 16000; ev "Cafe X" 3000 completed 40 90 200 2800 2950
    ev "Cafe X" 300 failed 40 90 200 250 280) >"$FIXTURES/page2.json"

out="$(DRY_RUN=1 bash "$SCRIPT")"
[ ! -f "$FIXTURES/slack.log" ] || fail "dry run posted"
[ "$(wc -l <"$FIXTURES/requests.log" | tr -d ' ')" = 2 ] || fail "expected 2 pages"
q="$(head -1 "$FIXTURES/requests.log" | jq -r .filter.query)"
grep -q -- '-service:eng-2785-forced-test -@trigger:forced_test' <<<"$q" || fail "test events not excluded: $q"
grep -q 'env:production' <<<"$q" || fail "not production: $q"
[ "$(head -1 "$FIXTURES/requests.log" | jq -r .filter.from)" = "2026-10-05T23:00:00Z" ] || fail "window start"
grep -qF '• *SubWing*: 3 over 1 s, p50 2.5 s, max 16.1 s, 1 failed. Stage p50: create job 0.1 s, pickup 0.1 s, printer check 0.2 s, build ticket 0.2 s, *send 1.9 s*' <<<"$out" \
  || fail "SubWing line: $out"
grep -qF '• *Cafe X*: 1 over 1 s, p50 3 s, max 3 s, 1 failed. Stage p50: create job 0 s, pickup 0.1 s, printer check 0.1 s, *build ticket 2.6 s*, send 0.2 s' <<<"$out" \
  || fail "Cafe X line: $out"
[ "$(grep -n 'SubWing' <<<"$out" | cut -d: -f1)" -lt "$(grep -n 'Cafe X' <<<"$out" | cut -d: -f1)" ] || fail "order"
grep -qF 'from_ts=1791241200000&to_ts=1791327600000&live=false' <<<"$out" || fail "dashboard window: $out"
echo "ok: pagination, exclusions, per-restaurant stats, slowest stage bolded"

bash "$SCRIPT" >/dev/null
bash "$SCRIPT" >/dev/null
[ "$(cut -f1 "$FIXTURES/slack.log" | tr '\n' ' ')" = "post update " ] || fail "rerun must update: $(cat "$FIXTURES/slack.log")"
[ "$(awk -F'\t' 'NR == 2 {print $3}' "$FIXTURES/slack.log")" = "1791300000.000100" ] || fail "update ts"
NOW_EPOCH=$((NOW_EPOCH + 86400 - 60)) bash "$SCRIPT" >/dev/null
NOW_EPOCH=$((NOW_EPOCH + 86400)) bash "$SCRIPT" >/dev/null
[ "$(cut -f1 "$FIXTURES/slack.log" | tr '\n' ' ')" = "post update update post " ] || fail "4 pm boundary: $(cut -f1 "$FIXTURES/slack.log")"
echo "ok: first run posts, reruns before the next 4 pm update it, the next 4 pm posts anew"

jq -cn '{data:[], meta:{page:{}}}' >"$FIXTURES/page1.json"
out="$(DRY_RUN=1 bash "$SCRIPT")"
grep -qF '• No production prints over 1 s and no failed prints.' <<<"$out" || fail "empty day: $out"
echo "ok: empty day"

rm -rf "$FIXTURES"
echo "ALL OK"
