#!/bin/bash
# Adds lowercase "claude" to any active-sprint ENG ticket labelled "Claude" (any case) that
# lacks it — downstream scripts match the lowercase label. Env: DRY_RUN=1.
set -euo pipefail

source "$HOME/.config/jira-sweep.env"
JQL='project = ENG AND sprint in openSprints() AND labels = Claude'
LOG="${JIRA_CLAUDE_LABEL_LOG:-$HOME/Library/Logs/jira-claude-label.log}"
DRY_RUN="${DRY_RUN:-0}"

log() { echo "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

api() { # api METHOD PATH [JSON_BODY]
  local method="$1" path="$2" body="${3:-}"
  local args=(-sS --fail-with-body -X "$method" -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -H "Accept: application/json")
  if [ -n "$body" ]; then args+=(-H "Content-Type: application/json" -d "$body"); fi
  curl "${args[@]}" "https://$JIRA_SITE_URL$path"
}

urlencode() { jq -rn --arg s "$1" '$s|@uri'; }

# Emits keys needing the label, paginating. Filters in jq: JQL label matching is
# case-insensitive, so the query alone cannot tell "Claude" from "claude".
needs_label() {
  local token="" resp
  while :; do
    resp="$(api GET "/rest/api/3/search/jql?jql=$(urlencode "$JQL")&fields=labels&maxResults=100&nextPageToken=$token")"
    jq -r '.issues[] | (.fields.labels // []) as $l
      | select(($l | index("claude") | not) and any($l[]; ascii_downcase == "claude")) | .key' <<<"$resp"
    token="$(jq -r '.nextPageToken // empty' <<<"$resp")"
    [ -z "$token" ] && break
  done
}

main() {
  local key checked=0 labelled=0
  for key in $(needs_label); do
    checked=$((checked + 1))
    if [ "$DRY_RUN" = "1" ]; then log "DRY_RUN would label $key claude"; labelled=$((labelled + 1)); continue; fi
    if api PUT "/rest/api/3/issue/$key" '{"update":{"labels":[{"add":"claude"}]}}' >/dev/null; then
      log "labelled $key claude"; labelled=$((labelled + 1))
    else
      log "ERROR $key: label PUT failed, continuing"
    fi
  done
  log "done: checked=$checked labelled=$labelled dry_run=$DRY_RUN"
}

main "$@"
