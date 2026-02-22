#!/usr/bin/env python3
"""
ralph merge - Collaborative consensus-based merge workflow.

WORKFLOW:
  start    → Initialize merge, analyze conflicting files
  show     → Display current hunk, proposals, and discussion
  propose  → Suggest a resolution (either agent can do this)
  comment  → Add to the discussion
  agree    → Signal you're satisfied with the current proposal
  finalize → Apply all staged files and commit

CONSENSUS MODEL:
- Either agent can propose a resolution at any time
- Either agent can add comments to discuss
- When BOTH agents agree, the hunk is resolved and moves to next
- No fixed "writer/reviewer" roles - it's collaborative

TURN COORDINATION:
- Turns prevent race conditions, not assign roles
- After any action, turn passes to the other agent
- dev1 goes first on each new hunk
"""

import json
import sys

from merge_hunk_init import cmd_start_hunks, cmd_hunk_status
from merge_hunk_review import (
    cmd_show_hunk, cmd_propose_hunk, cmd_comment_hunk, cmd_agree_hunk,
    cmd_write_hunk, cmd_approve_hunk, cmd_reject_hunk  # aliases
)
from merge_hunk_finalize import cmd_finalize_hunks
from merge_hunk_nav import cmd_hunk_next_action
from merge_cmd_util import cmd_status, cmd_reset, cmd_complete, cmd_wait


def main():
    if len(sys.argv) < 2:
        cmd_status()
        return

    cmd = sys.argv[1]

    # Core workflow commands
    if cmd == "start":
        cmd_start_hunks()
    elif cmd == "show":
        cmd_show_hunk()
    elif cmd == "propose":
        from pathlib import Path
        proposal_file = Path.home() / ".claude" / "merge-staging" / "proposal.txt"

        code = None
        # Priority 1: Read from proposal file
        if proposal_file.exists():
            code = proposal_file.read_text()
            if code.strip():
                proposal_file.unlink()  # Clear after reading
            else:
                code = None

        # Priority 2: Command line arg
        if not code and len(sys.argv) >= 3:
            code = sys.argv[2]

        # Priority 3: stdin
        if not code:
            import sys as _sys
            if not _sys.stdin.isatty():
                code = _sys.stdin.read()

        if not code or not code.strip():
            print("ERROR: Empty proposal. Write your resolved code to:")
            print(f"  {proposal_file}")
            print("Then run: ralph merge propose")
            return

        cmd_propose_hunk(code)
    elif cmd == "comment":
        if len(sys.argv) >= 3:
            text = sys.argv[2]
        else:
            import sys as _sys
            if not _sys.stdin.isatty():
                text = _sys.stdin.read()
            else:
                print("Usage: ralph merge comment '<your thoughts>'")
                return
        cmd_comment_hunk(text)
    elif cmd == "agree":
        cmd_agree_hunk()
    elif cmd == "finalize":
        cmd_finalize_hunks()

    # Aliases for old commands
    elif cmd == "write":
        if len(sys.argv) >= 3:
            code = sys.argv[2]
        else:
            import sys as _sys
            if not _sys.stdin.isatty():
                code = _sys.stdin.read()
            else:
                print("Usage: ralph merge write << 'EOF'")
                print("your code here")
                print("EOF")
                return
        cmd_write_hunk(code)
    elif cmd == "approve":
        cmd_approve_hunk()
    elif cmd == "reject":
        if len(sys.argv) < 3:
            print("Usage: ralph merge reject '<reason>'")
            return
        cmd_reject_hunk(sys.argv[2])

    # Status and utility
    elif cmd == "status":
        cmd_hunk_status()
    elif cmd == "reset":
        cmd_reset()
    elif cmd == "complete":
        cmd_complete()
    elif cmd == "wait":
        max_sec = int(sys.argv[2]) if len(sys.argv) > 2 else 10
        result = cmd_wait(max_sec)
        print(json.dumps(result))
    elif cmd == "next-action":
        result = cmd_hunk_next_action()
        print(json.dumps(result))

    else:
        print(f"Unknown command: {cmd}")
        print("")
        print("Collaborative merge workflow:")
        print("  start → show → propose/comment → agree → finalize")
        print("")
        print("Commands:")
        print("  start     Initialize hunk-by-hunk merge")
        print("  show      Show current hunk + proposals + discussion")
        print("  propose   Suggest a resolution")
        print("  comment   Add to the discussion")
        print("  agree     Signal satisfaction with current proposal")
        print("  finalize  Apply staged files and commit")
        print("")
        print("Both agents must 'agree' before moving to next hunk.")
        print("")
        print("Utility:")
        print("  status      Show current merge status")
        print("  reset       Clear all merge state")
        print("  complete    Clean up after merge")
        print("  wait        Wait for turn")
        print("  next-action Get next action to take")


if __name__ == "__main__":
    main()
