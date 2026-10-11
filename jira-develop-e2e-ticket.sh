#!/bin/bash
# ENG-2850: daily 9am launchd job that, every 2nd day, files "Run All E2Es on Develop and Fix - MM/DD"
# (claude label, active sprint) for /all-auto. Env: DRY_RUN=1, TODAY=YYYY-MM-DD (test hook).
set -euo pipefail

source "$HOME/.config/jira-sweep.env"
LOG="${JIRA_DEVELOP_E2E_TICKET_LOG:-$HOME/Library/Logs/jira-develop-e2e-ticket.log}"
DRY_RUN="${DRY_RUN:-0}"
# One "YYYY-MM-DD<TAB>summary" line per filing; the last line is the 2-day clock.
STATE="${JIRA_DEVELOP_E2E_TICKET_STATE:-$HOME/.config/jira-develop-e2e-ticket.state}"
TODAY="${TODAY:-$(date +%Y-%m-%d)}"
EVERY_DAYS=2
BOARD_ID=2
CARLOS_ACCOUNT_ID="712020:3f7c6fe9-65f2-4059-8be9-2afe874e32f2"
SUMMARY="🤖 Run All E2Es on Develop and Fix - $(date -j -f %Y-%m-%d "$TODAY" +%m/%d)"

log() { echo "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

api() { # api METHOD PATH [JSON_BODY]
  local method="$1" path="$2" body="${3:-}"
  local args=(-sS --fail-with-body -X "$method" -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -H "Accept: application/json")
  if [ -n "$body" ]; then args+=(-H "Content-Type: application/json" -d "$body"); fi
  curl "${args[@]}" "https://$JIRA_SITE_URL$path"
}

urlencode() { jq -rn --arg s "$1" '$s|@uri'; }

# Whole days from the last filing to TODAY; 9999 when nothing was ever filed. +12h absorbs DST.
days_since_last() {
  local last
  last="$(tail -1 "$STATE" 2>/dev/null | cut -f1)"
  if [ -z "$last" ]; then echo 9999; return 0; fi
  echo $(( ($(date -j -f %Y-%m-%d "$TODAY" +%s) - $(date -j -f %Y-%m-%d "$last" +%s) + 43200) / 86400 ))
}

read -r -d '' DESCRIPTION <<'EOF' || true
Filed every 2 days at 9am by spark-agent-tools/jira-develop-e2e-ticket.sh (ENG-2850). It replaces the 2 random e2e:release tests that used to ride on the first PR of each day.

Run this ticket with /develop-e2e-run-fix <this ticket's key>. Do not run the normal /full-auto build steps.

What it does: one full pass of every SparkPos Maestro E2E against the tip of develop on the 4 Bigboy emulators (develop2 / develop5 / develop7 / develop8), then the /release-e2e-run-fix triage and fix-proof rounds for each failure, then ONE pull request with the test-side and e2e-infra fixes, taken through /pr-wrap-up-phase and merged into develop by the normal auto-merge.

Skip rule: if release E2Es or any other non-develop E2E run is already going on Bigboy, skip this round. Say so in a comment on this ticket and move it to Done. The next ticket comes in 2 days.

Nothing failed and nothing to fix = post the counts on this ticket and move it to Done.
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
  local days jql existing sprint_id key
  days="$(days_since_last)"
  if [ "$days" -lt "$EVERY_DAYS" ]; then log "skip: last filed $days day(s) ago, next at $EVERY_DAYS"; return 0; fi
  # MM/DD repeats every year, so only a ticket created in the last 2 days counts as this round's.
  jql="project = ENG AND created >= -2d AND summary ~ \"\\\"$SUMMARY\\\"\""
  existing="$(api GET "/rest/api/3/search/jql?jql=$(urlencode "$jql")&fields=summary&maxResults=5" \
    | jq -r --arg s "$SUMMARY" '.issues[] | select(.fields.summary == $s) | .key' | head -1)"
  if [ -n "$existing" ]; then log "exists: $existing ($SUMMARY), skipping"; return 0; fi

  sprint_id="$(api GET "/rest/agile/1.0/board/$BOARD_ID/sprint?state=active" | jq -r '.values[0].id')"
  if [ "$DRY_RUN" = "1" ]; then log "DRY_RUN would create:"; body_json "$sprint_id" | tee -a "$LOG"; return 0; fi

  key="$(api POST /rest/api/3/issue "$(body_json "$sprint_id")" | jq -r .key)"
  printf '%s\t%s\n' "$TODAY" "$SUMMARY" >> "$STATE"
  log "created $key ($SUMMARY) in sprint $sprint_id"
}

main "$@"
