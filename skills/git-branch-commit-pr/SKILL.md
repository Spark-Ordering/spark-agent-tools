---
name: git-branch-commit-pr
description: |
  SparkPos git branching, commit, and PR workflow conventions. Use when: (1) user asks to
  commit and push work, (2) user asks to create a PR, (3) need to create a branch for new
  work, (4) user says "commit", "push", "create PR", or "ship it". Covers branch naming,
  commit message rules (no Claude credit), and PR title format with JIRA ticket numbers.
author: Carlos Borde
version: 1.0.0
date: 2026-02-28
---

# SparkPos Git Workflow

## Problem
Consistent git workflow conventions for branching, committing, and creating PRs in SparkPos.

## Context / Trigger Conditions
- User asks to commit and push code
- User asks to create a PR
- Starting new work that needs a branch
- User says "commit", "push", "create PR", "ship it"

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

Example commit:
```bash
git commit -m "$(cat <<'EOF'
feat(menu-settings): compact layout with scrollable version table

- Replace verbose card layout with side-by-side buttons
- Extract MenuVersionTable as separate component
- FlatList-based scrollable version rows
EOF
)"
```

## PR Creation

1. **Title format**: `ENG-NNNN: Short description` (ticket number first)
   - Example: `ENG-2061: Add version picker to menu settings`
   - If no ticket: just the description
2. **NEVER mention Claude, AI, or assistants** anywhere in the PR (title, body, comments)
3. **Do NOT include** the "Generated with Claude Code" footer
4. Body format:
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

## Full Workflow Example

```bash
# 1. Check current branch
git branch --show-current

# 2. If on main/develop/unrelated, create branch
git checkout -b cborde/ENG-2061/add-version-picker

# 3. Stage and commit (NO Co-Authored-By)
git add src/components/views/SettingsView/pages/MenuVersionTable.tsx
git add src/components/views/SettingsView/pages/MenuSettingsPage.tsx
git commit -m "feat(menu-settings): add scrollable version table"

# 4. Push
git push -u origin cborde/ENG-2061/add-version-picker

# 5. Create PR (NO Claude mentions)
gh pr create --title "ENG-2061: Add scrollable version table" --body "..."
```

## Notes
- The user handles all git commits themselves most of the time — only commit when explicitly asked
- Always stage specific files, not `git add -A` or `git add .`
- Check `git status` and `git diff` before committing to understand what's changing
