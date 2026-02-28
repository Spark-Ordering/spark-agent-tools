---
name: git-branch-commit-pr
description: |
  SparkPos git branching, commit, and PR workflow conventions. Use when: (1) user asks to
  commit and push work, (2) user asks to create a PR, (3) need to create a branch for new
  work, (4) user says "commit", "push", "create PR", or "ship it". Covers branch naming,
  commit message rules (no Claude credit), and PR title format with JIRA ticket numbers.
author: Carlos Borde
version: 1.1.0
date: 2026-02-28
---

# SparkPos Git Workflow

## When This Skill is Invoked: JUST DO IT

When the user invokes this skill, DO NOT ask what to do. Assess the current state and
execute the full workflow automatically:

1. Run `git status`, `git diff --stat`, `git branch --show-current`, `git log --oneline -5`
2. If there are uncommitted changes: stage specific files, commit, push
3. If everything is committed and pushed: create a PR
4. If already committed but not pushed: push, then create PR
5. Extract the JIRA ticket number from the branch name if present

The user expects you to figure out what step you're on and do the right thing.

## Branch Naming

Format: `cborde/<TICKET>/<short-description>`

- **User prefix**: `cborde` (always lowercase, one word)
- **Ticket**: `ENG-NNNN` (uppercase ENG, dash, number) — include if a JIRA ticket exists
- **Description**: kebab-case concise explanation of what the branch does

Examples:
```
cborde/ENG-2061/add-version-picker
cborde/ENG-1543/fix-payment-rounding
cborde/menu-editor-cleanup          (no ticket)
```

### When to create a branch
- If currently on `main`, `develop`, or any branch unrelated to the current work
- If already on a branch related to the work, just commit to it

## Commit Rules

1. **NEVER include Co-Authored-By lines** — no Claude credit, no co-author tags
2. **NEVER mention Claude, AI, or assistants** in commit messages
3. Write concise commit messages that describe the change
4. Use conventional commit format when appropriate: `feat(scope): message`, `fix(scope): message`
5. Always stage specific files, not `git add -A` or `git add .`

## PR Creation

1. **Title format**: `ENG-NNNN: Short description` (ticket number first)
   - Example: `ENG-2061: Add version picker to menu settings`
   - If no ticket: just the description
2. **NEVER mention Claude, AI, or assistants** anywhere in the PR (title, body, comments)
3. **Do NOT include** the "Generated with Claude Code" footer
4. Body uses this format (no Claude attribution):
```bash
gh pr create --title "ENG-2061: Add version picker" --body "$(cat <<'EOF'
## Summary
- Compact menu settings layout with side-by-side buttons
- Scrollable version table with activate functionality
- Active version highlighted, confirmation dialog before activation

## Test plan
- [ ] Navigate to Settings > Menu Settings
- [ ] Verify version table scrolls
- [ ] Activate a version and confirm it switches
EOF
)"
```
