#!/bin/bash
# Self-check for jira-weekly-security-audit.sh against the fake curl. Run: bash jira-weekly-security-audit.test.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/jira-weekly-security-audit.sh"
export FIXTURES; FIXTURES="$(mktemp -d)"
export JIRA_WEEKLY_SECURITY_AUDIT_LOG="$FIXTURES/job.log"
export JIRA_WEEKLY_SECURITY_AUDIT_STATE="$FIXTURES/state"
export PATH="$HERE/jira-develop-e2e-ticket.test:$PATH"
fail() { echo "FAIL: $*"; exit 1; }
echo '{"issues":[]}' >"$FIXTURES/search.json"

out="$(TODAY=2026-10-28 DRY_RUN=1 bash "$SCRIPT")"
grep -q "DRY_RUN would create" <<<"$out" || fail "dry run did not reach create: $out"
[ ! -f "$FIXTURES/created.log" ] || fail "dry run created a ticket"
echo "ok: dry run creates nothing"

out="$(TODAY=2026-10-28 bash "$SCRIPT")"
grep -q "created ENG-9999" <<<"$out" || fail "first run did not create: $out"
[ "$(jq -r .fields.summary "$FIXTURES/created.log")" = "🤖 Weekly security audit: 2026-10-28" ] || fail "summary wrong"
[ "$(jq -c '[.fields.labels, .fields.customfield_10020]' "$FIXTURES/created.log")" = '[["claude"],4242]' ] || fail "labels/sprint wrong"
jq -r '.fields.description.content[].content[].text' "$FIXTURES/created.log" | grep -q "Skill(security-audit)" || fail "description lost the skill"
echo "ok: files the dated ticket with the claude label in the active sprint"

out="$(TODAY=2026-10-28 bash "$SCRIPT")"
grep -q "exists: marker" <<<"$out" || fail "same-date rerun should skip: $out"
mv "$FIXTURES/state" "$FIXTURES/state.lost"
jq -cn '{issues:[{key:"ENG-7",fields:{summary:"🤖 Weekly security audit: 2026-10-28"}}]}' >"$FIXTURES/search.json"
out="$(TODAY=2026-10-28 bash "$SCRIPT")"
grep -q "exists: ENG-7" <<<"$out" || fail "existing Jira ticket not detected: $out"
[ "$(jq -s length "$FIXTURES/created.log")" = "1" ] || fail "filed a duplicate"
echo "ok: same date skips (marker, then Jira)"

echo "ALL OK"
