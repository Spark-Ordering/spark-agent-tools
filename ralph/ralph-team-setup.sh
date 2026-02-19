#!/bin/bash
# ralph-team-setup.sh - Automatically set up branch and task coordination for team mode
#
# Usage:
#   ralph-team-setup.sh <agent> <plan_file>
#
# This script:
#   1. Creates agent-specific branch if needed (feature/X-dev1, feature/X-dev2)
#   2. Switches to that branch
#   3. Auto-splits tasks in plan if no agent markers exist
#   4. Returns branch name for confirmation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

agent="${1:-dev1}"
plan_file="${2:-}"

# Find plan file if not provided
if [[ -z "$plan_file" ]]; then
    plan_file=$(ls -t "$HOME/.claude/plans/"*.md 2>/dev/null | head -1)
fi

if [[ ! -f "$plan_file" ]]; then
    echo "ERROR: No plan file found" >&2
    exit 1
fi

# Get current branch
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [[ -z "$current_branch" ]]; then
    echo "ERROR: Not in a git repository" >&2
    exit 1
fi

# Determine base branch (strip -dev1/-dev2 if present)
base_branch="${current_branch%-dev1}"
base_branch="${base_branch%-dev2}"

# Calculate target branch
target_branch="${base_branch}-${agent}"

# Create/switch to agent branch
if git show-ref --verify --quiet "refs/heads/$target_branch"; then
    # Branch exists, switch to it
    git checkout "$target_branch" 2>/dev/null
    echo "BRANCH: Switched to existing $target_branch"
else
    # Create branch from base
    git checkout -b "$target_branch" 2>/dev/null
    echo "BRANCH: Created and switched to $target_branch"
fi

# Check if plan has agent markers
has_markers=$(grep -c '<!-- agent:' "$plan_file" 2>/dev/null || echo "0")

if [[ "$has_markers" -eq 0 ]]; then
    # Auto-split tasks - call the split script
    "$SCRIPT_DIR/ralph-split.sh" "$plan_file"
    echo "TASKS: Auto-split tasks between dev1 and dev2"
else
    echo "TASKS: Plan already has agent markers (found $has_markers)"
fi

# Output summary
echo ""
echo "🔧 Team setup complete:"
echo "   Agent: $agent"
echo "   Branch: $target_branch"
echo "   Plan: $(basename "$plan_file")"
