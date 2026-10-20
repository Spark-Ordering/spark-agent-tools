#!/bin/bash
# aws-2fa.sh "<why>" -- <command...>
# Runs ONE command with the Stage-only `sparkpos-ops` AWS profile (permission set StageOps,
# ENG-2927). Each run needs Carlos's approval: an IAM Identity Center device-code login he
# approves on his phone with his passkey (same mechanism as the prod build's release secrets).
# The code is DM'd to him with the reason and the exact command; the session is logged out
# when the command ends, so one approval = one command. Setup: aws-ops/setup.sh (once).
# Exit codes: the command's own, or 2 usage, 3 profile not set up, 4 login not approved/expired.
set -euo pipefail

PROFILE="${AWS_2FA_PROFILE:-sparkpos-ops}"
APPROVER="${AWS_2FA_APPROVER:-U0516TWQHGD}" # Carlos's Slack id; the bot DMs him
SLACK_BOT="${SLACK_BOT:-$HOME/.claude/skills/claudeqs/slack-bot.sh}"
LOG_DIR="${AWS_2FA_LOG_DIR:-$HOME/.aws-2fa}"

why="${1:-}"
[ -n "$why" ] && [ "${2:-}" = "--" ] && [ $# -ge 3 ] || {
  echo 'usage: aws-2fa.sh "<why>" -- <command...>' >&2
  exit 2
}
shift 2

if [ "$(aws configure get sso_role_name --profile "$PROFILE" 2>/dev/null || true)" != "StageOps" ]; then
  echo "profile $PROFILE is not set up: Carlos runs aws-ops/setup.sh once (docs/aws-2fa.md)" >&2
  exit 3
fi

mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"
run_id="$(date +%Y%m%d-%H%M%S)-$$"
login_log="$LOG_DIR/$run_id.login.log"
command_text="$(printf '%q ' "$@")"
printf '%s\t%s\t%s\n' "$(date '+%F %T')" "$why" "$command_text" >>"$LOG_DIR/history.tsv"

login_pid=""
cleanup() {
  [ -n "$login_pid" ] && kill "$login_pid" 2>/dev/null || true
  aws sso logout --profile "$PROFILE" >/dev/null 2>&1 || true
}
trap cleanup EXIT

aws sso login --profile "$PROFILE" --use-device-code --no-browser >"$login_log" 2>&1 &
login_pid=$!

# The CLI prints the approve URL (with ?user_code=) before it starts waiting.
url=""
for _ in $(seq 1 60); do
  url="$(grep -oE 'https://[^ ]+user_code=[A-Z0-9-]+' "$login_log" | head -1 || true)"
  [ -n "$url" ] && break
  kill -0 "$login_pid" 2>/dev/null || break
  sleep 0.5
done
if [ -z "$url" ]; then
  echo "aws sso login printed no approve URL; see $login_log" >&2
  exit 4
fi
code="${url##*user_code=}"
expires="$(date -v+10M '+%H:%M' 2>/dev/null || date -d '+10 min' '+%H:%M')"

text="🔐 AWS approval needed (Stage only, one command)
Why: $why
Command: \`$command_text\`
Code: $code (expires ~$expires)
$url
Approve with your passkey only if this is the command you expect."
bash "$SLACK_BOT" post "$APPROVER" "$text" >/dev/null
echo "Waiting for approval of code $code (DM'd to $APPROVER, expires ~$expires)" >&2

login_rc=0
wait "$login_pid" || login_rc=$?
login_pid=""
if [ "$login_rc" -ne 0 ]; then
  echo "login not approved (exit $login_rc); see $login_log" >&2
  exit 4
fi

cmd_rc=0
AWS_PROFILE="$PROFILE" AWS_REGION="${AWS_REGION:-us-east-2}" "$@" || cmd_rc=$?
printf '%s\t%s\texit %s\n' "$(date '+%F %T')" "$command_text" "$cmd_rc" >>"$LOG_DIR/history.tsv"
exit "$cmd_rc"
