#!/bin/bash
# ralph-commit.sh - Safe commit wrapper for team mode
#
# Usage:
#   ralph-commit.sh <agent> "commit message"
#
# Safety features:
#   - Only commits if on agent's own branch (e.g., dev1 can only commit to *-dev1)
#   - Shows what would be committed before proceeding
#   - Optionally pulls changes from base branch first

agent="${1:-}"
message="${2:-}"

if [[ -z "$agent" ]] || [[ -z "$message" ]]; then
    echo "Usage: ralph-commit.sh <agent> \"commit message\"" >&2
    exit 1
fi

# Get current branch
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Verify we're on the agent's branch
if [[ ! "$current_branch" == *"-${agent}" ]]; then
    echo "ERROR: Not on ${agent}'s branch" >&2
    echo "       Current: $current_branch" >&2
    echo "       Expected: *-${agent}" >&2
    exit 1
fi

# Check for changes
if git diff --quiet && git diff --staged --quiet; then
    echo "No changes to commit"
    exit 0
fi

# Show what will be committed
echo "📝 Changes to commit on $current_branch:"
git status --short

echo ""
echo "💬 Message: $message"
echo ""

# Stage and commit (let Claude handle the specific files)
# This script just verifies we're on the right branch
echo "✅ Verified: On correct branch for $agent"
echo "   Proceed with: git add <files> && git commit -m \"$message\""
