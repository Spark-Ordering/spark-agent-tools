#!/bin/bash
# ENG-2802: 4pm PT launchd job posting the last 24 h of production prints over 1 s to #engineering.
# A rerun the same PT day edits that day's post. Env: DRY_RUN=1 prints instead of posting.
set -euo pipefail

LOG="${PRINT_SLOW_SUMMARY_LOG:-$HOME/Library/Logs/print-slow-summary.log}"
STATE="${PRINT_SLOW_SUMMARY_STATE:-$HOME/.config/print-slow-summary.state}"
DD_ENV_FILE="${DD_ENV_FILE:-$HOME/Code/SparkPos/.env.develop1}"
SLACK_BOT="${SLACK_BOT:-$HOME/.claude/skills/claudeqs/slack-bot.sh}"
DRY_RUN="${DRY_RUN:-0}"
NOW_EPOCH="${NOW_EPOCH:-$(date +%s)}"
CHANNEL="C0516TVR79B"
DASHBOARD="https://us5.datadoghq.com/dashboard/2ph-uk6-56r"
QUERY='env:production "print.button_to_print_latency" (@elapsed_ms:>=1000 OR @outcome:failed) -service:eng-2785-forced-test -@trigger:forced_test'

log() { echo "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

# Datadog keys are org-wide; only these two lines are sourced and never printed.
eval "$(grep -E '^DD_(API|APP)_KEY=' "$DD_ENV_FILE" | awk '{print "export " $0}')"
: "${DD_API_KEY:?DD_API_KEY missing in $DD_ENV_FILE}" "${DD_APP_KEY:?DD_APP_KEY missing in $DD_ENV_FILE}"

FROM_EPOCH=$((NOW_EPOCH - 86400))
iso() { date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ; }
pt() { TZ=America/Los_Angeles date -r "$1" "+%b %-d %-I:%M %p"; }
# Report day runs 4 pm to 4 pm PT, so a manual run before 4 pm edits yesterday's post, not today's.
DAY="$(TZ=America/Los_Angeles date -r $((NOW_EPOCH - 16 * 3600)) +%Y-%m-%d)"

events="$(mktemp)"
trap 'rm -f "$events"' EXIT
cursor=""
while :; do
  body="$(jq -cn --arg q "$QUERY" --arg from "$(iso "$FROM_EPOCH")" --arg to "$(iso "$NOW_EPOCH")" --arg c "$cursor" \
    '{filter:{query:$q,from:$from,to:$to,indexes:["*"]},sort:"timestamp",page:({limit:1000} + (if $c == "" then {} else {cursor:$c} end))}')"
  page="$(curl -sS --fail-with-body -X POST "https://api.us5.datadoghq.com/api/v2/logs/events/search" \
    -H "DD-API-KEY: $DD_API_KEY" -H "DD-APPLICATION-KEY: $DD_APP_KEY" -H "Content-Type: application/json" -d "$body")"
  jq -c '.data[].attributes.attributes' <<<"$page" >>"$events"
  cursor="$(jq -r '.meta.page.after // empty' <<<"$page")"
  [ -n "$cursor" ] || break
done

link="$DASHBOARD?from_ts=$((FROM_EPOCH * 1000))&to_ts=$((NOW_EPOCH * 1000))&live=false"
text="$(jq -rs --arg header "Production prints over 1 s, $(pt "$FROM_EPOCH") to $(pt "$NOW_EPOCH") PT" --arg link "$link" '
  def s: (. / 100 | round) / 10 | tostring + " s";
  def p50: sort | .[((length + 1) / 2 | floor) - 1];
  def stage(a; b): [.[] | select(.[a] != null and .[b] != null) | .[a] - .[b]] | if length == 0 then null else p50 end;
  group_by(.restaurant_name // (.restaurant_id | tostring))
  | map(. as $all | ([.[] | select(.elapsed_ms >= 1000)]) as $slow | {
      name: ($all[0].restaurant_name // ($all[0].restaurant_id | tostring)),
      slow: ($slow | length),
      failed: ([$all[] | select(.outcome == "failed")] | length),
      p50: ([$slow[].elapsed_ms] | if length == 0 then null else p50 end),
      max: ([$slow[].elapsed_ms] | max),
      stages: ([["create job", ($slow | [.[] | .jobs_created_ms // empty] | if length == 0 then null else p50 end)],
                ["pickup", ($slow | stage("claimed_ms"; "jobs_created_ms"))],
                ["printer check", ($slow | stage("connection_checked_ms"; "claimed_ms"))],
                ["build ticket", ($slow | stage("instructions_built_ms"; "connection_checked_ms"))],
                ["send", ($slow | stage("sent_ms"; "instructions_built_ms"))]] | map(select(.[1] != null)))})
  | sort_by(-.slow, -.failed)
  | (if length == 0 then ["• No production prints over 1 s and no failed prints."] else map(
      . as $r | ((($r.stages | max_by(.[1])) // [null])[0]) as $top
      | "• *\($r.name)*: \($r.slow) over 1 s"
        + (if $r.slow > 0 then ", p50 \($r.p50 | s), max \($r.max | s)" else "" end)
        + ", \($r.failed) failed"
        + (if ($r.stages | length) > 0 then ". Stage p50: " + ($r.stages | map(
            if .[0] == $top then "*\(.[0]) \(.[1] | s)*" else "\(.[0]) \(.[1] | s)" end) | join(", ")) else "" end))
    end)
  | (["🖨️ " + $header] + . + ["<" + $link + "|POS Print Latency PROD dashboard>"]) | join("\n")
' "$events")"

if [ "$DRY_RUN" = "1" ]; then
  echo "$text"
  log "dry run: day=$DAY events=$(wc -l <"$events" | tr -d ' ')"
  exit 0
fi

mkdir -p "$(dirname "$STATE")"
touch "$STATE"
ts="$(awk -v d="$DAY" '$1 == d {print $2}' "$STATE" | tail -1)"
if [ -n "$ts" ]; then
  resp="$(bash "$SLACK_BOT" update "$CHANNEL" "$ts" "$text")"
  action="updated"
else
  resp="$(bash "$SLACK_BOT" post "$CHANNEL" "$text")"
  action="posted"
fi
[ "$(jq -r .ok <<<"$resp")" = "true" ] || { log "slack $action failed: $(jq -c '{ok,error}' <<<"$resp")"; exit 1; }
ts="$(jq -r .ts <<<"$resp")"
if [ "$action" = "posted" ]; then echo "$DAY $ts" >>"$STATE"; fi
log "$action day=$DAY ts=$ts events=$(wc -l <"$events" | tr -d ' ')"
