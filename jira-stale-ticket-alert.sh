#!/bin/bash
# ENG-2486 (local): weekday alert to #pos for current-sprint tickets stuck
# > STALE_DAYS in the same status. Ported from
# supabase/functions/jira-stale-ticket-alert. Re-alerts a ticket at most every
# REALERT_DAYS. State: ~/.config/jira-stale-ticket-alert.state (JSON).
set -euo pipefail

source "$HOME/.config/jira-sweep.env"
STATE="$HOME/.config/jira-stale-ticket-alert.state"
LOG="${JIRA_STALE_LOG:-$HOME/Library/Logs/jira-stale-ticket-alert.log}"
SLACK_BOT="$HOME/.claude/skills/claudeqs/slack-bot.sh"
POS_CHANNEL="${POS_CHANNEL:-C09BSTZ0DRU}"
MENTION="<@U0516TWQHGD> <@U0516TPEU2Z>"
STALE_DAYS=4
REALERT_DAYS=3
DRY_RUN="${DRY_RUN:-0}"

log() { echo "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

[ -f "$STATE" ] || echo '{}' > "$STATE"

api() {
  curl -sS --fail-with-body -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
    -H "Accept: application/json" "https://$JIRA_SITE_URL$1"
}
urlencode() { jq -rn --arg s "$1" '$s|@uri'; }

JQL='project = ENG AND sprint in openSprints() AND status IN ("To Do","In Progress","Hold") ORDER BY created ASC'

# Emit KEY\tSUMMARY\tSTATUS\tASSIGNEE\tCREATED\tACTIVE_SPRINT_ID per issue.
search_stale() {
  api "/rest/api/3/search/jql?jql=$(urlencode "$JQL")&maxResults=50&fields=summary,status,assignee,created,customfield_10020" \
    | jq -r '
      .issues[]
      | . as $i
      | ($i.fields.customfield_10020 // [] | map(select(.state=="active")) | .[0]) as $sp
      | select($sp)
      | [$i.key,
         $i.fields.summary,
         $i.fields.status.name,
         ($i.fields.assignee.displayName // "unassigned"),
         $i.fields.created,
         ($sp.id | tostring)]
      | @tsv'
}

# Emits days-in-status\tdays-in-sprint for one issue.
days_pair() {
  local key="$1" created="$2" sprint_id="$3" status="$4"
  local now_ms; now_ms=$(($(date +%s) * 1000))
  api "/rest/api/3/issue/$key?expand=changelog&fields=created" \
    | jq -r --arg status "$status" --arg sprint "$sprint_id" --arg created "$created" --argjson now "$now_ms" '
      def to_ms: sub("(\\.\\d+)?[+-]\\d\\d:?\\d\\d$"; "Z") | fromdateiso8601 * 1000;
      (.changelog.histories // []) as $h
      | ($created | to_ms) as $c0
      | ([$h[] | . as $H | .items[] | select(.field=="status" and .toString==$status) | ($H.created | to_ms)] | max // $c0) as $s_entered
      | ([$h[] | . as $H | .items[]
          | select(.field=="Sprint")
          | select((.to // "" | split(",") | map(gsub("^\\s+|\\s+$";"")) | index($sprint)))
          | ($H.created | to_ms)] | max // $c0) as $sp_added
      | (($now - $s_entered) / 86400000 | floor | tostring) + "\t" + (($now - $sp_added) / 86400000 | floor | tostring)'
}

# Escape for Slack mrkdwn.
slack_esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

throttled_recently() {
  local key="$1"
  python3 - "$STATE" "$key" "$REALERT_DAYS" <<'PY'
import json, sys, time
state = json.load(open(sys.argv[1]))
key, days = sys.argv[2], int(sys.argv[3])
last = state.get(key)
if not last: sys.exit(1)
if time.time() - last < days * 86400: sys.exit(0)
sys.exit(1)
PY
}

record_alerts() {
  python3 - "$STATE" "$@" <<'PY'
import json, sys, time
state_path, *keys = sys.argv[1:]
state = json.load(open(state_path))
now = time.time()
for k in keys: state[k] = now
json.dump(state, open(state_path, 'w'))
PY
}

# The prod edge function posts the same alert; skip if either already posted today.
posted_today() {
  local midnight; midnight=$(date -j -f '%Y-%m-%d %H:%M:%S' "$(date +%Y-%m-%d) 00:00:00" +%s)
  curl -sS --fail-with-body -H "Authorization: Bearer $(cat "$HOME/.claude/skills/claudeqs/.bot-token")" \
    "https://slack.com/api/conversations.history?channel=$POS_CHANNEL&oldest=$midnight&limit=200" \
    | jq -e '.ok and ([.messages[] | select(.text | contains("sitting in the same status for more than"))] | length > 0)' >/dev/null
}

main() {
  local rows lines=()
  if posted_today; then log "already posted today in $POS_CHANNEL, skipping"; return 0; fi
  rows="$(search_stale)"
  [ -z "$rows" ] && { log "no candidates"; return 0; }

  local to_alert_keys=()
  while IFS=$'\t' read -r key summary status assignee created sprint_id; do
    if throttled_recently "$key"; then
      log "throttle skip $key"; continue
    fi
    local pair d_status d_sprint
    pair="$(days_pair "$key" "$created" "$sprint_id" "$status")"
    d_status="${pair%%$'\t'*}"; d_sprint="${pair##*$'\t'}"
    if [ "$d_status" -lt "$STALE_DAYS" ] || [ "$d_sprint" -lt "$STALE_DAYS" ]; then
      continue
    fi
    local esc_summary esc_assignee
    esc_summary="$(printf %s "$summary" | slack_esc)"
    esc_assignee="$(printf %s "$assignee" | slack_esc)"
    lines+=("• <https://$JIRA_SITE_URL/browse/$key|$key> $esc_summary — $status, ${d_status}d in status, ${d_sprint}d in sprint, $esc_assignee")
    to_alert_keys+=("$key")
  done <<<"$rows"

  if [ "${#lines[@]}" -eq 0 ]; then log "nothing to alert"; return 0; fi

  local text
  text="$MENTION :hourglass_flowing_sand: ${#lines[@]} sprint ticket(s) sitting in the same status for more than ${STALE_DAYS} days:"
  local line; for line in "${lines[@]}"; do text+=$'\n'"$line"; done

  if [ "$DRY_RUN" = "1" ]; then
    log "DRY_RUN — would post ${#lines[@]} ticket(s):"
    printf '%s\n' "$text" | tee -a "$LOG"
    return 0
  fi

  "$SLACK_BOT" post "$POS_CHANNEL" "$text" >/dev/null
  record_alerts "${to_alert_keys[@]}"
  log "posted ${#lines[@]} ticket(s) to $POS_CHANNEL"
}

main "$@"
