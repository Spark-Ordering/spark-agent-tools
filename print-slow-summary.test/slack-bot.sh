#!/bin/bash
# Fake slack-bot.sh: records one line per call (command, channel, ts-or-text), answers like Slack.
printf '%s\t%s\t%s\n' "$1" "$2" "$(printf '%s' "$3" | head -1)" >>"$FIXTURES/slack.log"
echo '{"ok":true,"ts":"1791300000.000100"}'
