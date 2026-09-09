#!/bin/bash
# Self-check for jira-claude-label.sh against a fake curl. Run: bash jira-claude-label.test.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/jira-claude-label.sh"
export FIXTURES; FIXTURES="$(mktemp -d)"
export JIRA_CLAUDE_LABEL_LOG="$FIXTURES/label.log"
export PATH="$HERE/jira-claude-label.test:$PATH"
fail() { echo "FAIL: $*"; exit 1; }

# ENG-1 Claude only -> label; ENG-2 has both -> skip; ENG-3 CLAUDE -> label; ENG-4 page 2 -> label.
jq -cn '{issues:[{key:"ENG-1",fields:{labels:["Claude"]}},{key:"ENG-2",fields:{labels:["Claude","claude"]}},
                 {key:"ENG-3",fields:{labels:["CLAUDE","2.07.X"]}}], nextPageToken:"TOK2"}' >"$FIXTURES/page1.json"
jq -cn '{issues:[{key:"ENG-4",fields:{labels:["Claude"]}}]}' >"$FIXTURES/page2.json"

out="$(DRY_RUN=1 bash "$SCRIPT")"
[ ! -f "$FIXTURES/labels.log" ] || fail "dry run added labels"
grep -q "done: checked=3 labelled=3 dry_run=1" <<<"$out" || fail "dry run counts: $out"
echo "ok: dry run"

out="$(bash "$SCRIPT")"
grep -q "done: checked=3 labelled=3 dry_run=0" <<<"$out" || fail "real run counts: $out"
labelled="$(cut -d' ' -f1 "$FIXTURES/labels.log" | sort -V | tr '\n' ' ')"
[ "$labelled" = "ENG-1 ENG-3 ENG-4 " ] || fail "labelled set wrong: $labelled"
grep -q '^ENG-1 {"update":{"labels":\[{"add":"claude"}\]}}$' "$FIXTURES/labels.log" || fail "ENG-1 body wrong"
echo "ok: pagination + case filter + PUT body"

rm -rf "$FIXTURES"
echo "ALL OK"
