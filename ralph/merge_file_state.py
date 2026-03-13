#!/usr/bin/env python3
"""
File-level merge state machine using the `transitions` library.

ARCHITECTURE:
- FileMergeModel: holds data (files, proposal, approvals, seen flags, etc.)
- Machine: manages state transitions, callbacks do all the work
- CLI commands just trigger events on the machine

STATES:
- INIT: Starting state - call begin() to start the workflow
- CHECK_REMAINING: Loop controller - checks if more files remain
- CHECKING_FILE: Checks if current file needs merge or is identical
- NO_PROPOSAL_DEV1: No proposal exists, dev1's turn to propose
- PROPOSAL_DEV2_NEITHER: Proposal exists, dev2's turn, neither approved
- PROPOSAL_DEV1_DEV2_APPROVED: Proposal exists, dev1's turn, dev2 approved
- PROPOSAL_DEV1_NEITHER: Proposal exists, dev1's turn, neither approved
- PROPOSAL_DEV2_DEV1_APPROVED: Proposal exists, dev2's turn, dev1 approved
- FILE_COMPLETE: Both approved, apply proposal and advance
- DONE: All files resolved
- REJECTED: Staging has conflict markers
- BLIND_REJECTED: Tried to approve without seeing staging

TRIGGERS:
- begin: Start the workflow (INIT → CHECK_REMAINING)
- has_more: More files remain (CHECK_REMAINING → CHECKING_FILE)
- no_more: No more files (CHECK_REMAINING → DONE)
- needs_merge: Current file differs between branches (CHECKING_FILE → NO_PROPOSAL_DEV1)
- is_identical: Current file is identical (CHECKING_FILE → CHECK_REMAINING)
- dev1_propose: dev1 proposes (→ PROPOSAL_DEV2_NEITHER)
- dev2_propose: dev2 counter-proposes (→ PROPOSAL_DEV1_NEITHER)
- dev1_approve: dev1 approves current proposal
- dev2_approve: dev2 approves current proposal
- file_resolved: File was resolved, advance to CHECK_REMAINING
- reject_markers: Staging has conflict markers (→ REJECTED)
- reject_blind: Agent tried to approve without seeing (→ BLIND_REJECTED)
- fix_markers: Fixed conflict markers (REJECTED → NO_PROPOSAL_DEV1)
- fix_blind: Viewed staging (BLIND_REJECTED → previous proposal state)
"""

import json
import time
from pathlib import Path
from typing import Optional, List
import subprocess
from transitions import Machine, State


STAGING_DIR = Path.home() / ".claude" / "merge-staging"


# =============================================================================
# STATES
# =============================================================================

STATES = [
    State(name='INIT'),
    State(name='CHECK_REMAINING'),
    State(name='CHECKING_FILE'),
    State(name='NO_PROPOSAL_DEV1'),
    State(name='PROPOSAL_DEV2_NEITHER'),
    State(name='PROPOSAL_DEV1_DEV2_APPROVED'),
    State(name='PROPOSAL_DEV1_NEITHER'),
    State(name='PROPOSAL_DEV2_DEV1_APPROVED'),
    State(name='FILE_COMPLETE'),
    State(name='DONE', final=True),
    State(name='REJECTED'),
    State(name='BLIND_REJECTED'),
]


# =============================================================================
# TRANSITIONS
# =============================================================================

TRANSITIONS = [
    # From INIT: start the workflow
    {
        'trigger': 'begin',
        'source': 'INIT',
        'dest': 'CHECK_REMAINING',
    },

    # From CHECK_REMAINING: loop controller
    {
        'trigger': 'has_more',
        'source': 'CHECK_REMAINING',
        'dest': 'CHECKING_FILE',
    },
    {
        'trigger': 'no_more',
        'source': 'CHECK_REMAINING',
        'dest': 'DONE',
    },

    # From CHECKING_FILE: check current file status
    {
        'trigger': 'needs_merge',
        'source': 'CHECKING_FILE',
        'dest': 'NO_PROPOSAL_DEV1',
    },
    {
        'trigger': 'is_identical',
        'source': 'CHECKING_FILE',
        'dest': 'CHECK_REMAINING',
        'before': 'stage_identical_and_advance',
    },

    # From NO_PROPOSAL_DEV1: only dev1 can propose
    {
        'trigger': 'dev1_propose',
        'source': 'NO_PROPOSAL_DEV1',
        'dest': 'PROPOSAL_DEV2_NEITHER',
        'before': 'store_dev1_proposal',
    },
    {
        'trigger': 'reject_markers',
        'source': 'NO_PROPOSAL_DEV1',
        'dest': 'REJECTED',
    },

    # From PROPOSAL_DEV2_NEITHER: dev2 can approve or counter-propose
    {
        'trigger': 'dev2_approve',
        'source': 'PROPOSAL_DEV2_NEITHER',
        'dest': 'PROPOSAL_DEV1_DEV2_APPROVED',
        'before': 'set_dev2_approval',
    },
    {
        'trigger': 'dev2_propose',
        'source': 'PROPOSAL_DEV2_NEITHER',
        'dest': 'PROPOSAL_DEV1_NEITHER',
        'before': 'store_dev2_proposal',
    },
    {
        'trigger': 'reject_markers',
        'source': 'PROPOSAL_DEV2_NEITHER',
        'dest': 'REJECTED',
    },
    {
        'trigger': 'reject_blind',
        'source': 'PROPOSAL_DEV2_NEITHER',
        'dest': 'BLIND_REJECTED',
    },

    # From PROPOSAL_DEV1_DEV2_APPROVED: dev1 can complete or counter-propose
    {
        'trigger': 'dev1_approve',
        'source': 'PROPOSAL_DEV1_DEV2_APPROVED',
        'dest': 'FILE_COMPLETE',
        'before': 'set_dev1_approval',
    },
    {
        'trigger': 'dev1_propose',
        'source': 'PROPOSAL_DEV1_DEV2_APPROVED',
        'dest': 'PROPOSAL_DEV2_NEITHER',
        'before': 'store_dev1_proposal',
    },
    {
        'trigger': 'reject_markers',
        'source': 'PROPOSAL_DEV1_DEV2_APPROVED',
        'dest': 'REJECTED',
    },
    {
        'trigger': 'reject_blind',
        'source': 'PROPOSAL_DEV1_DEV2_APPROVED',
        'dest': 'BLIND_REJECTED',
    },

    # From PROPOSAL_DEV1_NEITHER: dev1 can approve or counter-propose
    {
        'trigger': 'dev1_approve',
        'source': 'PROPOSAL_DEV1_NEITHER',
        'dest': 'PROPOSAL_DEV2_DEV1_APPROVED',
        'before': 'set_dev1_approval',
    },
    {
        'trigger': 'dev1_propose',
        'source': 'PROPOSAL_DEV1_NEITHER',
        'dest': 'PROPOSAL_DEV2_NEITHER',
        'before': 'store_dev1_proposal',
    },
    {
        'trigger': 'reject_markers',
        'source': 'PROPOSAL_DEV1_NEITHER',
        'dest': 'REJECTED',
    },
    {
        'trigger': 'reject_blind',
        'source': 'PROPOSAL_DEV1_NEITHER',
        'dest': 'BLIND_REJECTED',
    },

    # From PROPOSAL_DEV2_DEV1_APPROVED: dev2 can complete or counter-propose
    {
        'trigger': 'dev2_approve',
        'source': 'PROPOSAL_DEV2_DEV1_APPROVED',
        'dest': 'FILE_COMPLETE',
        'before': 'set_dev2_approval',
    },
    {
        'trigger': 'dev2_propose',
        'source': 'PROPOSAL_DEV2_DEV1_APPROVED',
        'dest': 'PROPOSAL_DEV1_NEITHER',
        'before': 'store_dev2_proposal',
    },
    {
        'trigger': 'reject_markers',
        'source': 'PROPOSAL_DEV2_DEV1_APPROVED',
        'dest': 'REJECTED',
    },
    {
        'trigger': 'reject_blind',
        'source': 'PROPOSAL_DEV2_DEV1_APPROVED',
        'dest': 'BLIND_REJECTED',
    },

    # From FILE_COMPLETE: auto-advance to CHECK_REMAINING
    {
        'trigger': 'file_resolved',
        'source': 'FILE_COMPLETE',
        'dest': 'CHECK_REMAINING',
        'before': 'apply_and_advance',
    },

    # From REJECTED: fix staging and retry
    {
        'trigger': 'fix_markers',
        'source': 'REJECTED',
        'dest': 'NO_PROPOSAL_DEV1',
    },

    # From BLIND_REJECTED: view staging and return to proposal state
    {
        'trigger': 'fix_blind_dev2',
        'source': 'BLIND_REJECTED',
        'dest': 'PROPOSAL_DEV2_NEITHER',
    },
    {
        'trigger': 'fix_blind_dev1',
        'source': 'BLIND_REJECTED',
        'dest': 'PROPOSAL_DEV1_NEITHER',
    },
]


# =============================================================================
# MODEL - holds the data
# =============================================================================

class FileMergeModel:
    """
    Model that holds file-level merge data.
    The Machine attaches state and triggers to this model.
    """

    def __init__(self):
        # ALL FILES to process - list of filepath strings
        self.all_files: List[str] = []
        self.file_index: int = 0
        self.current_file: Optional[str] = None

        # Timestamp for staleness check - when did current file start
        self.file_started_at: float = 0.0

        # Seen tracking - single flag per agent, reset per file
        # Must run "ralph merge show" before proposing/approving
        self.dev1_has_seen: bool = False
        self.dev2_has_seen: bool = False

        # Timestamp when each agent last ran 'show' - staging must be newer
        self.dev1_last_show_at: float = 0.0
        self.dev2_last_show_at: float = 0.0

        # Proposal data
        self.proposal_comment: Optional[str] = None
        self.proposed_by: Optional[str] = None

        # Approval tracking
        self.dev1_approved: bool = False
        self.dev2_approved: bool = False

        # Agent identity (set by load_model)
        self.agent: Optional[str] = None

        # State is managed by Machine, but we track it for persistence
        # (Machine will set self.state)

    # -------------------------------------------------------------------------
    # Callbacks: on_enter_<state> - auto-discovered by transitions
    # -------------------------------------------------------------------------

    def on_enter_CHECK_REMAINING(self, event=None):
        """Loop controller - are there more files to process?

        Checks each file to see if it has clean staging (no conflict markers).
        If a file needs processing, triggers has_more.
        If all files resolved, triggers no_more.
        """
        for i, filepath in enumerate(self.all_files):
            if self._is_file_resolved(filepath):
                continue

            # This file needs processing
            self.file_index = i
            self.current_file = filepath
            print(f"\n>>> File {i + 1}/{len(self.all_files)}: {filepath}")
            self.has_more()
            return

        # All files resolved
        self.no_more()

    def _is_file_resolved(self, filepath: str) -> bool:
        """Check if file has clean staging (no conflict markers)."""
        staging_path = get_staging_path(filepath)
        if not staging_path.exists():
            return False
        content = staging_path.read_text()
        has_conflicts = '<<<<<<<' in content or '=======' in content or '>>>>>>>' in content
        return not has_conflicts

    def on_enter_CHECKING_FILE(self, event=None):
        """Check if current file needs merge or is identical.

        Compares dev1 and dev2 versions:
        - Identical → auto-stage and continue
        - Different → enter proposal workflow
        """
        # Reset state for new file
        self._reset_for_new_file()

        # Compare dev1 and dev2 versions
        versions = get_file_versions(self.current_file)
        dev1_content = versions.get('dev1', '')
        dev2_content = versions.get('dev2', '')

        if dev1_content == dev2_content:
            # File is identical - auto-stage
            self.is_identical()
        else:
            # File differs - needs merge
            self.needs_merge()

    def _reset_for_new_file(self):
        """Reset all per-file state."""
        self.file_started_at = time.time()
        self.dev1_has_seen = False
        self.dev2_has_seen = False
        self.dev1_last_show_at = 0.0
        self.dev2_last_show_at = 0.0
        self.proposal_comment = None
        self.proposed_by = None
        self.dev1_approved = False
        self.dev2_approved = False

    def on_enter_NO_PROPOSAL_DEV1(self, event=None):
        """Clear proposal state for fresh start."""
        self.proposal_comment = None
        self.proposed_by = None
        self.dev1_approved = False
        self.dev2_approved = False

    def on_enter_PROPOSAL_DEV2_NEITHER(self, event=None):
        """Dev2's turn starts - reset staging seen for new proposal."""
        pass  # Seen flags already reset in store_proposal

    def on_enter_PROPOSAL_DEV1_DEV2_APPROVED(self, event=None):
        """Dev1's turn - dev2 has approved."""
        pass

    def on_enter_PROPOSAL_DEV1_NEITHER(self, event=None):
        """Dev1's turn - neither approved (counter-proposal made)."""
        pass

    def on_enter_PROPOSAL_DEV2_DEV1_APPROVED(self, event=None):
        """Dev2's turn - dev1 has approved."""
        pass

    def on_enter_FILE_COMPLETE(self, event=None):
        """Both approved - apply the proposal and advance."""
        if not self.dev1_approved or not self.dev2_approved:
            raise RuntimeError(
                f"FILE_COMPLETE reached without both approvals! "
                f"dev1={self.dev1_approved}, dev2={self.dev2_approved}"
            )

        total_files = len(self.all_files)
        print(f"Both approved! File {self.file_index + 1}/{total_files}: {self.current_file}")

        # Trigger advancement
        self.file_resolved()

    def on_enter_DONE(self, event=None):
        """All files resolved."""
        print("All files resolved! Run: ralph merge finalize")

    def on_enter_REJECTED(self, event=None):
        """Staging has conflict markers."""
        print("ERROR: Staging file contains conflict markers!")
        print("Write RESOLVED code without <<<<<<<, =======, or >>>>>>> markers.")

    def on_enter_BLIND_REJECTED(self, event=None):
        """Agent tried to approve without seeing staging."""
        print("ERROR: You must view the proposal before approving.")
        print("Run 'ralph merge show staging' first.")

    # -------------------------------------------------------------------------
    # Callbacks: registered in TRANSITIONS
    # -------------------------------------------------------------------------

    def store_dev1_proposal(self, event):
        """Store proposal from dev1."""
        self._store_proposal(event, 'dev1')

    def store_dev2_proposal(self, event):
        """Store proposal from dev2."""
        self._store_proposal(event, 'dev2')

    def _store_proposal(self, event, agent: str):
        """Common proposal storage logic.

        CRITICAL: Proposing RESETS ALL approvals per spec.
        """
        comment = event.kwargs.get('comment', '')

        if not comment or not comment.strip():
            raise ValueError("Proposal comment cannot be empty")

        self.proposal_comment = comment.strip()
        self.proposed_by = agent

        # RESET ALL APPROVALS - new proposal needs fresh consensus
        self.dev1_approved = False
        self.dev2_approved = False

        # RESET OTHER AGENT'S has_seen - they must run 'show' to see new proposal
        if agent == "dev1":
            self.dev2_has_seen = False
        else:
            self.dev1_has_seen = False

    def set_dev1_approval(self, event=None):
        """Set dev1's approval flag."""
        self.dev1_approved = True

    def set_dev2_approval(self, event=None):
        """Set dev2's approval flag."""
        self.dev2_approved = True

    def stage_identical_and_advance(self, event=None):
        """Auto-stage identical file content."""
        print(f"✅ {self.current_file} - identical content, auto-staged")

        versions = get_file_versions(self.current_file)
        content = versions.get('dev1', '')
        if content:
            staging_path = get_staging_path(self.current_file)
            staging_path.parent.mkdir(parents=True, exist_ok=True)
            staging_path.write_text(content)

    def apply_and_advance(self, event=None):
        """Apply staging and advance to next file.

        Staging already contains the agreed proposal (agent wrote it before proposing).
        """
        pass  # Staging is already in place

    # -------------------------------------------------------------------------
    # Helpers: seen tracking
    # -------------------------------------------------------------------------

    def has_seen(self, agent: str) -> bool:
        """Check if agent has run 'show' for this file."""
        if agent == "dev1":
            return self.dev1_has_seen
        else:
            return self.dev2_has_seen

    def mark_seen(self, agent: str):
        """Mark that agent has run 'show' for this file and record timestamp."""
        if agent == "dev1":
            self.dev1_has_seen = True
            self.dev1_last_show_at = time.time()
        else:
            self.dev2_has_seen = True
            self.dev2_last_show_at = time.time()

    # -------------------------------------------------------------------------
    # Helpers: turn and actions
    # -------------------------------------------------------------------------

    def get_turn(self) -> Optional[str]:
        """Get whose turn it is based on current state."""
        state = getattr(self, 'state', 'INIT')
        turn_map = {
            'INIT': 'dev1',  # dev1 starts
            'CHECK_REMAINING': None,  # Transient
            'CHECKING_FILE': None,  # Transient
            'NO_PROPOSAL_DEV1': 'dev1',
            'PROPOSAL_DEV2_NEITHER': 'dev2',
            'PROPOSAL_DEV1_DEV2_APPROVED': 'dev1',
            'PROPOSAL_DEV1_NEITHER': 'dev1',
            'PROPOSAL_DEV2_DEV1_APPROVED': 'dev2',
            'FILE_COMPLETE': None,  # Transient
            'DONE': None,
            'REJECTED': self.proposed_by if self.proposed_by else 'dev1',
            'BLIND_REJECTED': 'dev2' if self.proposed_by == 'dev1' else 'dev1',
        }
        return turn_map.get(state)

    def get_actions(self) -> List[str]:
        """Get ALL valid actions for current state."""
        state = getattr(self, 'state', 'INIT')

        actions_map = {
            'INIT': ["ralph merge start"],
            'CHECK_REMAINING': [],
            'CHECKING_FILE': [],
            'NO_PROPOSAL_DEV1': [
                "ralph merge propose '<filepath>' '<comment>'"
            ],
            'PROPOSAL_DEV2_NEITHER': [
                "ralph merge approve",
                "ralph merge propose '<filepath>' '<counter-comment>'",
            ],
            'PROPOSAL_DEV1_DEV2_APPROVED': [
                "ralph merge approve",
                "ralph merge propose '<filepath>' '<counter-comment>'",
            ],
            'PROPOSAL_DEV1_NEITHER': [
                "ralph merge approve",
                "ralph merge propose '<filepath>' '<counter-comment>'",
            ],
            'PROPOSAL_DEV2_DEV1_APPROVED': [
                "ralph merge approve",
                "ralph merge propose '<filepath>' '<counter-comment>'",
            ],
            'FILE_COMPLETE': [],
            'DONE': ["ralph merge finalize"],
            'REJECTED': ["Fix staging file, then: ralph merge propose '<filepath>' '<comment>'"],
            'BLIND_REJECTED': ["ralph merge show staging"],
        }
        return actions_map.get(state, [])

    def is_my_turn(self) -> bool:
        """Check if it's this agent's turn."""
        turn = self.get_turn()
        if turn is None:
            return True  # Transient states
        return turn == self.agent

    # -------------------------------------------------------------------------
    # Serialization
    # -------------------------------------------------------------------------

    def to_dict(self) -> dict:
        """Serialize model to dict for persistence."""
        return {
            'state': self.state,
            'all_files': self.all_files,
            'file_index': self.file_index,
            'current_file': self.current_file,
            'file_started_at': self.file_started_at,
            'dev1_has_seen': self.dev1_has_seen,
            'dev2_has_seen': self.dev2_has_seen,
            'dev1_last_show_at': self.dev1_last_show_at,
            'dev2_last_show_at': self.dev2_last_show_at,
            'proposal_comment': self.proposal_comment,
            'proposed_by': self.proposed_by,
            'dev1_approved': self.dev1_approved,
            'dev2_approved': self.dev2_approved,
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'FileMergeModel':
        """Deserialize model from dict."""
        model = cls()
        model.all_files = data.get('all_files', [])
        model.file_index = data.get('file_index', 0)
        model.current_file = data.get('current_file')
        model.file_started_at = data.get('file_started_at', 0.0)
        model.dev1_has_seen = data.get('dev1_has_seen', False)
        model.dev2_has_seen = data.get('dev2_has_seen', False)
        model.dev1_last_show_at = data.get('dev1_last_show_at', 0.0)
        model.dev2_last_show_at = data.get('dev2_last_show_at', 0.0)
        model.proposal_comment = data.get('proposal_comment')
        model.proposed_by = data.get('proposed_by')
        model.dev1_approved = data.get('dev1_approved', False)
        model.dev2_approved = data.get('dev2_approved', False)
        return model


# =============================================================================
# MACHINE FACTORY
# =============================================================================

def create_machine(model: FileMergeModel, initial_state: str) -> Machine:
    """Create a state machine attached to the given model."""
    machine = Machine(
        model=model,
        states=STATES,
        transitions=TRANSITIONS,
        initial=initial_state,
        send_event=True,
        auto_transitions=False,
    )
    return machine


# =============================================================================
# PERSISTENCE
# =============================================================================

def get_state_file() -> Path:
    """Get path to state file."""
    from merge_state import get_base_branch_from_git
    branch = get_base_branch_from_git().replace("/", "-")
    return Path.home() / ".claude" / "coordination" / f"file-merge-state-{branch}.json"


def save_model(model: FileMergeModel):
    """Save model to disk."""
    state_file = get_state_file()
    state_file.parent.mkdir(parents=True, exist_ok=True)
    with open(state_file, "w") as f:
        json.dump(model.to_dict(), f, indent=2)


def load_model() -> FileMergeModel:
    """Load model from disk, or create new if not exists."""
    from merge_state import get_agent
    state_file = get_state_file()

    if state_file.exists():
        with open(state_file) as f:
            data = json.load(f)
        model = FileMergeModel.from_dict(data)
        initial_state = data.get('state', 'INIT')
    else:
        model = FileMergeModel()
        initial_state = 'INIT'

    # Attach machine at the correct state
    create_machine(model, initial_state=initial_state)

    # Set agent identity
    model.agent = get_agent()

    return model


# =============================================================================
# HELPERS
# =============================================================================

def get_file_versions(filepath: str) -> dict:
    """Get base, dev1, dev2 content for a file."""
    from merge_git import get_branch_info

    current, base, other = get_branch_info()

    # Fetch latest
    subprocess.run(["git", "fetch", "origin"], capture_output=True)

    # Get merge base
    result = subprocess.run(
        ["git", "merge-base", f"origin/{base}-dev1", f"origin/{base}-dev2"],
        capture_output=True, text=True
    )
    merge_base = result.stdout.strip()

    # Get file contents
    base_content = subprocess.run(
        ["git", "show", f"{merge_base}:{filepath}"],
        capture_output=True, text=True
    ).stdout

    dev1_content = subprocess.run(
        ["git", "show", f"origin/{base}-dev1:{filepath}"],
        capture_output=True, text=True
    ).stdout

    dev2_content = subprocess.run(
        ["git", "show", f"origin/{base}-dev2:{filepath}"],
        capture_output=True, text=True
    ).stdout

    return {
        "base": base_content,
        "dev1": dev1_content,
        "dev2": dev2_content,
        "merge_base_ref": merge_base,
    }


def get_staging_path(filepath: str) -> Path:
    """Get staging path for a file."""
    return STAGING_DIR / filepath


def get_conflicting_files() -> List[str]:
    """Get list of files that differ between dev1 and dev2."""
    from merge_git import get_branch_info

    current, base, other = get_branch_info()

    # Fetch latest
    subprocess.run(["git", "fetch", "origin"], capture_output=True)

    # Get files that differ between dev1 and dev2
    result = subprocess.run(
        ["git", "diff", "--name-only", f"origin/{base}-dev1", f"origin/{base}-dev2"],
        capture_output=True, text=True
    )

    files = [f.strip() for f in result.stdout.strip().split("\n") if f.strip()]
    return files
