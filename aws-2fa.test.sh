#!/bin/bash
# Self-check for aws-2fa.sh against a fake aws CLI + slack-bot. Run: bash aws-2fa.test.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/aws-2fa.sh"
export FIXTURES; FIXTURES="$(mktemp -d)"
export PATH="$HERE/aws-2fa.test:$PATH" SLACK_BOT="$HERE/aws-2fa.test/slack-bot.sh" AWS_2FA_LOG_DIR="$FIXTURES/logs"
fail() { echo "FAIL: $*"; exit 1; }
reset() { rm -f "$FIXTURES/aws.log" "$FIXTURES/slack.log"; }

rc=0; bash "$SCRIPT" "no command" 2>/dev/null || rc=$?
[ "$rc" = 2 ] || fail "usage exit $rc"
echo "ok: usage"

reset; rc=0; FAKE_ROLE=ReleaseSecrets bash "$SCRIPT" "why" -- aws s3 ls 2>/dev/null || rc=$?
[ "$rc" = 3 ] || fail "wrong profile exit $rc"
[ ! -f "$FIXTURES/slack.log" ] || fail "DM sent without a set-up profile"
grep -q "sso login" "$FIXTURES/aws.log" && fail "logged in without a set-up profile"
echo "ok: profile must be the StageOps role"

reset; rc=0
bash "$SCRIPT" "check Stage2 health" -- aws elasticbeanstalk describe-environments --environment-names Stage2 2>/dev/null || rc=$?
[ "$rc" = 0 ] || fail "happy path exit $rc"
dm="$(cat "$FIXTURES/slack.log")"
grep -q "^post	U0516TWQHGD	" <<<"$dm" || fail "not a DM to Carlos: $dm"
grep -qF "Why: check Stage2 health" <<<"$dm" || fail "why missing: $dm"
grep -qF "aws elasticbeanstalk describe-environments --environment-names Stage2" <<<"$dm" || fail "command missing: $dm"
grep -qF "Code: ABCD-EFGH" <<<"$dm" || fail "code missing: $dm"
grep -qF "https://d-9a67.awsapps.com/start/#/device?user_code=ABCD-EFGH" <<<"$dm" || fail "url missing: $dm"
grep -qF "aws elasticbeanstalk describe-environments --environment-names Stage2 | AWS_PROFILE=sparkpos-ops" "$FIXTURES/aws.log" \
  || fail "command did not run with the profile: $(cat "$FIXTURES/aws.log")"
[ "$(grep -n 'sso login' "$FIXTURES/aws.log" | cut -d: -f1)" -lt "$(grep -n 'describe-environments' "$FIXTURES/aws.log" | cut -d: -f1)" ] \
  || fail "command ran before the login"
tail -1 "$FIXTURES/aws.log" | grep -q "sso logout" || fail "no logout after the command"
echo "ok: DM carries why + command + code + URL; command runs with sparkpos-ops after approval; logout last"

reset; rc=0; FAKE_CMD_RC=7 bash "$SCRIPT" "restart" -- aws elasticbeanstalk restart-app-server 2>/dev/null || rc=$?
[ "$rc" = 7 ] || fail "command exit not passed through: $rc"
tail -1 "$FIXTURES/aws.log" | grep -q "sso logout" || fail "no logout after a failing command"
echo "ok: the command's exit code is passed through and the session is still logged out"

reset; rc=0; FAKE_LOGIN_RC=255 bash "$SCRIPT" "restart" -- aws elasticbeanstalk restart-app-server 2>/dev/null || rc=$?
[ "$rc" = 4 ] || fail "expired login exit $rc"
grep -q "restart-app-server" "$FIXTURES/aws.log" && fail "command ran without approval"
tail -1 "$FIXTURES/aws.log" | grep -q "sso logout" || fail "no logout after an expired login"
echo "ok: unapproved/expired login exits 4 and never runs the command"

[ "$(wc -l <"$FIXTURES/logs/history.tsv" | tr -d ' ')" = 5 ] || fail "history: $(cat "$FIXTURES/logs/history.tsv")"
echo "ok: history.tsv records each request and each result"

rm -rf "$FIXTURES"
echo "ALL OK"
