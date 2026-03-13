#!/usr/bin/env python3
"""
ralph merge - Collaborative file-level merge workflow.

COMMANDS:
  start                    → Initialize merge, list conflicting files
  show                     → Show ALL versions (base, dev1, dev2, staging)
  propose '<file>' '<msg>' → Propose staging file as resolution
  approve                  → Approve the current proposal
  finalize                 → Commit resolved files after all done
  next-action              → Get next action as JSON

WORKFLOW:
  1. ralph merge show (see all versions)
  2. Write resolved file to staging
  3. ralph merge propose '<filepath>' '<comment>'
  4. Other agent runs 'show', then approves or counter-proposes
  5. Both approved → file applied, move to next
  6. Repeat until all files done
"""

import json
import sys

from merge_file_review import (
    cmd_show, cmd_start, cmd_propose, cmd_approve,
    cmd_finalize, cmd_next_action
)
from merge_cmd_util import cmd_reset, cmd_wait


def main():
    if len(sys.argv) < 2:
        cmd_show()
        return

    cmd = sys.argv[1]

    if cmd == "start":
        cmd_start()

    elif cmd == "show":
        cmd_show()

    elif cmd == "propose":
        # ralph merge propose '<filepath>' '<comment>'
        if len(sys.argv) < 4:
            print("Usage: ralph merge propose '<filepath>' '<comment>'")
            print("Write your resolved file to staging first.")
            return
        filepath = sys.argv[2]
        comment = sys.argv[3]
        cmd_propose(filepath, comment)

    elif cmd == "approve":
        cmd_approve()

    elif cmd == "finalize":
        cmd_finalize()

    elif cmd == "next-action":
        result = cmd_next_action()
        print(json.dumps(result))

    elif cmd == "reset":
        cmd_reset()

    elif cmd == "wait":
        result = cmd_wait(10)
        print(json.dumps(result))

    else:
        print(f"Unknown command: {cmd}")
        print("")
        print("Commands:")
        print("  start              Initialize file-level merge")
        print("  show               Show all versions (base, dev1, dev2, staging)")
        print("  propose '<f>' '<c>' Propose staging as resolution")
        print("  approve            Approve current proposal")
        print("  finalize           Finalize merge (commit resolved files)")
        print("  next-action        Get next action as JSON")
        print("")
        print("Workflow:")
        print("  1. ralph merge show  (see all versions)")
        print("  2. Write resolved file to staging path")
        print("  3. ralph merge propose '<filepath>' '<comment>'")
        print("  4. Other agent runs 'show', then approves or counter-proposes")
        print("")
        print("Utility:")
        print("  reset       Clear all merge state")
        print("  wait        Wait for turn")


if __name__ == "__main__":
    main()
