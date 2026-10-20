#!/bin/bash
# Fake slack-bot.sh: records command, channel and the full text.
printf '%s\t%s\t%s\n---\n' "$1" "$2" "$3" >>"$FIXTURES/slack.log"
echo '{"ok":true,"ts":"1792500000.000100"}'
