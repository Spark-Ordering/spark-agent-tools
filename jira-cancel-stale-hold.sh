#!/bin/bash
# Daily (launchd com.carlos.jira-cancel-stale-hold): ENG active-sprint tickets labelled claude+paused
# that have sat in Hold >= 7 days -> Cancelled, with a "move back to To Do" comment. PRs are left open
# (Trent, 2026-10-07). No Slack post. Env: DRY_RUN=1, STALE_DAYS (default 7).
set -euo pipefail

source "$HOME/.config/jira-sweep.env"
TARGET_STATUS="Cancelled"
STALE_DAYS="${STALE_DAYS:-7}"
JQL="project = ENG AND sprint in openSprints() AND status = Hold AND labels = claude AND labels = paused AND NOT status CHANGED AFTER -${STALE_DAYS}d"
COMMENT="Cancelled for now, feel free to move back to To Do and remove the paused label if you would like to resume it."
LOG="${JIRA_CANCEL_LOG:-$HOME/Library/Logs/jira-cancel-stale-hold.log}"
DRY_RUN="${DRY_RUN:-0}"

log() { echo "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

api() { # api METHOD PATH [JSON_BODY]
  local method="$1" path="$2" body="${3:-}"
  local args=(-sS --fail-with-body -X "$method" -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -H "Accept: application/json")
  if [ -n "$body" ]; then args+=(-H "Content-Type: application/json" -d "$body"); fi
  curl "${args[@]}" "https://$JIRA_SITE_URL$path"
}

urlencode() { jq -rn --arg s "$1" '$s|@uri'; }

stale_issue_keys() {
  local token="" resp
  while :; do
    resp="$(api GET "/rest/api/3/search/jql?jql=$(urlencode "$JQL")&fields=key&maxResults=100&nextPageToken=$token")"
    jq -r '.issues[].key' <<<"$resp"
    token="$(jq -r '.nextPageToken // empty' <<<"$resp")"
    [ -z "$token" ] && break
  done
}

transition_to_target() {
  local key="$1" id
  id="$(api GET "/rest/api/3/issue/$key/transitions" | jq -r --arg s "$TARGET_STATUS" 'first(.transitions[] | select(.to.name == $s) | .id)')"
  [ -n "$id" ] || { log "ERROR $key: no transition to '$TARGET_STATUS'"; return 1; }
  if [ "$DRY_RUN" = "1" ]; then log "DRY_RUN would move $key -> $TARGET_STATUS"; return 0; fi
  api POST "/rest/api/3/issue/$key/transitions" "{\"transition\":{\"id\":\"$id\"}}" >/dev/null
  log "moved $key -> $TARGET_STATUS"
}

add_comment() {
  local key="$1" body
  body="$(jq -cn --arg t "$COMMENT" '{body:{type:"doc",version:1,content:[{type:"paragraph",content:[{type:"text",text:$t}]}]}}')"
  if [ "$DRY_RUN" = "1" ]; then log "DRY_RUN would comment on $key"; return 0; fi
  api POST "/rest/api/3/issue/$key/comment" "$body" >/dev/null
  log "commented on $key"
}

main() {
  local key checked=0 moved=0
  for key in $(stale_issue_keys); do
    checked=$((checked + 1))
    if ! transition_to_target "$key"; then log "ERROR $key: transition failed, skipping comment"; continue; fi
    moved=$((moved + 1))
    add_comment "$key" || log "ERROR $key: comment failed, continuing"
  done
  log "done: checked=$checked moved=$moved stale_days=$STALE_DAYS dry_run=$DRY_RUN"
}

main "$@"
