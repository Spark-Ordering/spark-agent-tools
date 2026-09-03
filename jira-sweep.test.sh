#!/bin/bash
# Self-check for jira-sweep.sh against a fake curl. Run: bash jira-sweep.test.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SWEEP="$HERE/jira-sweep.sh"
export FIXTURES; FIXTURES="$(mktemp -d)"
export JIRA_SWEEP_LOG="$FIXTURES/sweep.log"
export PATH="$HERE/jira-sweep.test:$PATH"
fail() { echo "FAIL: $*"; exit 1; }

# --- fixtures ---------------------------------------------------------------
# ENG-2 carries the "claude" label; everything else is unlabelled.
keys_json() { jq -cn --argjson a "$1" --argjson b "$2" '[range($a; $b + 1) | {key: ("ENG-" + tostring), fields: {labels: (if . == 2 then ["claude"] else [] end)}}]'; }
jq -cn --argjson issues "$(keys_json 1 100)" '{issues: $issues, nextPageToken: "TOK2", isLast: false}' >"$FIXTURES/search-page1.json"
jq -cn --argjson issues "$(keys_json 101 120)" '{issues: $issues, isLast: true}' >"$FIXTURES/search-page2.json"

# hist AUTHOR FIELD -> one changelog history entry
hist() { jq -cn --arg a "$1" --arg f "$2" '{author: {accountId: $a}, items: [{field: $f}]}'; }
changelog() { # changelog ISLAST TOTAL entry... -> changelog page json
  local islast="$1" total="$2"; shift 2
  printf '%s\n' "$@" | jq -cs --argjson l "$islast" --argjson t "$total" '{isLast: $l, total: $t, values: .}'
}
changelog true 2 "$(hist ME status)" "$(hist TRENT status)"        >"$FIXTURES/changelog-default.json"
changelog true 2 "$(hist TRENT status)" "$(hist ME status)"        >"$FIXTURES/changelog-ENG-1.json"    # mine -> move
changelog true 2 "$(hist ME status)" "$(hist TRENT status)"        >"$FIXTURES/changelog-ENG-2.json"    # Trent re-moved -> keep
changelog true 3 "$(hist ME status)" "$(hist TRENT assignee)"      >"$FIXTURES/changelog-ENG-3.json"    # non-status edit after -> move
changelog true 1 "$(hist ME status)"                               >"$FIXTURES/changelog-ENG-120.json"  # page 2 -> move
changelog false 150 "$(hist ME status)"                            >"$FIXTURES/changelog-ENG-50.json"   # long log, last page wins
changelog true 150 "$(hist TRENT status)"                          >"$FIXTURES/changelog-ENG-50-last.json"
changelog false 150 "$(hist TRENT status)"                         >"$FIXTURES/changelog-ENG-51.json"
changelog true 150 "$(hist ME status)"                             >"$FIXTURES/changelog-ENG-51-last.json"
echo '{"transitions":[{"id":"31","to":{"name":"Done"}},{"id":"4","to":{"name":"Pending Release"}}]}' >"$FIXTURES/transitions-default.json"

# ENG-2510 labelling: ENG-201 needs the label, ENG-202 already has it, ENG-203 on page 2.
# ENG-2562: ENG-204 has a stale 2.06.X (add + drop), ENG-205 has current + two stale (drop only),
# ENG-206 carries a newer 2.08.X than version.json (kept as-is, untouched).
echo '{"version":"2.07.02","versionCode":20702}' >"$FIXTURES/version.json"
export VERSION_JSON="$FIXTURES/version.json"
jq -cn '{issues: [{key:"ENG-201",fields:{labels:["claude"]}},{key:"ENG-202",fields:{labels:["claude","2.07.X"]}},
                  {key:"ENG-204",fields:{labels:["claude","2.06.X"]}},{key:"ENG-205",fields:{labels:["2.05.X","claude","2.07.X","2.06.X"]}},
                  {key:"ENG-206",fields:{labels:["claude","2.08.X"]}}], nextPageToken:"TOKP2", isLast:false}' >"$FIXTURES/pending-page1.json"
jq -cn '{issues: [{key:"ENG-203",fields:{labels:["claude"]}}], isLast:true}' >"$FIXTURES/pending-page2.json"

# --- standup window ---------------------------------------------------------
expect_window() { # expect_window "YYYY-MM-DD HH:MM" skip|run
  local out; out="$(NOW_OVERRIDE="$1" DRY_RUN=1 bash "$SWEEP")"
  case "$2" in
    skip) grep -q "skip: standup window" <<<"$out" || fail "$1 should skip: $out" ;;
    run)  grep -q "done: checked=120" <<<"$out"    || fail "$1 should run: $out" ;;
  esac
}
expect_window "2026-08-24 18:59" run    # Mon just before
expect_window "2026-08-24 19:00" skip   # Mon 7pm
expect_window "2026-08-24 23:59" skip   # Mon last minute
expect_window "2026-08-25 00:00" run    # Tue midnight
expect_window "2026-08-24 08:00" run    # Mon morning
expect_window "2026-08-23 20:00" run    # Sun evening
expect_window "2026-08-31 21:00" skip   # next Mon
echo "ok: standup window"

# --- dry run posts nothing --------------------------------------------------
[ ! -f "$FIXTURES/posts.log" ] || fail "dry run posted transitions"
grep -q "DRY_RUN would move ENG-3" "$JIRA_SWEEP_LOG" || fail "dry run should report ENG-3"
[ ! -f "$FIXTURES/labels.log" ] || fail "dry run added labels"
grep -q "DRY_RUN would label ENG-201 2.07.X" "$JIRA_SWEEP_LOG" || fail "dry run should report ENG-201 label"
grep -q "DRY_RUN would label ENG-204 2.07.X (drop 2.06.X)" "$JIRA_SWEEP_LOG" || fail "dry run should report ENG-204 drop"
echo "ok: dry run"

# --- real run: missing transition logs and continues (ENG-2510 hardening) ---
echo '{"transitions":[{"id":"31","to":{"name":"Done"}}]}' >"$FIXTURES/transitions-ENG-1.json"
: >"$FIXTURES/calls.log"
out="$(NOW_OVERRIDE="2026-08-25 10:00" bash "$SWEEP")"
grep -q "ERROR ENG-1: no transition to 'Pending Release'" <<<"$out" || fail "ENG-1 should error on missing transition: $out"
grep -q "done: checked=120 moved=4 labelled=4 dry_run=0" <<<"$out" || fail "run should continue past ENG-1: $out"
echo "ok: missing transition logs and continues"

cp "$FIXTURES/transitions-default.json" "$FIXTURES/transitions-ENG-1.json"
: >"$FIXTURES/calls.log"; : >"$FIXTURES/posts.log"; : >"$FIXTURES/labels.log"
out="$(NOW_OVERRIDE="2026-08-25 10:00" bash "$SWEEP")"
grep -q "done: checked=120 moved=5 labelled=4 dry_run=0" <<<"$out" || fail "expected 5 moves + 4 labels: $out"
posted="$(cut -d' ' -f1 "$FIXTURES/posts.log" | sort -V | tr '\n' ' ')"
[ "$posted" = "ENG-1 ENG-2 ENG-3 ENG-51 ENG-120 " ] || fail "posted set wrong: $posted"
grep -q '"id":"4"' "$FIXTURES/posts.log" || fail "transition id should be 4"
# ENG-2 moves on its label alone, so its changelog is never fetched (119, not 120).
[ "$(grep -c "changelog?maxResults=100$" "$FIXTURES/calls.log")" = "119" ] || fail "should check 119 changelogs"
echo "ok: pagination, author + label filter, transitions"

# --- version labelling (ENG-2510 + ENG-2562): paginated, skips already-correct, one version label kept
labelled="$(cut -d' ' -f1 "$FIXTURES/labels.log" | sort -V | tr '\n' ' ')"
[ "$labelled" = "ENG-201 ENG-203 ENG-204 ENG-205 " ] || fail "labelled set wrong: $labelled"
grep -q '^ENG-201 {"update":{"labels":\[{"add":"2.07.X"}\]}}$' "$FIXTURES/labels.log" || fail "ENG-201 body wrong"
grep -q '^ENG-204 {"update":{"labels":\[{"add":"2.07.X"},{"remove":"2.06.X"}\]}}$' "$FIXTURES/labels.log" || fail "ENG-204 body wrong"
grep -q '^ENG-205 {"update":{"labels":\[{"remove":"2.05.X"},{"remove":"2.06.X"}\]}}$' "$FIXTURES/labels.log" || fail "ENG-205 body wrong"
grep -q "dropped 2.05.X,2.06.X" "$JIRA_SWEEP_LOG" || fail "ENG-205 drop should be logged"
echo "ok: version labelling"

rm -rf "$FIXTURES"
echo "ALL OK"
