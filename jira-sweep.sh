#!/bin/bash
# Moves ENG active-sprint tickets that *I* last moved to Done back to Pending Release.
# Skips Mon 19:00-23:59 (standup). Env: DRY_RUN=1, NOW_OVERRIDE="YYYY-MM-DD HH:MM".
set -euo pipefail

source "$HOME/.config/jira-sweep.env"
TZ_NAME="America/Los_Angeles"
TARGET_STATUS="Pending Release"
JQL='project = ENG AND sprint in openSprints() AND status = Done'
LABEL_JQL='project = ENG AND sprint in openSprints() AND status = "Pending Release" AND labels = claude'
SPARKPOS="$HOME/Code/SparkPos"
VERSION_JSON="${VERSION_JSON:-}"   # test override; default reads origin/develop, not the checkout
LOG="${JIRA_SWEEP_LOG:-$HOME/Library/Logs/jira-sweep.log}"
DRY_RUN="${DRY_RUN:-0}"

log() { echo "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

# Prints %u%H (ISO weekday + hour) for now, or for NOW_OVERRIDE when set.
now_dow_hour() {
  if [ -n "${NOW_OVERRIDE:-}" ]; then
    date -j -f "%Y-%m-%d %H:%M" "$NOW_OVERRIDE" +%u%H
  else
    TZ="$TZ_NAME" date +%u%H
  fi
}

in_standup_window() {
  local stamp; stamp="$(now_dow_hour)"
  local dow="${stamp:0:1}" hour="$((10#${stamp:1:2}))"
  [ "$dow" = "1" ] && [ "$hour" -ge 19 ]
}

api() { # api METHOD PATH [JSON_BODY]
  local method="$1" path="$2" body="${3:-}"
  local args=(-sS --fail-with-body -X "$method" -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -H "Accept: application/json")
  if [ -n "$body" ]; then args+=(-H "Content-Type: application/json" -d "$body"); fi
  curl "${args[@]}" "https://$JIRA_SITE_URL$path"
}

urlencode() { jq -rn --arg s "$1" '$s|@uri'; }

# Emits "KEY:claudeFlag" per Done issue (flag 1 if labelled "claude"), paginating.
done_issues() {
  local token="" resp
  while :; do
    resp="$(api GET "/rest/api/3/search/jql?jql=$(urlencode "$JQL")&fields=labels&maxResults=100&nextPageToken=$token")"
    jq -r '.issues[] | .key + ":" + (if (.fields.labels // [] | index("claude")) then "1" else "0" end)' <<<"$resp"
    token="$(jq -r '.nextPageToken // empty' <<<"$resp")"
    [ -z "$token" ] && break
  done
}

# accountId of whoever made the most recent status change on the issue.
last_status_change_author() {
  local key="$1" resp total
  resp="$(api GET "/rest/api/3/issue/$key/changelog?maxResults=100")"
  if [ "$(jq -r '.isLast' <<<"$resp")" != "true" ]; then
    total="$(jq -r '.total' <<<"$resp")"
    resp="$(api GET "/rest/api/3/issue/$key/changelog?maxResults=100&startAt=$((total - 100))")"
  fi
  jq -r '[.values[] | select(any(.items[]; .field == "status"))] | last | .author.accountId // empty' <<<"$resp"
}

transition_to_target() {
  local key="$1" id
  id="$(api GET "/rest/api/3/issue/$key/transitions" | jq -r --arg s "$TARGET_STATUS" '.transitions[] | select(.to.name == $s) | .id')"
  [ -n "$id" ] || { log "ERROR $key: no transition to '$TARGET_STATUS'"; return 1; }
  if [ "$DRY_RUN" = "1" ]; then log "DRY_RUN would move $key -> $TARGET_STATUS"; return 0; fi
  api POST "/rest/api/3/issue/$key/transitions" "{\"transition\":{\"id\":\"$id\"}}" >/dev/null
  log "moved $key -> $TARGET_STATUS"
}

# ENG-2510: labels claude tickets in Pending Release with the release in flight — one minor
# below version.json (develop is bumped at cut, so 2.09.00 means release 2.08 is pending).
version_json() {
  if [ -n "$VERSION_JSON" ]; then cat "$VERSION_JSON"; return; fi
  git -C "$SPARKPOS" fetch -q origin develop
  git -C "$SPARKPOS" show origin/develop:version.json
}

version_label() {
  version_json | jq -r '.version | split(".") | .[0] + "." + (("0" + ((.[1] | tonumber) - 1 | tostring))[-2:]) + ".X"'
}

# The release branch that matches version_label, e.g. label 2.09.X -> release-2-09-XX.
release_branch_name() {
  version_json | jq -r '.version | split(".") | "release-" + .[0] + "-" + (("0" + ((.[1] | tonumber) - 1 | tostring))[-2:]) + "-XX"'
}

# ENG-XXXX: only label if the ticket's PR is actually in the release branch. A ticket
# merged to develop after the cut isn't reachable from the branch -> skip it (labels later).
pr_in_release() {
  local key="$1" br="$2"
  [ -n "$(git -C "$SPARKPOS" log "origin/$br" -1 -E --grep="${key}([^0-9]|$)" --format=%H 2>/dev/null)" ]
}

# ENG-2562: a ticket carries exactly one version label — the pending release's; every other
# version label is dropped in the same PUT. Emits "KEY<TAB>keep<TAB>body<TAB>drop,list" per ticket to fix
# (drop last: an empty field collapses under a tab IFS, so it must not precede anything).
label_plan() {
  jq -r --arg l "$1" '
    def vers: select(test("^[0-9]+\\.[0-9]+\\.X$"));
    .issues[]
    | (.fields.labels // []) as $have
    | $l as $keep
    | [$have[] | vers | select(. != $keep)] as $drop
    | select(($drop | length) > 0 or ($have | index($keep) | not))
    | [.key, $keep,
       ({update: {labels: ((if ($have | index($keep)) then [] else [{add: $keep}] end) + ($drop | map({remove: .})))}} | tojson),
       ($drop | join(","))]
    | @tsv'
}

# Increments caller's `labelled` (dynamic scope) so log lines still reach stdout.
label_pending_release() {
  local label token="" resp key keep drop body branch gate=0
  label="$(version_label)"
  branch="$(release_branch_name)"
  if git -C "$SPARKPOS" ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
    gate=1; git -C "$SPARKPOS" fetch -q origin "$branch"
    log "release branch origin/$branch exists — gating labels to PRs in it"
  else
    log "no release branch origin/$branch — labelling blindly"
  fi
  while :; do
    resp="$(api GET "/rest/api/3/search/jql?jql=$(urlencode "$LABEL_JQL")&fields=labels&maxResults=100&nextPageToken=$token")"
    while IFS=$'\t' read -r key keep body drop; do
      if [ "$gate" = "1" ] && ! pr_in_release "$key" "$branch"; then
        log "skip $key: not in origin/$branch"; continue
      fi
      if [ "$DRY_RUN" = "1" ]; then log "DRY_RUN would label $key $keep${drop:+ (drop $drop)}"; else
        if api PUT "/rest/api/3/issue/$key" "$body" >/dev/null; then
          log "labelled $key $keep${drop:+ (dropped $drop)}"
        else
          log "ERROR $key: label PUT failed, continuing"; continue
        fi
      fi
      labelled=$((labelled + 1))
    done < <(label_plan "$label" <<<"$resp")
    token="$(jq -r '.nextPageToken // empty' <<<"$resp")"
    [ -z "$token" ] && break
  done
}

main() {
  if in_standup_window; then log "skip: standup window (Mon 19:00-23:59 $TZ_NAME)"; return 0; fi
  local me items checked=0 moved=0 labelled=0 item key claude author
  me="$(api GET /rest/api/3/myself | jq -r '.accountId')"
  items="$(done_issues)"
  for item in $items; do
    checked=$((checked + 1))
    key="${item%%:*}"; claude="${item##*:}"
    # Move if claude-labelled, else only if I last moved it to Done.
    # Per-issue failures log and continue: an aborted run here would skip
    # label_pending_release below (2026-09-01: exit 22 mid-loop did exactly that).
    if [ "$claude" = "1" ]; then
      if transition_to_target "$key"; then moved=$((moved + 1)); else log "ERROR $key: transition failed, continuing"; fi
      continue
    fi
    author="$(last_status_change_author "$key")" || { log "ERROR $key: changelog fetch failed, continuing"; continue; }
    if [ "$author" = "$me" ]; then
      if transition_to_target "$key"; then moved=$((moved + 1)); else log "ERROR $key: transition failed, continuing"; fi
    fi
  done
  label_pending_release
  log "done: checked=$checked moved=$moved labelled=$labelled dry_run=$DRY_RUN"
}

main "$@"
