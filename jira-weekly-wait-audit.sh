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

# ENG-3010: once production's goal-loops-to-jira files this loop's ticket, this launchd job removes itself.
retire_if_filed_by_goal_loops() { # retire_if_filed_by_goal_loops ISSUE_KEY
  local label="com.carlos.jira-weekly-wait-audit"
  if ! api GET "/rest/api/3/issue/$1?fields=description" | grep -q 'goal-loops-to-jira'; then return 0; fi
  log "retired: $1 was filed by goal-loops-to-jira; removing launchd job $label"
  rm -f "$HOME/Library/LaunchAgents/$label.plist"
  launchctl bootout "gui/$(id -u)/$label"
}

read -r -d '' DESCRIPTION <<'EOF' || true
Filed every Tuesday 9am by spark-agent-tools/jira-weekly-wait-audit.sh (ENG-2736). This ticket replaces a person doing this sweep by hand each week.

Find every place in the apps where a person waits on an outcome and nothing tells us when it is slow: a screen or page painting, data showing up, a tap responding, a payment, a print, a card reader, the cash drawer, any hardware. Look for new ones (code merged since last week's audit ticket) and old ones never covered. Do not stop at a pre-made list.

Only add what is missing. A wait that is already instrumented keeps its instrumentation; a case that already has a perf E2E keeps it. Work only on what is not covered yet.

Everything this sweep finds is covered in THIS ticket's PR, this week. Never defer a wait point to next week's audit ticket and never list one as "not covered yet". A surface with no way to time it yet (a KDS or Online Orders device with no e2e latency badge, admin-dashboard and portal pages with no web telemetry) gets that path built in this PR.

For each uninstrumented wait, instrument it the way staff actions already are (startStaffAction / endStaffAction, see /add-datadog-tracking), so the per-restaurant monitor (datadog/monitors/restaurant-staff-action-slow.json) posts to #incidents the first time it takes more than 1 s.

Alert rule, never relax it: every monitor that pages #incidents ({{PAGE_INCIDENTS}}) fires on the FIRST slow event (">= 1" / critical 1). Never add an "N or more in M minutes" cap, never raise a threshold to quiet a monitor, never use an @slack- handle (Datadog has no Slack integration). scripts/checks/datadogMonitorChecker.js blocks the merge gate on any of these. Also check the live monitors in Datadog match the repo and that a slow event in the last week actually posted to #incidents; if one did not, fix it in this PR.

When the wait is performance-based and has no perf E2E for that case, add a Maestro perf E2E like print-latency, item-open-latency and rapid-tap-latency: run the action at least 10 times in a row and fail if any run takes 1 s or more (on the rig assert the badge's max as max=[0-9]{1,3}). A run over 1 s fails its checklist box, so the PR cannot merge until the slow code is fixed; never loosen the cap to pass. One feature can need several perf E2Es when there are different ways to exercise it (e.g. cash vs card, small vs large order); add one per way worth testing.

Fix what #incidents keeps alerting on (Slack channel C09EZTKUAAE, private; read it with the Slack MCP). Read every alert posted there in the last 7 days (POS running slow / staff_action.latency, Prints running slow / print.button_to_print_latency, POS offline, card reader, display, and any other kind) and count them per action and restaurant. Older posts name only the restaurant, not the action: get the action from the production logs over 1 s in Datadog for the same window (staff_action.latency by @action, print.button_to_print_latency). Every action that alerted 3 or more times in the week is part of this ticket, most alerts first: reproduce it on that restaurant's data (/perf-debugging), fix the cause so it stays under 1 s, and give it a perf E2E as above. Fix the slow code, never the alert.

Deliverable: one PR with the instrumentation, fixes and E2Es. In the PR body, every wait point found is its own checkbox line, "- [ ] <wait point>: <staff action> / <perf E2E>", ticked only once it is instrumented and its perf E2E passed on the rig (already covered ones go in ticked, naming their existing action and E2E). The merge gate blocks on any unticked box, so the PR cannot merge with a wait point left uncovered. Below them, a table of every repeated #incidents alert (alert, action, count, restaurants, cause, fix). Nothing uncovered and no alert repeated 3+ times this week = say so on the ticket and close it.
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
  if [ -n "$existing" ]; then
    log "exists: $existing ($SUMMARY), skipping"
    if [ "$DRY_RUN" != "1" ]; then retire_if_filed_by_goal_loops "$existing"; fi
    return 0
  fi

  sprint_id="$(api GET "/rest/agile/1.0/board/$BOARD_ID/sprint?state=active" | jq -r '.values[0].id')"
  if [ "$DRY_RUN" = "1" ]; then log "DRY_RUN would create:"; body_json "$sprint_id" | tee -a "$LOG"; return 0; fi

  key="$(api POST /rest/api/3/issue "$(body_json "$sprint_id")" | jq -r .key)"
  echo "$SUMMARY" >> "$STATE"
  log "created $key ($SUMMARY) in sprint $sprint_id"
}

main "$@"
