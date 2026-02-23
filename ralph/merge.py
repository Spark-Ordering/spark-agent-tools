#!/usr/bin/env python3
"""
ralph merge - Collaborative file-level merge workflow.

COMMANDS:
  start                    → Initialize merge, list conflicting files
  show                     → Show status (current file, seen flags, state)
  show base                → Show BASE version, mark as seen
  show dev1                → Show DEV1 version, mark as seen
  show dev2                → Show DEV2 version, mark as seen
  show staging             → Show current staging file
  propose '<file>' '<msg>' → Propose staging file as resolution
  approve                  → Approve the current proposal
  next                     → Skip to next file (recovery)
  finalize                 → Commit resolved files after all done
  next-action              → Get next action as JSON

WORKFLOW:
  1. Both agents read all 3 versions (base, dev1, dev2)
  2. One agent writes resolved file to staging and proposes
  3. Other agent reviews staging and approves
  4. Both approved → file applied, move to next
  5. Repeat until all files done

STATE MACHINE:
  INIT → start → REVIEWING
  REVIEWING → propose → PROPOSAL_PENDING
  PROPOSAL_PENDING → both approve → FILE_COMPLETE → next file
  All files done → DONE
"""

import json
import sys

from merge_file_review import (
    cmd_show, cmd_start, cmd_propose, cmd_approve, cmd_next,
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
        # ralph merge show [base|dev1|dev2|staging]
        variant = sys.argv[2] if len(sys.argv) > 2 else None
        cmd_show(variant)

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

    elif cmd == "next":
        cmd_next()

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
        print("  show               Show status (file, seen flags, state)")
        print("  show base          Show BASE version (marks as seen)")
        print("  show dev1          Show DEV1 version (marks as seen)")
        print("  show dev2          Show DEV2 version (marks as seen)")
        print("  show staging       Show current staging file")
        print("  propose '<f>' '<c>' Propose staging as resolution")
        print("  approve            Approve current proposal")
        print("  next               Skip to next file")
        print("  finalize           Finalize merge (commit resolved files)")
        print("  next-action        Get next action as JSON")
        print("")
        print("Workflow:")
        print("  1. Read all 3 versions: show base, show dev1, show dev2")
        print("  2. Write resolved file to staging path")
        print("  3. Propose with filepath and comment")
        print("  4. Other agent reviews and approves")
        print("")
        print("Utility:")
        print("  reset       Clear all merge state")
        print("  wait        Wait for turn")


if __name__ == "__main__":
    main()
