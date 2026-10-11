#!/bin/bash
# Self-check for jira-develop-e2e-ticket.sh against a fake curl. Run: bash jira-develop-e2e-ticket.test.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/jira-develop-e2e-ticket.sh"
export FIXTURES; FIXTURES="$(mktemp -d)"
export JIRA_DEVELOP_E2E_TICKET_LOG="$FIXTURES/job.log"
export JIRA_DEVELOP_E2E_TICKET_STATE="$FIXTURES/state"
export PATH="$HERE/jira-develop-e2e-ticket.test:$PATH"
fail() { echo "FAIL: $*"; exit 1; }
created() { jq -s length "$FIXTURES/created.log"; }
echo '{"issues":[]}' >"$FIXTURES/search.json"

out="$(TODAY=2026-10-11 DRY_RUN=1 bash "$SCRIPT")"
grep -q "DRY_RUN would create" <<<"$out" || fail "dry run did not reach create: $out"
[ ! -f "$FIXTURES/created.log" ] || fail "dry run created a ticket"
[ ! -f "$FIXTURES/state" ] || fail "dry run wrote the state file"
echo "ok: dry run"

out="$(TODAY=2026-10-11 bash "$SCRIPT")"
grep -q "created ENG-9999" <<<"$out" || fail "first run did not create: $out"
summary="$(jq -r .fields.summary "$FIXTURES/created.log")"
[ "$summary" = "🤖 Run All E2Es on Develop and Fix - 10/11" ] || fail "summary wrong: $summary"
[ "$(jq -c '[.fields.labels, .fields.customfield_10020]' "$FIXTURES/created.log")" = '[["claude"],4242]' ] || fail "labels/sprint wrong"
echo "ok: first run files 'Run All E2Es on Develop and Fix - 10/11' with the claude label in the active sprint"

for day in 2026-10-11 2026-10-12; do
  out="$(TODAY=$day bash "$SCRIPT")"
  grep -q "skip: last filed" <<<"$out" || fail "$day should skip: $out"
done
[ "$(created)" = "1" ] || fail "a ticket was filed inside the 2-day window"
echo "ok: same day and next day skip"

out="$(TODAY=2026-10-13 bash "$SCRIPT")"
grep -q "created ENG-9999" <<<"$out" || fail "day 2 did not create: $out"
[ "$(created)" = "2" ] || fail "expected 2 tickets after day 2"
echo "ok: files again 2 days later"

# 2026-11-01 is the DST change in the US: the day count must still be whole days.
out="$(TODAY=2026-11-01 bash "$SCRIPT")"; grep -q "created" <<<"$out" || fail "11-01 did not create: $out"
out="$(TODAY=2026-11-02 bash "$SCRIPT")"; grep -q "skip: last filed 1 day" <<<"$out" || fail "11-02 (DST) should be 1 day: $out"
out="$(TODAY=2026-11-03 bash "$SCRIPT")"; grep -q "created" <<<"$out" || fail "11-03 did not create: $out"
echo "ok: day count across the DST change"

# State file lost but Jira already has this round's ticket: skip on the exact-summary match.
rm "$FIXTURES/state"
jq -cn '{issues:[{key:"ENG-7",fields:{summary:"🤖 Run All E2Es on Develop and Fix - 11/05"}}]}' >"$FIXTURES/search.json"
out="$(TODAY=2026-11-05 bash "$SCRIPT")"
grep -q "exists: ENG-7" <<<"$out" || fail "existing ticket not detected: $out"
[ "$(created)" = "4" ] || fail "created a duplicate of an existing ticket"
echo "ok: existing ticket with the same name skips"

rm -rf "$FIXTURES"
echo "ALL OK"
