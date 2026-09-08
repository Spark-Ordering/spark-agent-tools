#!/bin/bash
# Moves ENG active-sprint tickets labelled "active" from To Do -> In Progress.
# Only touches the ENG board / current sprint. Env: DRY_RUN=1.
set -euo pipefail

source "$HOME/.config/jira-sweep.env"
TARGET_STATUS="In Progress"
JQL='project = ENG AND sprint in openSprints() AND labels = active AND status = "To Do"'
LOG="${JIRA_ACTIVATE_LOG:-$HOME/Library/Logs/jira-activate.log}"
DRY_RUN="${DRY_RUN:-0}"

log() { echo "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

api() { # api METHOD PATH [JSON_BODY]
  local method="$1" path="$2" body="${3:-}"
  local args=(-sS --fail-with-body -X "$method" -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -H "Accept: application/json")
  if [ -n "$body" ]; then args+=(-H "Content-Type: application/json" -d "$body"); fi
  curl "${args[@]}" "https://$JIRA_SITE_URL$path"
}

urlencode() { jq -rn --arg s "$1" '$s|@uri'; }

# All issue keys matching JQL, following nextPageToken until exhausted.
todo_issue_keys() {
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

main() {
  local keys checked=0 moved=0 key
  keys="$(todo_issue_keys)"
  for key in $keys; do
    checked=$((checked + 1))
    transition_to_target "$key" && moved=$((moved + 1))
  done
  log "done: checked=$checked moved=$moved dry_run=$DRY_RUN"
}

main "$@"
