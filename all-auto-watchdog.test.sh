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
transcript() { # transcript NAME MTIME_EPOCH LINE...
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

# 2. Fresh /all-auto goal (10 min old) -> no alert.
reset; transcript fresh $((NOW_EPOCH - 600)) "$(goal_line 'run /all-auto continuously')"; run
[ -z "$(posts)" ] || fail "fresh session must not alert: $(posts)"

# 3. Stale /all-auto goal (2h old) -> alert "stalled".
reset; transcript stale $((NOW_EPOCH - 7200)) "$(goal_line 'run /all-auto continuously')"; run
grep -q "stalled" "$(posts)" 2>/dev/null || posts | grep -q "stalled" || fail "stale session should alert"
posts | grep -q "120 min ago" || fail "alert should say how long ago: $(posts)"

# 4. Goal later cleared -> treated as no session -> alert.
reset; transcript cleared $((NOW_EPOCH - 60)) "$(goal_line 'run /all-auto continuously')" "$(goal_line 'clear')"; run
posts | grep -q "not running" || fail "cleared goal should alert"

# 5. A goal that is not /all-auto is ignored; a fresh /all-auto one elsewhere keeps it quiet.
reset; transcript other $((NOW_EPOCH - 60)) "$(goal_line 'finish the release notes')"; run
posts | grep -q "not running" || fail "non-all-auto goal must not count"
transcript fresh2 $((NOW_EPOCH - 120)) "$(goal_line 'NEVER ACHIEVED. run /all-auto continuously')"; run
[ -z "$(posts)" ] || fail "fresh /all-auto beside another goal must not alert"

# 6. Newest session wins: one stale, one fresh -> quiet.
reset; transcript stale $((NOW_EPOCH - 7200)) "$(goal_line 'run /all-auto')"; transcript fresh $((NOW_EPOCH - 60)) "$(goal_line 'run /all-auto')"; run
[ -z "$(posts)" ] || fail "newest fresh session must win"

# 7. DRY_RUN never posts.
reset; DRY_RUN=1 run
[ -z "$(posts)" ] || fail "DRY_RUN must not post"

echo "all-auto-watchdog.test.sh: all checks passed"
