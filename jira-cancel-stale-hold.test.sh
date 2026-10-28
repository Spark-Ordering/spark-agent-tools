#!/bin/bash
# Self-check for jira-cancel-stale-hold.sh against a fake curl + fake gh. Run: bash jira-cancel-stale-hold.test.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/jira-cancel-stale-hold.sh"
export FIXTURES; FIXTURES="$(mktemp -d)"
export JIRA_CANCEL_LOG="$FIXTURES/cancel.log"
export HOME_ENV="$FIXTURES/home"; mkdir -p "$HOME_ENV/.config"
printf 'export JIRA_SITE_URL=jira.test\nexport JIRA_EMAIL=me@test\nexport JIRA_API_TOKEN=t\n' >"$HOME_ENV/.config/jira-sweep.env"
export PATH="$HERE/jira-cancel-stale-hold.test:$PATH"
chmod +x "$HERE/jira-cancel-stale-hold.test/curl" "$HERE/jira-cancel-stale-hold.test/gh"
fail() { echo "FAIL: $*"; exit 1; }

# --- fixtures: 2 pages; ENG-1 has PRs in two repos, ENG-2 none, ENG-3 has no Cancelled transition, ENG-4 on page 2
jq -cn '{issues:[{key:"ENG-1"},{key:"ENG-2"},{key:"ENG-3"}], nextPageToken:"TOK2", isLast:false}' >"$FIXTURES/search-page1.json"
jq -cn '{issues:[{key:"ENG-4"}], isLast:true}' >"$FIXTURES/search-page2.json"
echo '{"transitions":[{"id":"5","to":{"name":"Hold"}},{"id":"20","to":{"name":"Cancelled"}}]}' >"$FIXTURES/transitions-default.json"
echo '{"transitions":[{"id":"5","to":{"name":"Hold"}}]}' >"$FIXTURES/transitions-ENG-3.json"
echo "https://github.com/Spark-Ordering/SparkPos/pull/10" >"$FIXTURES/prs-SparkPos-ENG-1.txt"
echo "https://github.com/Spark-Ordering/SPARK_E2E/pull/3" >"$FIXTURES/prs-SPARK_E2E-ENG-1.txt"
echo "https://github.com/Spark-Ordering/RestWeb/pull/7" >"$FIXTURES/prs-RestWeb-ENG-4.txt"

run() { HOME="$HOME_ENV" bash "$SCRIPT"; }

# --- dry run touches nothing
out="$(DRY_RUN=1 run)"
grep -q "done: checked=4 moved=3 prs_closed=3 stale_days=7 dry_run=1" <<<"$out" || fail "dry summary: $out"
[ ! -f "$FIXTURES/transitions.log" ] || fail "dry run transitioned"
[ ! -f "$FIXTURES/comments.log" ] || fail "dry run commented"
[ ! -f "$FIXTURES/closed.log" ] || fail "dry run closed PRs"
echo "ok: dry run"

# --- live run
rm -f "$FIXTURES/calls.log" "$FIXTURES/gh.log"
out="$(run)"
grep -q "done: checked=4 moved=3 prs_closed=3 stale_days=7 dry_run=0" <<<"$out" || fail "live summary: $out"
[ "$(grep -c . "$FIXTURES/transitions.log")" = "3" ] || fail "expected 3 transitions"
grep -q '^ENG-1 {"transition":{"id":"20"}}' "$FIXTURES/transitions.log" || fail "ENG-1 not moved via id 20"
grep -q "^ENG-3 " "$FIXTURES/transitions.log" && fail "ENG-3 has no Cancelled transition but was moved"
grep -q "ERROR ENG-3: no transition to 'Cancelled'" <<<"$out" || fail "ENG-3 error not logged"
[ "$(grep -c . "$FIXTURES/comments.log")" = "3" ] || fail "expected 3 comments"
grep -q 'ENG-2 .*Cancelled for now, feel free to move back to To Do and remove the paused label if you would like to resume it\.' "$FIXTURES/comments.log" || fail "comment text wrong"
grep -q "^ENG-3 " "$FIXTURES/comments.log" && fail "ENG-3 commented despite failed transition"
[ "$(grep -c . "$FIXTURES/closed.log")" = "3" ] || fail "expected 3 PRs closed: $(cat "$FIXTURES/closed.log")"
grep -q "SparkPos/pull/10" "$FIXTURES/closed.log" || fail "SparkPos PR not closed"
grep -q "SPARK_E2E/pull/3" "$FIXTURES/closed.log" || fail "SPARK_E2E PR not closed"
grep -q "RestWeb/pull/7" "$FIXTURES/closed.log" || fail "page-2 ticket's PR not closed"
grep -q -- "--delete-branch" "$FIXTURES/gh.log" && fail "branch deletion attempted"
grep -q -- "--state open" "$FIXTURES/gh.log" || fail "pr list must filter open PRs"
echo "ok: live run"

# --- STALE_DAYS reaches the JQL
rm -f "$FIXTURES/calls.log"
STALE_DAYS=10 DRY_RUN=1 run >/dev/null
grep -q "AFTER%20-10d" "$FIXTURES/calls.log" || fail "STALE_DAYS not in JQL"
echo "ok: stale days"
echo "ALL OK"
