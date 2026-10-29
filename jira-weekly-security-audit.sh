#!/bin/bash
# ENG-2948: Wednesday 9am launchd job filing the weekly security audit ticket (claude label,
# active sprint) for /all-auto. One ticket per date: reruns skip. Env: DRY_RUN=1, TODAY=YYYY-MM-DD.
set -euo pipefail

source "$HOME/.config/jira-sweep.env"
LOG="${JIRA_WEEKLY_SECURITY_AUDIT_LOG:-$HOME/Library/Logs/jira-weekly-security-audit.log}"
DRY_RUN="${DRY_RUN:-0}"
STATE="${JIRA_WEEKLY_SECURITY_AUDIT_STATE:-$HOME/.config/jira-weekly-security-audit.state}"
TODAY="${TODAY:-$(date +%Y-%m-%d)}"
BOARD_ID=2
CARLOS_ACCOUNT_ID="712020:3f7c6fe9-65f2-4059-8be9-2afe874e32f2"
SUMMARY="🤖 Weekly security audit: $TODAY"

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
  local label="com.carlos.jira-weekly-security-audit"
  if ! api GET "/rest/api/3/issue/$1?fields=description" | grep -q 'goal-loops-to-jira'; then return 0; fi
  log "retired: $1 was filed by goal-loops-to-jira; removing launchd job $label"
  rm -f "$HOME/Library/LaunchAgents/$label.plist"
  launchctl bootout "gui/$(id -u)/$label"
}

read -r -d '' DESCRIPTION <<'EOF' || true
Filed every Wednesday 9am by spark-agent-tools/jira-weekly-security-audit.sh (ENG-2948). Find the security holes in SparkPos and fix every one of them in this ticket's PR, this week.

Run the vendored Cloudflare skill in FULL AUDIT MODE on the SparkPos repo (develop at the time you start): Skill(security-audit), "standard" profile, output in its default directory ~/security-audit-skill/SparkPos/run-<N> (outside the repo, never committed). This ticket is the explicit request for the complete workflow, so do not stop to ask which mode or which directory. Earlier runs in that directory are the baseline: re-check their findings against the current code and give the code merged since the last run the closest look.

Also, in the same sweep: the Supabase security advisors for develop1 (Management API GET /v1/projects/<ref>/advisors/security; develop1 runs the same migrations as production, never query production), and npm audit for high and critical advisories in the root, admin-dashboard and portal.

Then look for the holes that are specific to how Spark is built, which no generic checklist knows about. At least: a restaurant reading or writing another restaurant's rows (restaurant_id scoping in SFCs, edge functions, admin-dashboard and portal API routes, and powersync/sync_rules.yaml); edge functions that trust a restaurant id, amount or price sent by the client; admin-dashboard and portal routes that skip the login (lib/middlewareRouting.ts in each app) and the pages where a token in the URL is the credential; the AGENT_KEY routes; webhooks (Finix, Uber Eats, Mailgun, Twilio) that do not check the signature; storage buckets that are public but hold private files; where the Supabase service-role key is reachable; secrets committed to git. Add anything else this codebase does that could let one person act as another.

A finding counts once it is confirmed: the skill's own validation, or your reproduction on develop1 or the rig with dummy data (never production, never a real customer). Every needs_validation lead from the skill gets that reproduction this week; it ends confirmed (and fixed) or rejected with the reason.

Fix every confirmed finding in THIS ticket's PR, critical first: the smallest change that closes it, plus a regression test that fails without the fix (vitest, a Maestro E2E, or a Cypress spec, whichever reaches it). Never defer a finding to next week's audit ticket, never list one as "accepted risk" on your own, and never weaken a check to make a test pass. If a fix needs a product decision only a person can make (a behavior change customers would notice), post the stop for that one finding and keep fixing the rest.

Deliverable: one PR (plus the paired SPARK_E2E PR when a Cypress spec is added). In the PR body, every confirmed finding is its own checkbox line, "- [ ] <severity> <finding id>: <title> / <fix> / <regression test>", ticked only once the fix is in and its test passed. The merge gate blocks on any unticked box, so the PR cannot merge with a confirmed finding left open. Below them, a table of every rejected lead (lead, why rejected) and the run's REPORT.md summary. Nothing confirmed this week = post the REPORT.md summary on the ticket and close it.
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
