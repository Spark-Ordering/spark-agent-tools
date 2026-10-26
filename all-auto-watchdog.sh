#!/bin/bash
# Hourly (launchd com.carlos.all-auto-watchdog): if the newest /all-auto session's last assistant
# text is over an hour old (or none exists), tag Carlos in #engineering.
# Env: DRY_RUN=1, PROJECTS_GLOB, NOW_EPOCH, SLACK_BOT, STALE_SECONDS. ENG-2648.
set -euo pipefail

PROJECTS_GLOB="${PROJECTS_GLOB:-$HOME/.claude/projects/*/*.jsonl}"
SLACK_BOT="${SLACK_BOT:-$HOME/.claude/skills/claudeqs/slack-bot.sh}"
ENGINEERING_CHANNEL="${ENGINEERING_CHANNEL:-C0516TVR79B}"
CARLOS_ID="${CARLOS_ID:-U0516TWQHGD}"
STALE_SECONDS="${STALE_SECONDS:-3600}"
LOG="${ALL_AUTO_WATCHDOG_LOG:-$HOME/Library/Logs/all-auto-watchdog.log}"
DRY_RUN="${DRY_RUN:-0}"

log() { echo "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

now_epoch() {
  if [ -n "${NOW_EPOCH:-}" ]; then echo "$NOW_EPOCH"; else date +%s; fi
}

# True when a real user message (string content, not a tool result) invoked /all-auto.
# /all-auto sessions never set /goal (start-loops and handoffs pass "/all-auto" as the prompt).
invoked_all_auto() {
  local file="$1"
  grep -a 'command-name>/all-auto</command-name>' "$file" \
    | jq -e -s 'any(.[]; .type == "user" and (.message.content | type == "string")
        and (.message.content | test("<command-name>/all-auto</command-name>")))' >/dev/null 2>&1
}

# Epoch of the last assistant message carrying non-empty text; 0 when none. Never file mtime:
# the harness rewrites the transcript every few minutes with no new messages (2026-09-09 stall).
last_text_epoch() {
  local file="$1" ts
  ts="$(grep -a '"type":"assistant"' "$file" \
    | jq -r 'select(.message.content | type == "array")
        | select(any(.message.content[]; .type == "text" and (.text | length) > 0))
        | .timestamp // empty' 2>/dev/null \
    | tail -1)"
  if [ -z "$ts" ]; then echo 0; return; fi
  TZ=UTC date -j -f '%Y-%m-%dT%H:%M:%S' "${ts%%.*}" +%s
}

# Prints "<last-text-epoch>\t<file>" for every transcript touched in the last 3 days that ran /all-auto.
active_all_auto_sessions() {
  local file cutoff
  cutoff=$(( $(now_epoch) - 259200 ))
  for file in $PROJECTS_GLOB; do
    [ -f "$file" ] || continue
    [ "$(stat -f '%m' "$file")" -gt "$cutoff" ] || continue
    invoked_all_auto "$file" || continue
    printf '%s\t%s\n' "$(last_text_epoch "$file")" "$file"
  done
}

alert() {
  local text="$1"
  log "ALERT: $text"
  if [ "$DRY_RUN" = "1" ]; then return; fi
  "$SLACK_BOT" post "$ENGINEERING_CHANNEL" "<@$CARLOS_ID> 🚨 /all-auto loop check: $text" >/dev/null
}

main() {
  local newest
  newest="$(active_all_auto_sessions | sort -rn | head -1)"
  if [ -z "$newest" ]; then
    alert "no Claude session has run /all-auto in the last 3 days — the loop is not running. Fix it now."
    return
  fi
  local last file age
  last="${newest%%	*}"
  file="${newest#*	}"
  age=$(( $(now_epoch) - last ))
  if [ "$age" -gt "$STALE_SECONDS" ]; then
    alert "the /all-auto session $(basename "$file" .jsonl) last posted a message $((age / 60)) min ago — the loop has stalled. Fix it now."
    return
  fi
  log "ok: $(basename "$file" .jsonl) active, last message $((age / 60)) min ago"
}

main
