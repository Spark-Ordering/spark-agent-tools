#!/usr/bin/env python3
"""
ralph merge - STRICTLY TURN-BASED dual-agent merge workflow.

TURN ENFORCEMENT:
- "whose_turn" field determines who can act
- If it's not your turn, you WAIT (no action)
- After acting, you set whose_turn to the other agent
- dev1 always goes first

Each agent writes ONLY to their own state file.
Reading merges both files to get combined view.
"""

import io
import json
import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime

COORD_DIR = Path.home() / ".claude" / "coordination"

def get_base_branch_from_git() -> str:
    """Get base branch from current git branch (strips -dev1/-dev2 suffix)."""
    result = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True, text=True
    )
    current = result.stdout.strip()
    return current.replace("-dev1", "").replace("-dev2", "")

def get_state_file(agent: str, base_branch: str = None) -> Path:
    """Get state file path. Includes base branch for isolation between branches."""
    if not base_branch:
        base_branch = get_base_branch_from_git()
    # Sanitize branch name for filename (replace / with -)
    safe_branch = base_branch.replace("/", "-")
    return COORD_DIR / f"merge-state-{safe_branch}-{agent}.json"

def get_agent() -> str:
    identity_file = Path.home() / ".claude" / "agent-identity"
    if identity_file.exists():
        agent = identity_file.read_text().strip()
        if agent in ("dev1", "dev2"):
            return agent

    env_agent = os.environ.get("RALPH_AGENT", "")
    if env_agent in ("dev1", "dev2"):
        return env_agent

    ralph_flag = Path.home() / ".claude" / ".ralph-mode"
    if ralph_flag.exists():
        content = ralph_flag.read_text().strip()
        if ":" in content:
            agent = content.split(":")[0]
            if agent in ("dev1", "dev2"):
                return agent
        elif content in ("dev1", "dev2"):
            return content

    hostname = subprocess.run(["hostname"], capture_output=True, text=True).stdout.strip().lower()
    if any(x in hostname for x in ["macbook-air", "mac.attlocal", "mac.local"]):
        return "dev1"
    if any(x in hostname for x in ["macbook-pro", "carloss-macbook"]):
        return "dev2"

    return "unknown"

def empty_state() -> dict:
    return {
        "phase": "idle",
        "whose_turn": "dev1",  # dev1 always starts
        "current_file": None,
        "base_branch": None,
        "files": {},
        "history": []
    }

def load_agent_state(agent: str) -> dict:
    """Load agent state - use SSH for remote agent to get real-time state."""
    my_agent = get_agent()
    state_file = get_state_file(agent)

    # If reading OUR OWN state, read locally
    if agent == my_agent:
        if not state_file.exists():
            return empty_state()
        try:
            with open(state_file) as f:
                return json.load(f)
        except:
            return empty_state()

    # Reading OTHER agent's state - SSH for real-time (avoids sync lag)
    # dev1 = MacBook Air at 192.168.1.148, dev2 = MacBook Pro at 192.168.1.104
    if my_agent == "dev1" and agent == "dev2":
        other_host = "carlos@192.168.1.104"
    elif my_agent == "dev2" and agent == "dev1":
        other_host = "carlos@192.168.1.148"
    else:
        other_host = None

    if other_host:
        try:
            result = subprocess.run(
                ["ssh", "-o", "ConnectTimeout=3", other_host, f"cat {state_file} 2>/dev/null"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0 and result.stdout.strip():
                return json.load(io.StringIO(result.stdout))
        except:
            pass  # Fall through to local file

    # Fallback: read synced local copy
    if not state_file.exists():
        return empty_state()
    try:
        with open(state_file) as f:
            return json.load(f)
    except:
        return empty_state()

def merge_states(dev1_state: dict, dev2_state: dict) -> dict:
    """Merge both agent states. TURN is determined by most recent action."""
    phase_priority = {"idle": 0, "started": 1, "review": 2, "clean": 3, "merged": 4}
    p1 = phase_priority.get(dev1_state.get("phase", "idle"), 0)
    p2 = phase_priority.get(dev2_state.get("phase", "idle"), 0)
    phase = dev1_state.get("phase") if p1 >= p2 else dev2_state.get("phase")

    current_file = dev1_state.get("current_file") or dev2_state.get("current_file")
    base_branch = dev1_state.get("base_branch") or dev2_state.get("base_branch")

    # TURN: check whose_turn from both states, use most recently set
    # Compare last history entry timestamps
    h1 = dev1_state.get("history", [])
    h2 = dev2_state.get("history", [])
    last_t1 = h1[-1]["time"] if h1 else ""
    last_t2 = h2[-1]["time"] if h2 else ""

    if last_t1 > last_t2:
        whose_turn = dev1_state.get("whose_turn", "dev1")
    elif last_t2 > last_t1:
        whose_turn = dev2_state.get("whose_turn", "dev1")
    else:
        whose_turn = dev1_state.get("whose_turn") or dev2_state.get("whose_turn") or "dev1"

    # Merge files
    merged_files = {}
    all_file_paths = set(dev1_state.get("files", {}).keys()) | set(dev2_state.get("files", {}).keys())

    for filepath in all_file_paths:
        f1 = dev1_state.get("files", {}).get(filepath, {})
        f2 = dev2_state.get("files", {}).get(filepath, {})

        discussed_by = list(set(f1.get("discussed_by", [])) | set(f2.get("discussed_by", [])))

        all_discussions = f1.get("discussion", []) + f2.get("discussion", [])
        seen = set()
        discussions = []
        for d in sorted(all_discussions, key=lambda x: x.get("time", "")):
            key = (d.get("time"), d.get("agent"))
            if key not in seen:
                seen.add(key)
                discussions.append(d)

        votes = {
            "dev1": f1.get("votes", {}).get("dev1") or f2.get("votes", {}).get("dev1"),
            "dev2": f1.get("votes", {}).get("dev2") or f2.get("votes", {}).get("dev2")
        }

        proposal = f1.get("proposal") or f2.get("proposal")
        proposed_by = f1.get("proposed_by") or f2.get("proposed_by")

        if votes["dev1"] == "APPROVE" and votes["dev2"] == "APPROVE":
            status = "approved"
        elif proposal:
            status = "proposed"
        else:
            status = "pending"

        merged_files[filepath] = {
            "status": status,
            "discussed_by": discussed_by,
            "discussion": discussions,
            "proposal": proposal,
            "proposed_by": proposed_by,
            "votes": votes
        }

    # Merge history
    all_history = dev1_state.get("history", []) + dev2_state.get("history", [])
    seen_history = set()
    history = []
    for h in sorted(all_history, key=lambda x: x.get("time", "")):
        key = (h.get("time"), h.get("agent"), h.get("action"))
        if key not in seen_history:
            seen_history.add(key)
            history.append(h)

    return {
        "phase": phase,
        "whose_turn": whose_turn,
        "current_file": current_file,
        "base_branch": base_branch,
        "files": merged_files,
        "history": history
    }

def load_state() -> dict:
    dev1_state = load_agent_state("dev1")
    dev2_state = load_agent_state("dev2")
    return merge_states(dev1_state, dev2_state)

def save_state(state: dict):
    agent = get_agent()
    if agent not in ("dev1", "dev2"):
        print(f"ERROR: Cannot save state - unknown agent: {agent}")
        return
    COORD_DIR.mkdir(parents=True, exist_ok=True)
    state_file = get_state_file(agent)
    with open(state_file, "w") as f:
        json.dump(state, f, indent=2)

def log_action(state: dict, agent: str, action: str):
    state["history"].append({
        "time": datetime.now().isoformat(),
        "agent": agent,
        "action": action
    })

def pass_turn(state: dict, agent: str):
    """Pass turn to the other agent."""
    other = "dev2" if agent == "dev1" else "dev1"
    state["whose_turn"] = other

def get_branch_info() -> tuple:
    current = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True, text=True
    ).stdout.strip()
    base = current.replace("-dev1", "").replace("-dev2", "")
    other = f"{base}-dev2" if current.endswith("-dev1") else f"{base}-dev1"
    return current, base, other

def get_conflicting_files() -> list:
    current, base, other = get_branch_info()
    subprocess.run(["git", "fetch", "origin"], capture_output=True)
    result = subprocess.run(
        ["git", "merge-base", current, f"origin/{other}"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return []
    merge_base = result.stdout.strip()

    my_files = set(subprocess.run(
        ["git", "diff", "--name-only", merge_base, current],
        capture_output=True, text=True
    ).stdout.strip().split("\n"))

    their_files = set(subprocess.run(
        ["git", "diff", "--name-only", merge_base, f"origin/{other}"],
        capture_output=True, text=True
    ).stdout.strip().split("\n"))

    overlap = sorted(my_files & their_files)
    return [f for f in overlap if f]

def get_file_diff(filepath: str) -> dict:
    current, base, other = get_branch_info()

    # Fetch latest from both branches so both agents see current state
    subprocess.run(["git", "fetch", "origin"], capture_output=True)

    result = subprocess.run(
        ["git", "merge-base", current, f"origin/{other}"],
        capture_output=True, text=True
    )
    merge_base = result.stdout.strip()

    # Both use origin/ prefix so it works on either machine
    dev1_diff = subprocess.run(
        ["git", "diff", merge_base, f"origin/{base}-dev1", "--", filepath],
        capture_output=True, text=True
    ).stdout

    dev2_diff = subprocess.run(
        ["git", "diff", merge_base, f"origin/{base}-dev2", "--", filepath],
        capture_output=True, text=True
    ).stdout

    return {"dev1": dev1_diff, "dev2": dev2_diff}

# === COMMANDS ===

def cmd_start():
    agent = get_agent()
    current, base, other = get_branch_info()

    # Clear coordination messages when starting merge
    messages_file = COORD_DIR / "messages.txt"
    if messages_file.exists():
        messages_file.unlink()
        print("🗑️  Cleared coordination messages")

    print(f"📤 Starting merge phase as {agent}")

    status = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True)
    if status.stdout.strip():
        print("   Committing changes...")
        subprocess.run(["git", "add", "-A"])
        subprocess.run(["git", "commit", "-m", f"Merge phase: {agent} final changes"])

    print(f"   Pushing {current}...")
    subprocess.run(["git", "push", "-u", "origin", current])

    my_state = load_agent_state(agent)
    my_state["phase"] = "started"
    my_state["base_branch"] = base
    my_state["whose_turn"] = "dev1"  # dev1 always starts
    log_action(my_state, agent, "started merge")
    save_state(my_state)

    print("✅ Done. Run: ralph merge check")

def cmd_reset():
    """Clear all merge state on BOTH machines."""
    agent = get_agent()
    base_branch = get_base_branch_from_git()
    safe_branch = base_branch.replace("/", "-")

    # Files to clear
    files_to_clear = [
        str(COORD_DIR / "messages.txt"),
        str(COORD_DIR / f"merge-state-{safe_branch}-dev1.json"),
        str(COORD_DIR / f"merge-state-{safe_branch}-dev2.json"),
    ]

    # Clear locally
    print("🗑️  Clearing local merge state...")
    for f in files_to_clear:
        p = Path(f)
        if p.exists():
            p.unlink()
            print(f"   Deleted: {p.name}")

    # Clear on remote (dev2) via SSH
    print("🗑️  Clearing remote merge state (dev2)...")
    remote_cmd = f"rm -f {' '.join(files_to_clear)}"
    result = subprocess.run(
        ["ssh", "carlos@192.168.1.104", remote_cmd],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        print("   ✅ Remote cleared")
    else:
        print(f"   ⚠️  Remote clear failed: {result.stderr.strip()}")

    print(f"✅ Merge state reset for branch: {base_branch}")

def cmd_check():
    agent = get_agent()
    files = get_conflicting_files()

    if not files:
        print("✅ No conflicts - clean merge possible")
        my_state = load_agent_state(agent)
        my_state["phase"] = "clean"
        save_state(my_state)
        print("Run: ralph merge execute")
        return

    print(f"⚠️  {len(files)} overlapping files found:\n")

    my_state = load_agent_state(agent)
    if "files" not in my_state:
        my_state["files"] = {}
    for f in files:
        if f not in my_state["files"]:
            my_state["files"][f] = {
                "status": "pending",
                "discussed_by": [],
                "discussion": [],
                "proposal": None,
                "proposed_by": None,
                "votes": {"dev1": None, "dev2": None}
            }
        print(f"   📄 {f}")

    if not my_state.get("current_file"):
        my_state["current_file"] = files[0]

    my_state["phase"] = "review"
    my_state["whose_turn"] = "dev1"  # dev1 goes first
    log_action(my_state, agent, f"detected {len(files)} conflicts")
    save_state(my_state)

    print(f"\n🔒 Locked onto: {my_state['current_file']}")
    print(f"📍 Turn: dev1 goes first")
    print("Run: ralph merge show")

def cmd_show():
    state = load_state()
    current_file = state.get("current_file")

    if not current_file:
        print("No current file. Run: ralph merge check")
        return

    print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print(f"📄 {current_file}")
    print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    diffs = get_file_diff(current_file)

    print("\n━━━ dev1's changes ━━━")
    print(diffs["dev1"][:2000] if diffs["dev1"] else "(no changes)")

    print("\n━━━ dev2's changes ━━━")
    print(diffs["dev2"][:2000] if diffs["dev2"] else "(no changes)")

    file_state = state["files"].get(current_file, {})
    discussion = file_state.get("discussion", [])
    if discussion:
        print("\n━━━ Discussion ━━━")
        for d in discussion[-5:]:
            print(f"   [{d['agent']}]: {d['message'][:100]}")

    discussed = file_state.get("discussed_by", [])
    print(f"\n📊 Status: {file_state.get('status', 'pending')}")
    print(f"   Discussed: dev1={'✓' if 'dev1' in discussed else '✗'}, dev2={'✓' if 'dev2' in discussed else '✗'}")
    print(f"   Turn: {state.get('whose_turn', 'dev1')}")

def cmd_discuss(message: str):
    agent = get_agent()
    merged_state = load_state()

    # TURN CHECK
    whose_turn = merged_state.get("whose_turn", "dev1")
    if whose_turn != agent:
        print(f"⏳ Not your turn. Waiting for {whose_turn}...")
        return

    current_file = merged_state.get("current_file")
    if not current_file:
        print("No current file. Run: ralph merge check")
        return

    my_state = load_agent_state(agent)
    if "files" not in my_state:
        my_state["files"] = {}
    if current_file not in my_state["files"]:
        my_state["files"][current_file] = {
            "status": "pending",
            "discussed_by": [],
            "discussion": [],
            "proposal": None,
            "proposed_by": None,
            "votes": {"dev1": None, "dev2": None}
        }

    my_state["current_file"] = current_file
    file_state = my_state["files"][current_file]

    file_state["discussion"].append({
        "time": datetime.now().isoformat(),
        "agent": agent,
        "message": message
    })

    if agent not in file_state["discussed_by"]:
        file_state["discussed_by"].append(agent)

    log_action(my_state, agent, f"discussed {current_file}")
    pass_turn(my_state, agent)  # PASS TURN TO OTHER
    save_state(my_state)

    other = "dev2" if agent == "dev1" else "dev1"
    print(f"💬 {agent}: {message}")
    print(f"\n➡️  Turn passed to {other}")

def cmd_propose(resolution: str):
    agent = get_agent()
    merged_state = load_state()

    # TURN CHECK
    whose_turn = merged_state.get("whose_turn", "dev1")
    if whose_turn != agent:
        print(f"⏳ Not your turn. Waiting for {whose_turn}...")
        return

    current_file = merged_state.get("current_file")
    if not current_file:
        print("No current file. Run: ralph merge check")
        return

    merged_file = merged_state["files"].get(current_file, {})
    discussed = merged_file.get("discussed_by", [])
    if len(discussed) < 2:
        print("❌ Both agents must discuss before proposing.")
        print(f"   Discussed: {discussed}")
        return

    my_state = load_agent_state(agent)
    if "files" not in my_state:
        my_state["files"] = {}
    if current_file not in my_state["files"]:
        my_state["files"][current_file] = {
            "status": "pending",
            "discussed_by": [],
            "discussion": [],
            "proposal": None,
            "proposed_by": None,
            "votes": {"dev1": None, "dev2": None}
        }

    file_state = my_state["files"][current_file]
    file_state["proposal"] = resolution
    file_state["proposed_by"] = agent
    file_state["status"] = "proposed"

    log_action(my_state, agent, f"proposed for {current_file}")
    pass_turn(my_state, agent)  # PASS TURN
    save_state(my_state)

    other = "dev2" if agent == "dev1" else "dev1"
    print(f"📋 Proposal by {agent}: {resolution}")
    print(f"\n➡️  Turn passed to {other}")
    print(f"   {other} should vote: ralph merge vote approve")

def cmd_vote(vote: str, reason: str = ""):
    agent = get_agent()
    merged_state = load_state()

    # TURN CHECK
    whose_turn = merged_state.get("whose_turn", "dev1")
    if whose_turn != agent:
        print(f"⏳ Not your turn. Waiting for {whose_turn}...")
        return

    current_file = merged_state.get("current_file")
    if not current_file:
        print("No current file. Run: ralph merge check")
        return

    my_state = load_agent_state(agent)
    if "files" not in my_state:
        my_state["files"] = {}
    if current_file not in my_state["files"]:
        my_state["files"][current_file] = {
            "status": "pending",
            "discussed_by": [],
            "discussion": [],
            "proposal": None,
            "proposed_by": None,
            "votes": {"dev1": None, "dev2": None}
        }

    file_state = my_state["files"][current_file]
    other = "dev2" if agent == "dev1" else "dev1"

    if vote.lower() in ["approve", "yes", "y"]:
        file_state["votes"][agent] = "APPROVE"
        log_action(my_state, agent, f"approved {current_file}")
        pass_turn(my_state, agent)
        save_state(my_state)

        # Check merged state
        merged_state = load_state()
        merged_file = merged_state["files"].get(current_file, {})
        merged_votes = merged_file.get("votes", {})

        if merged_votes.get("dev1") == "APPROVE" and merged_votes.get("dev2") == "APPROVE":
            print(f"✅ {current_file} APPROVED by both!")

            next_file = None
            for f, fs in merged_state["files"].items():
                if fs.get("status") != "approved":
                    next_file = f
                    break

            if next_file:
                my_state["current_file"] = next_file
                my_state["whose_turn"] = "dev1"  # dev1 starts each new file
                save_state(my_state)
                print(f"\n🔒 Moving to: {next_file}")
                print(f"📍 Turn: dev1 starts")
            else:
                my_state["current_file"] = None
                save_state(my_state)
                print("\n🎉 ALL FILES APPROVED!")
                print("   ralph merge execute")
        else:
            print(f"✓ {agent} approved.")
            print(f"➡️  Turn passed to {other}")

    elif vote.lower() in ["reject", "no", "n"]:
        file_state["votes"] = {"dev1": None, "dev2": None}
        file_state["proposal"] = None
        file_state["proposed_by"] = None
        file_state["status"] = "pending"
        file_state["discussion"].append({
            "time": datetime.now().isoformat(),
            "agent": agent,
            "message": f"REJECTED: {reason}"
        })
        log_action(my_state, agent, f"rejected {current_file}")
        pass_turn(my_state, agent)
        save_state(my_state)
        print(f"❌ Rejected by {agent}: {reason}")
        print(f"➡️  Turn passed to {other}")

def cmd_status():
    state = load_state()
    agent = get_agent()

    print(f"Phase: {state.get('phase', 'idle')}")
    print(f"Current file: {state.get('current_file', 'none')}")
    print(f"Turn: {state.get('whose_turn', 'dev1')}")
    print(f"You are: {agent}")
    print()

    files = state.get("files", {})
    if not files:
        print("No files tracked.")
        return

    approved = sum(1 for f in files.values() if f.get("status") == "approved")
    print(f"Progress: {approved}/{len(files)} files approved\n")

    for path, info in files.items():
        status = info.get("status", "pending")
        icon = "✅" if status == "approved" else "⏳" if status == "proposed" else "❌"
        current = " 🔒" if path == state.get("current_file") else ""
        discussed = info.get("discussed_by", [])
        print(f"{icon} {path}{current}")
        print(f"   discussed: {discussed}, votes: {info.get('votes', {})}")

def cmd_execute():
    state = load_state()

    files = state.get("files", {})
    if files:
        for f, info in files.items():
            if info.get("status") != "approved":
                print(f"❌ Not all files approved. Blocked: {f}")
                return

    current, base, other = get_branch_info()

    print("🔀 Executing merge...")

    subprocess.run(["git", "fetch", "origin"])
    subprocess.run(["git", "checkout", base])
    subprocess.run(["git", "pull", "origin", base], capture_output=True)

    print("   Merging dev1...")
    result = subprocess.run(["git", "merge", f"origin/{base}-dev1", "--no-edit"])
    if result.returncode != 0:
        print("❌ Conflict merging dev1. Resolve manually.")
        return

    print("   Merging dev2...")
    result = subprocess.run(["git", "merge", f"origin/{base}-dev2", "--no-edit"])
    if result.returncode != 0:
        print("❌ Conflict merging dev2. Resolve manually.")
        return

    subprocess.run(["git", "push", "origin", base])

    agent = get_agent()
    my_state = load_agent_state(agent)
    my_state["phase"] = "merged"
    save_state(my_state)

    print("✅ Merge complete!")
    print("   ralph merge complete")

def cmd_complete():
    current, base, other = get_branch_info()

    subprocess.run(["git", "checkout", base], capture_output=True)
    subprocess.run(["git", "branch", "-d", f"{base}-dev1"], capture_output=True)
    subprocess.run(["git", "branch", "-d", f"{base}-dev2"], capture_output=True)

    # Delete state files for this branch (not just reset)
    dev1_state_file = get_state_file("dev1", base)
    dev2_state_file = get_state_file("dev2", base)
    dev1_state_file.unlink(missing_ok=True)
    dev2_state_file.unlink(missing_ok=True)
    print(f"   Deleted merge state files for {base}")

    ralph_flag = Path.home() / ".claude" / ".ralph-mode"
    ralph_flag.unlink(missing_ok=True)

    print("✅ Cleanup complete. Ralph mode disabled.")

def cmd_next_action() -> dict:
    """TURN-ENFORCED next action."""
    agent = get_agent()
    state = load_state()
    phase = state.get("phase", "idle")
    current_file = state.get("current_file")
    whose_turn = state.get("whose_turn", "dev1")

    result = {
        "agent": agent,
        "phase": phase,
        "current_file": current_file,
        "whose_turn": whose_turn,
        "action": None,
        "wait_for": None,
        "message": ""
    }

    # GLOBAL TURN CHECK - dev1 ALWAYS goes first in idle/started phases
    if phase in ("idle", "started") and agent == "dev2":
        # Dev2 must wait for dev1 to finish start+check
        dev1_state = load_agent_state("dev1")
        if dev1_state.get("phase", "idle") not in ("review", "clean", "merged"):
            result["wait_for"] = "dev1"
            result["message"] = "Waiting for dev1 to start merge first"
            return result

    # TURN CHECK for review phase
    if phase == "review" and whose_turn != agent:
        result["wait_for"] = whose_turn
        result["message"] = f"Not your turn. Waiting for {whose_turn}"
        return result

    if phase == "idle":
        result["action"] = "ralph merge start"
        result["message"] = "Start merge phase"
        return result

    if phase == "started":
        result["action"] = "ralph merge check"
        result["message"] = "Check for conflicts"
        return result

    if phase == "clean":
        result["action"] = "ralph merge execute"
        result["message"] = "No conflicts - execute merge"
        return result

    if phase == "merged":
        result["action"] = "ralph merge complete"
        result["message"] = "Cleanup"
        return result

    if not current_file:
        files = state.get("files", {})
        all_approved = all(f.get("status") == "approved" for f in files.values())
        if all_approved and files:
            result["action"] = "ralph merge execute"
            result["message"] = "All files approved"
        else:
            result["action"] = "ralph merge check"
            result["message"] = "No current file"
        return result

    # It's my turn - what should I do?
    file_state = state["files"].get(current_file, {})
    discussed_by = file_state.get("discussed_by", [])
    proposal = file_state.get("proposal")
    votes = file_state.get("votes", {})
    other = "dev2" if agent == "dev1" else "dev1"

    # Haven't discussed yet
    if agent not in discussed_by:
        result["action"] = f'ralph merge discuss "<your analysis of {current_file}>"'
        result["message"] = f"Discuss {current_file}"
        return result

    # Both discussed, no proposal - I should propose
    if len(discussed_by) >= 2 and not proposal:
        result["action"] = f'ralph merge propose "<resolution for {current_file}>"'
        result["message"] = "Both discussed - propose resolution"
        return result

    # Proposal exists, I haven't voted
    if proposal and not votes.get(agent):
        result["action"] = "ralph merge vote approve"
        result["message"] = f"Vote on proposal: {proposal[:50]}"
        return result

    # I discussed, other hasn't - but it's my turn? Pass to show
    result["action"] = "ralph merge show"
    result["message"] = "Show current file"
    return result

def main():
    if len(sys.argv) < 2:
        cmd_status()
        return

    cmd = sys.argv[1]

    if cmd == "start":
        cmd_start()
    elif cmd == "check":
        cmd_check()
    elif cmd == "show":
        cmd_show()
    elif cmd == "discuss":
        if len(sys.argv) < 3:
            print("Usage: merge.py discuss <message>")
            return
        cmd_discuss(sys.argv[2])
    elif cmd == "propose":
        if len(sys.argv) < 3:
            print("Usage: merge.py propose <resolution>")
            return
        cmd_propose(sys.argv[2])
    elif cmd == "vote":
        if len(sys.argv) < 3:
            print("Usage: merge.py vote approve|reject [reason]")
            return
        reason = sys.argv[3] if len(sys.argv) > 3 else ""
        cmd_vote(sys.argv[2], reason)
    elif cmd == "execute":
        cmd_execute()
    elif cmd == "complete":
        cmd_complete()
    elif cmd == "status":
        cmd_status()
    elif cmd == "reset":
        cmd_reset()
    elif cmd == "next-action":
        result = cmd_next_action()
        print(json.dumps(result))
    else:
        print(f"Unknown command: {cmd}")
        print("Commands: start, check, show, discuss, propose, vote, execute, complete, status, reset, next-action")

if __name__ == "__main__":
    main()
