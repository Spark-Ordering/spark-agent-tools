#!/usr/bin/env bash
# Reset the sticky Claude PR review comment to its loading/pending state.
#
# Run this right after `git push` so the review comment can never show a review
# of code that is no longer on the branch. /claude-pr-comment sees the `pending`
# marker and polls instead of summarizing a stale review; the /start-pr-reviews
# loop sees a non-`done` marker and re-reviews the new head.
#
# No-ops (exit 0) when there's no PR or no existing Claude review comment —
# it only ever RESETS one, never creates one.
#
# Usage: reset-pr-review-comment.sh [PR_NUMBER]   (defaults to current branch's PR)
set -euo pipefail

repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
pr=${1:-$(gh pr view --json number --jq .number 2>/dev/null || true)}
if [ -z "$pr" ]; then
  echo "reset-pr-review-comment: no PR for this branch — nothing to reset"
  exit 0
fi

# Target by comment id, not `gh pr comment --edit-last`, so this can never
# clobber some other comment from the same account.
id=$(gh api "repos/$repo/issues/$pr/comments" --paginate \
  --jq 'map(select(.body | startswith("<!-- claude-pr-review"))) | last | .id // empty')
if [ -z "$id" ]; then
  echo "reset-pr-review-comment: PR #$pr has no Claude review comment — nothing to reset"
  exit 0
fi

sha=$(git rev-parse HEAD)
short=${sha:0:7}
gh api -X PATCH "repos/$repo/issues/comments/$id" \
  -f body="<!-- claude-pr-review:pending:$sha -->
⏳ **Claude is reviewing this PR** (\`$short\`)…" >/dev/null

echo "reset-pr-review-comment: PR #$pr review comment reset to pending:$short"
