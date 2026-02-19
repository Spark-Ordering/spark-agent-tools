#!/bin/bash
# ralph-sync.sh - Sync changes between team branches with conflict coordination
#
# Usage:
#   ralph-sync.sh <agent>           # Pull changes from other agent's branch
#   ralph-sync.sh <agent> --push    # Push to remote after committing
#   ralph-sync.sh <agent> --check   # Just check for potential conflicts (dry-run)
#
# When conflicts occur, outputs COORDINATE message for Claude to use SendMessage.

agent="${1:-}"
flag="${2:-}"

if [[ -z "$agent" ]]; then
    echo "Usage: ralph-sync.sh <agent> [--push|--check]" >&2
    exit 1
fi

# Determine the other agent
if [[ "$agent" == "dev1" ]]; then
    other_agent="dev2"
else
    other_agent="dev1"
fi

# Get current branch
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
base_branch="${current_branch%-${agent}}"
other_branch="${base_branch}-${other_agent}"

echo "🔄 Sync for $agent"
echo "   Your branch: $current_branch"
echo "   Other branch: $other_branch"

# Check if other branch exists
if ! git show-ref --verify --quiet "refs/heads/$other_branch"; then
    echo "   Other branch doesn't exist locally yet"

    # Try to fetch from remote
    if git fetch origin "$other_branch" 2>/dev/null; then
        git branch "$other_branch" "origin/$other_branch" 2>/dev/null
        echo "   Fetched from remote"
    else
        echo "   No remote branch either - nothing to sync"
        exit 0
    fi
fi

# Dry-run mode: just check for potential conflicts
if [[ "$flag" == "--check" ]]; then
    echo ""
    echo "Checking for potential conflicts..."

    # Get files changed on each branch since common ancestor
    merge_base=$(git merge-base "$current_branch" "$other_branch")
    my_files=$(git diff --name-only "$merge_base" "$current_branch")
    their_files=$(git diff --name-only "$merge_base" "$other_branch")

    # Find overlapping files
    overlap=$(comm -12 <(echo "$my_files" | sort) <(echo "$their_files" | sort))

    if [[ -n "$overlap" ]]; then
        echo "⚠️  POTENTIAL_CONFLICTS:"
        echo "$overlap" | while read -r file; do
            echo "   - $file"
        done
        echo ""
        echo "COORDINATE: Both $agent and $other_agent modified these files."
        echo "Use SendMessage to coordinate before syncing:"
        echo "  - Discuss which changes to keep"
        echo "  - Agree on resolution strategy"
        echo "  - One agent rebases first, other follows"
        exit 2
    else
        echo "✅ No overlapping files - safe to sync"
        exit 0
    fi
fi

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --staged --quiet; then
    echo ""
    echo "⚠️  You have uncommitted changes. Commit or stash them first."
    exit 1
fi

# Attempt rebase
echo ""
echo "Rebasing $current_branch onto $other_branch..."

# Start rebase, capture if it fails
if ! git rebase "$other_branch" 2>&1; then
    # Rebase failed - get conflicting files
    conflicting_files=$(git diff --name-only --diff-filter=U 2>/dev/null)

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "🚨 CONFLICT_DETECTED - Coordination Required"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Conflicting files:"
    echo "$conflicting_files" | while read -r file; do
        echo "   ❌ $file"
    done
    echo ""
    echo "COORDINATE with $other_agent using SendMessage:"
    echo ""
    echo "  1. Share which files you changed and why"
    echo "  2. Ask what they changed in the same files"
    echo "  3. Decide together:"
    echo "     - Keep your version? (git checkout --ours <file>)"
    echo "     - Keep their version? (git checkout --theirs <file>)"
    echo "     - Manual merge needed?"
    echo ""
    echo "After resolving:"
    echo "  git add <resolved-files>"
    echo "  git rebase --continue"
    echo ""
    echo "Or abort and coordinate first:"
    echo "  git rebase --abort"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    exit 3
fi

echo "✅ Rebase successful - no conflicts"

# Optionally push
if [[ "$flag" == "--push" ]]; then
    echo ""
    echo "Pushing to remote..."
    git push -u origin "$current_branch"
    echo "✅ Pushed to origin/$current_branch"
fi

echo ""
echo "Done! Your branch now includes $other_agent's changes."
