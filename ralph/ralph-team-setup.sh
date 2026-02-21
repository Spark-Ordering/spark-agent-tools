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
    echo "Stashing them before branch switch..."
    git stash push -m "ralph-team-setup auto-stash for $agent"
    echo ""
fi

# Create/switch to agent branch
if [[ "$current_branch" == "$target_branch" ]]; then
    echo -e "${GREEN}✅ Already on correct branch: $target_branch${NC}"
elif git show-ref --verify --quiet "refs/heads/$target_branch"; then
    # Branch exists locally, switch to it
    echo "Branch exists, switching..."
    git checkout "$target_branch"
    echo -e "${GREEN}✅ Switched to existing branch: $target_branch${NC}"
elif git show-ref --verify --quiet "refs/remotes/origin/$target_branch"; then
    # Branch exists on remote, create local tracking branch
    echo "Branch exists on remote, creating local tracking branch..."
    git checkout -b "$target_branch" "origin/$target_branch"
    echo -e "${GREEN}✅ Created tracking branch: $target_branch${NC}"
else
    # Branch doesn't exist, create it from base
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

echo ""

# Check if plan has agent markers
has_markers=$(grep -c '<!-- agent:' "$plan_file" 2>/dev/null || echo "0")

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
