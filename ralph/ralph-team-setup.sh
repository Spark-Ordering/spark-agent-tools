#!/bin/bash
# ralph-team-setup.sh - Automatically set up branch and task coordination for team mode
#
# Usage:
#   ralph-team-setup.sh <agent> <plan_file>
#
# This script:
#   1. Creates agent-specific branch if needed (feature/X-dev1, feature/X-dev2)
#   2. Switches to that branch (with verification)
#   3. Auto-splits tasks in plan if no agent markers exist
#   4. Returns branch name for confirmation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

agent="${1:-dev1}"
plan_file="${2:-}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Find plan file if not provided
if [[ -z "$plan_file" ]]; then
    plan_file=$(ls -t "$HOME/.claude/plans/"*.md 2>/dev/null | head -1)
fi

if [[ ! -f "$plan_file" ]]; then
    echo -e "${RED}ERROR: No plan file found${NC}" >&2
    exit 1
fi

# Verify we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Not in a git repository${NC}" >&2
    exit 1
fi

# Get current branch
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [[ -z "$current_branch" ]]; then
    echo -e "${RED}ERROR: Could not determine current branch${NC}" >&2
    exit 1
fi

# Determine base branch (strip -dev1/-dev2 if present)
base_branch="${current_branch%-dev1}"
base_branch="${base_branch%-dev2}"

# Calculate target branch
target_branch="${base_branch}-${agent}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 TEAM SETUP: $agent"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Current branch: $current_branch"
echo "Base branch:    $base_branch"
echo "Target branch:  $target_branch"
echo ""

# Check for uncommitted changes before switching
if ! git diff --quiet || ! git diff --staged --quiet; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes${NC}"
    echo "Auto-committing to current branch before recreating..."
    git add -A
    git commit -m "WIP: auto-commit before ralph team setup ($agent)"
    echo -e "${GREEN}✅ Changes committed to $current_branch${NC}"
    echo ""
fi

# Create/switch to agent branch
# IMPORTANT: Always create fresh branch from current base to avoid stale code

# Helper function to backup and delete existing branch
cleanup_existing_branch() {
    local branch_to_cleanup="$1"
    local backup_name="icebox/${branch_to_cleanup}-backup-$(date +%Y%m%d-%H%M%S)"

    # Check if branch has unique commits (not already merged into base)
    local unique_commits=$(git log "$base_branch..$branch_to_cleanup" --oneline 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$unique_commits" -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Branch has $unique_commits commit(s) not in $base_branch${NC}"
        echo "Creating backup: $backup_name"
        git branch "$backup_name" "$branch_to_cleanup"
        echo -e "${GREEN}✅ Backup created${NC}"
    else
        echo "Branch has no unique commits, no backup needed"
    fi

    # Delete the old branch
    echo "Deleting old branch: $branch_to_cleanup"
    git branch -D "$branch_to_cleanup"
}

if [[ "$current_branch" == "$target_branch" ]]; then
    # Already on the target branch - just stay here with committed changes
    echo -e "${GREEN}✅ Already on $target_branch - keeping existing work${NC}"

elif git show-ref --verify --quiet "refs/heads/$target_branch"; then
    # Branch exists locally - backup, delete, recreate fresh
    echo -e "${YELLOW}⚠️  Branch $target_branch already exists - recreating fresh from $base_branch${NC}"

    cleanup_existing_branch "$target_branch"

    # Make sure we're on base branch
    if [[ "$current_branch" != "$base_branch" ]] && git show-ref --verify --quiet "refs/heads/$base_branch"; then
        git checkout "$base_branch"
    fi

    # Create fresh
    git checkout -b "$target_branch"
    echo -e "${GREEN}✅ Recreated fresh branch: $target_branch (from $base_branch)${NC}"

elif git show-ref --verify --quiet "refs/remotes/origin/$target_branch"; then
    # Branch exists on remote but not locally
    # Still create fresh from local base (remote might be stale too)
    echo -e "${YELLOW}⚠️  Branch exists on remote - creating fresh local from $base_branch${NC}"
    echo "(Remote branch will remain unchanged)"

    # Make sure we're on base branch
    if [[ "$current_branch" != "$base_branch" ]] && git show-ref --verify --quiet "refs/heads/$base_branch"; then
        git checkout "$base_branch"
    fi

    git checkout -b "$target_branch"
    echo -e "${GREEN}✅ Created fresh local branch: $target_branch (from $base_branch)${NC}"
else
    # Branch doesn't exist anywhere - create it from base
    echo "Creating new branch from $base_branch..."

    # Make sure we're on base branch first if it exists
    if [[ "$current_branch" != "$base_branch" ]] && git show-ref --verify --quiet "refs/heads/$base_branch"; then
        git checkout "$base_branch"
    fi

    git checkout -b "$target_branch"
    echo -e "${GREEN}✅ Created new branch: $target_branch${NC}"
fi

# VERIFY we're actually on the correct branch
actual_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$actual_branch" != "$target_branch" ]]; then
    echo -e "${RED}ERROR: Branch switch failed!${NC}" >&2
    echo "Expected: $target_branch" >&2
    echo "Actual:   $actual_branch" >&2
    exit 1
fi

# CRITICAL: Push fresh branch to origin to sync remote
# This ensures ralph merge (which uses origin branches) sees fresh state
echo ""
echo "Syncing fresh branch to origin..."
if git push origin "$target_branch" --force-with-lease 2>/dev/null; then
    echo -e "${GREEN}✅ Remote synced: origin/$target_branch${NC}"
else
    # First push (no remote tracking yet)
    git push -u origin "$target_branch" --force 2>/dev/null && \
        echo -e "${GREEN}✅ Remote synced: origin/$target_branch${NC}" || \
        echo -e "${YELLOW}⚠️  Could not push to origin (offline or no permission)${NC}"
fi

echo ""

# Check if plan has agent markers
has_markers=$(grep -c '<!-- agent:' "$plan_file" 2>/dev/null | tr -d '\n' || echo "0")

if [[ "$has_markers" -eq 0 ]]; then
    echo "Splitting tasks between agents..."
    "$SCRIPT_DIR/ralph-split.sh" "$plan_file"
    echo -e "${GREEN}✅ Tasks auto-split between dev1 and dev2${NC}"
else
    echo "Plan already has agent markers ($has_markers found)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎯 TEAM SETUP COMPLETE${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Agent:  $agent"
echo "Branch: $target_branch (VERIFIED)"
echo "Plan:   $(basename "$plan_file")"
echo ""
echo "Your tasks are marked with: <!-- agent: $agent -->"
echo "Work ONLY on tasks in your sections."
