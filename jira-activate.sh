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

# Timestamp of the most recent changelog entry that added the "active" label;
# falls back to issue creation when the label was set at create time.
active_added_at() {
  local key="$1" start=0 resp ts=""
  while :; do
    resp="$(api GET "/rest/api/3/issue/$key/changelog?maxResults=100&startAt=$start")"
    ts="$(jq -r --arg prev "$ts" '[.values[] | select(.items[] | .field == "labels" and ((.toString // "") | split(" ") | index("active")) and ((.fromString // "") | split(" ") | index("active") | not)) | .created] + [$prev] | map(select(. != "")) | max // ""' <<<"$resp")"
    [ "$(jq -r '.isLast' <<<"$resp")" = "true" ] && break
    start=$((start + 100))
  done
  [ -n "$ts" ] || ts="$(api GET "/rest/api/3/issue/$key?fields=created" | jq -r '.fields.created')"
  echo "$ts"
}

remove_active_label() {
  local key="$1"
  if [ "$DRY_RUN" = "1" ]; then log "DRY_RUN would remove 'active' from $key"; return 0; fi
  api PUT "/rest/api/3/issue/$key" '{"update":{"labels":[{"remove":"active"}]}}' >/dev/null
  log "removed 'active' from $key"
}

# Keep "active" only on the ticket it was most recently added to.
dedupe_active() {
  local all_jql='project = ENG AND sprint in openSprints() AND labels = active'
  local keys key ranked keep
  keys="$(JQL="$all_jql" todo_issue_keys)"
  [ "$(wc -w <<<"$keys")" -gt 1 ] || return 0
  ranked="$(for key in $keys; do echo "$(active_added_at "$key") $key"; done | sort)"
  keep="$(tail -1 <<<"$ranked" | awk '{print $2}')"
  log "dedupe: keeping $keep ($(tail -1 <<<"$ranked" | awk '{print $1}'))"
  for key in $(sed '$d' <<<"$ranked" | awk '{print $2}'); do remove_active_label "$key"; done
}

main() {
  local keys checked=0 moved=0 key
  dedupe_active
  keys="$(todo_issue_keys)"
  for key in $keys; do
    checked=$((checked + 1))
    transition_to_target "$key" && moved=$((moved + 1))
  done
  log "done: checked=$checked moved=$moved dry_run=$DRY_RUN"
}

main "$@"
