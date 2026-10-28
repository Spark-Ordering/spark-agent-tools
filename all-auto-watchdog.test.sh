#!/bin/bash
# Self-check for all-auto-watchdog.sh against fixture transcripts + a fake slack-bot. Run: bash all-auto-watchdog.test.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
WATCHDOG="$HERE/all-auto-watchdog.sh"
FIXTURES="$(mktemp -d)"
export ALL_AUTO_WATCHDOG_LOG="$FIXTURES/watchdog.log"
export PROJECTS_GLOB="$FIXTURES/projects/*/*.jsonl"
export SLACK_BOT="$FIXTURES/fake-slack-bot.sh"
export NOW_EPOCH=1000000
fail() { echo "FAIL: $*"; exit 1; }

cat >"$SLACK_BOT" <<'EOF'
#!/bin/bash
echo "$*" >>"$(dirname "$0")/posts.log"
EOF
chmod +x "$SLACK_BOT"
mkdir -p "$FIXTURES/projects/-Users-carlos"

goal_line() { # goal_line ARGS -> one transcript line carrying a /goal command
  printf '{"type":"user","message":{"content":"<command-name>/goal</command-name><command-message>goal</command-message><command-args>%s</command-args>"}}\n' "$1"
}
invoke_line() { # invoke_line CMD -> a real user message invoking that slash command
  printf '{"type":"user","message":{"content":"<command-name>/%s</command-name><command-message>%s</command-message>"}}\n' "$1" "$1"
}
tool_result_line() { # a tool result that merely mentions /all-auto (array content) must not count
  printf '{"type":"user","message":{"content":[{"type":"tool_result","content":"<command-name>/all-auto</command-name>"}]}}\n'
}
iso() { TZ=UTC date -r "$1" +%Y-%m-%dT%H:%M:%S.000Z; }
text_line() { # text_line EPOCH -> an assistant message with text at that time
  printf '{"type":"assistant","timestamp":"%s","message":{"content":[{"type":"text","text":"No change"}]}}\n' "$(iso "$1")"
}
tool_line() { # tool_line EPOCH -> an assistant tool_use record (no text) at that time
  printf '{"type":"assistant","timestamp":"%s","message":{"content":[{"type":"tool_use","name":"Bash"}]}}\n' "$(iso "$1")"
}
transcript() { # transcript NAME MTIME_EPOCH LINE...   (mtime is set but must be ignored)
  local name="$1" mtime="$2"; shift 2
  local file="$FIXTURES/projects/-Users-carlos/$name.jsonl"
  printf '%s\n' "$@" >"$file"
  touch -t "$(date -r "$mtime" +%Y%m%d%H%M.%S)" "$file"
}
run() { : >"$FIXTURES/posts.log"; bash "$WATCHDOG" >/dev/null; }
posts() { cat "$FIXTURES/posts.log"; }
reset() { rm -f "$FIXTURES/projects/-Users-carlos/"*.jsonl; }

# 1. No transcript at all -> alert "not running".
reset; run
grep -q "not running" "$(dirname "$SLACK_BOT")/posts.log" || fail "no session should alert"
grep -q "<@U0516TWQHGD>" "$(dirname "$SLACK_BOT")/posts.log" || fail "alert must tag Carlos"

# 2. Fresh /all-auto invocation, assistant text 10 min ago -> no alert.
reset; transcript fresh $((NOW_EPOCH - 600)) "$(invoke_line all-auto)" "$(text_line $((NOW_EPOCH - 600)))"; run
[ -z "$(posts)" ] || fail "fresh session must not alert: $(posts)"

# 3. Last assistant text 2h old -> alert "stalled".
reset; transcript stale $((NOW_EPOCH - 7200)) "$(invoke_line all-auto)" "$(text_line $((NOW_EPOCH - 7200)))"; run
posts | grep -q "stalled" || fail "stale session should alert"
posts | grep -q "120 min ago" || fail "alert should say how long ago: $(posts)"

# 4. A /goal naming /all-auto, or a tool result quoting it, is not an invocation -> alert.
reset; transcript goalonly $((NOW_EPOCH - 60)) "$(goal_line 'run /all-auto continuously')" "$(tool_result_line)" "$(text_line $((NOW_EPOCH - 60)))"; run
posts | grep -q "not running" || fail "goal/tool-result mentions must not count"

# 5. Another command is ignored; a fresh /all-auto session elsewhere keeps it quiet.
reset; transcript other $((NOW_EPOCH - 60)) "$(invoke_line claudeqs)" "$(text_line $((NOW_EPOCH - 60)))"; run
posts | grep -q "not running" || fail "non-all-auto session must not count"
transcript fresh2 $((NOW_EPOCH - 120)) "$(invoke_line all-auto)" "$(text_line $((NOW_EPOCH - 120)))"; run
[ -z "$(posts)" ] || fail "fresh /all-auto beside another session must not alert"

# 6. Newest session wins: one stale, one fresh -> quiet.
reset; transcript stale $((NOW_EPOCH - 7200)) "$(invoke_line all-auto)" "$(text_line $((NOW_EPOCH - 7200)))"; transcript fresh $((NOW_EPOCH - 60)) "$(invoke_line all-auto)" "$(text_line $((NOW_EPOCH - 60)))"; run
[ -z "$(posts)" ] || fail "newest fresh session must win"

# 7. DRY_RUN never posts.
reset; DRY_RUN=1 run
[ -z "$(posts)" ] || fail "DRY_RUN must not post"

# 8. THE 2026-09-09 STALL: file mtime fresh, last assistant text 2h old -> alert. mtime is ignored.
reset; transcript touched $((NOW_EPOCH - 60)) "$(invoke_line all-auto)" "$(text_line $((NOW_EPOCH - 7200)))"; run
posts | grep -q "stalled" || fail "fresh mtime must not hide a stale session"
posts | grep -q "120 min ago" || fail "age must come from the message timestamp: $(posts)"

# 9. Tool-use-only records, user text, empty text blocks after the last real message do not count.
user_line() { printf '{"type":"user","timestamp":"%s","message":{"content":"kick: re-query"}}\n' "$(iso "$1")"; }
empty_line() { printf '{"type":"assistant","timestamp":"%s","message":{"content":[{"type":"text","text":""}]}}\n' "$(iso "$1")"; }
reset; transcript noise $((NOW_EPOCH - 30)) "$(invoke_line all-auto)" "$(text_line $((NOW_EPOCH - 7200)))" "$(tool_line $((NOW_EPOCH - 120)))" "$(user_line $((NOW_EPOCH - 90)))" "$(empty_line $((NOW_EPOCH - 60)))"; run
posts | grep -q "120 min ago" || fail "tool/user/empty records must not count as activity: $(posts)"

# 10. /all-auto invoked but no assistant text ever -> alert stalled.
reset; transcript silent $((NOW_EPOCH - 60)) "$(invoke_line all-auto)" "$(tool_line $((NOW_EPOCH - 60)))"; run
posts | grep -q "stalled" || fail "a session with no text message must alert"

echo "all-auto-watchdog.test.sh: all checks passed"
