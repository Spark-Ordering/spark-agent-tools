#!/bin/bash
# ENG-2736: Tuesday 9am launchd job filing the weekly user-wait audit ticket (claude label,
# active sprint) for /all-auto. One ticket per date: reruns skip. Env: DRY_RUN=1.
set -euo pipefail

source "$HOME/.config/jira-sweep.env"
LOG="${JIRA_WEEKLY_WAIT_AUDIT_LOG:-$HOME/Library/Logs/jira-weekly-wait-audit.log}"
DRY_RUN="${DRY_RUN:-0}"
STATE="${JIRA_WEEKLY_WAIT_AUDIT_STATE:-$HOME/.config/jira-weekly-wait-audit.state}"
BOARD_ID=2
CARLOS_ACCOUNT_ID="712020:3f7c6fe9-65f2-4059-8be9-2afe874e32f2"
SUMMARY="🤖 Weekly user-wait audit: $(date +%Y-%m-%d)"

log() { echo "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

api() { # api METHOD PATH [JSON_BODY]
  local method="$1" path="$2" body="${3:-}"
  local args=(-sS --fail-with-body -X "$method" -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -H "Accept: application/json")
  if [ -n "$body" ]; then args+=(-H "Content-Type: application/json" -d "$body"); fi
  curl "${args[@]}" "https://$JIRA_SITE_URL$path"
}

urlencode() { jq -rn --arg s "$1" '$s|@uri'; }

read -r -d '' DESCRIPTION <<'EOF' || true
Filed every Tuesday 9am by spark-agent-tools/jira-weekly-wait-audit.sh (ENG-2736). This ticket replaces a person doing this sweep by hand each week.

Find every place in the apps where a person waits on an outcome and nothing tells us when it is slow: a screen or page painting, data showing up, a tap responding, a payment, a print, a card reader, the cash drawer, any hardware. Look for new ones (code merged since last week's audit ticket) and old ones never covered. Do not stop at a pre-made list.

For each uncovered wait, instrument it the way staff actions already are (startStaffAction / endStaffAction, see /add-datadog-tracking), so the staff_action.latency monitor (datadog/monitors/staff-action-latency.json) tags the team in Slack when it takes more than 1 s. Exceptions are allowed: list each one with its reason in the PR.

When the wait is performance-based, add a Maestro perf E2E like print-latency, item-open-latency and rapid-tap-latency: run the action at least 10 times in a row and fail if any run takes more than 1 s.

Deliverable: one PR with the instrumentation and E2Es, and a table in the PR body of every wait point found (already covered / covered by this PR / exception + reason). Nothing uncovered found this week = say so on the ticket and close it.
EOF

# ADF doc: one paragraph per blank-line-separated block.
body_json() { # body_json SPRINT_ID
  jq -n --arg summary "$SUMMARY" --arg desc "$DESCRIPTION" --arg acct "$CARLOS_ACCOUNT_ID" --argjson sprint "$1" '{fields: {
    project: {key: "ENG"}, issuetype: {name: "Task"}, summary: $summary,
    labels: ["claude"], assignee: {accountId: $acct}, customfield_10020: $sprint,
    description: {type: "doc", version: 1, content: [$desc | split("\n\n")[]
      | {type: "paragraph", content: [{type: "text", text: .}]}]}}}'
}

main() {
  local jql existing sprint_id key
  # Jira search lags a fresh create by seconds, so a same-date marker is checked first.
  if grep -qxF "$SUMMARY" "$STATE" 2>/dev/null; then log "exists: marker for $SUMMARY, skipping"; return 0; fi
  jql="project = ENG AND summary ~ \"\\\"$SUMMARY\\\"\""
  existing="$(api GET "/rest/api/3/search/jql?jql=$(urlencode "$jql")&fields=summary&maxResults=5" \
    | jq -r --arg s "$SUMMARY" '.issues[] | select(.fields.summary == $s) | .key' | head -1)"
  if [ -n "$existing" ]; then log "exists: $existing ($SUMMARY), skipping"; return 0; fi

  sprint_id="$(api GET "/rest/agile/1.0/board/$BOARD_ID/sprint?state=active" | jq -r '.values[0].id')"
  if [ "$DRY_RUN" = "1" ]; then log "DRY_RUN would create:"; body_json "$sprint_id" | tee -a "$LOG"; return 0; fi

  key="$(api POST /rest/api/3/issue "$(body_json "$sprint_id")" | jq -r .key)"
  echo "$SUMMARY" >> "$STATE"
  log "created $key ($SUMMARY) in sprint $sprint_id"
}

main "$@"
