#!/usr/bin/env python3
"""
Deterministic hunk state machine using the `transitions` library.

ARCHITECTURE:
- HunkModel: holds data (filepath, proposal, approvals, etc.)
- Machine: manages state transitions, callbacks do all the work
- CLI commands just trigger events on the machine

STATES:
- INIT: Starting state - call begin() to start the workflow
- CHECK_REMAINING: Loop controller - checks if more files/hunks remain
- CHECKING_FILE: Checks if current file is identical or has hunks
- NO_PROPOSAL_DEV1: No proposal exists, dev1's turn to propose
- PROPOSAL_DEV2_NEITHER: Proposal exists, dev2's turn, neither approved
- PROPOSAL_DEV1_DEV2_APPROVED: Proposal exists, dev1's turn, dev2 approved
- PROPOSAL_DEV1_NEITHER: Proposal exists, dev1's turn, neither approved
- PROPOSAL_DEV2_DEV1_APPROVED: Proposal exists, dev2's turn, dev1 approved
- RESOLVE_HUNK: Both approved, apply proposal and advance
- DONE: All files resolved

TRIGGERS:
- has_more: More files/hunks remain
- no_more: No more files/hunks
- has_hunks: Current file has hunks to resolve
- is_identical: Current file is identical (auto-stage)
- dev1_propose: dev1 proposes (requires filepath, comment)
- dev2_propose: dev2 counter-proposes
- dev1_approve: dev1 approves current proposal
- dev2_approve: dev2 approves current proposal
- hunk_resolved: Hunk was resolved, advance to CHECK_REMAINING
"""

import json
import time
from pathlib import Path
from typing import Optional
from transitions import Machine, State

from merge_hunks import get_staging_path, get_file_hunks, get_all_hunks_unified, count_unresolved_hunks_in_staging


# =============================================================================
# STATES
# =============================================================================

STATES = [
    State(name='INIT'),             # Starting state - call begin() to start the workflow
    State(name='CHECK_REMAINING'),  # Loop controller - checks if more files/hunks remain
    State(name='CHECKING_FILE'),    # Checks if current file is identical or has hunks
    State(name='NO_PROPOSAL_DEV1'),
    State(name='PROPOSAL_DEV2_NEITHER'),
    State(name='PROPOSAL_DEV1_DEV2_APPROVED'),
    State(name='PROPOSAL_DEV1_NEITHER'),
    State(name='PROPOSAL_DEV2_DEV1_APPROVED'),
    State(name='RESOLVE_HUNK'),     # Apply proposal and advance (renamed from COMPLETE)
    State(name='DONE', final=True),
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
        'trigger': 'has_hunks',
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

    # From PROPOSAL_DEV1_DEV2_APPROVED: dev1 can complete or counter-propose
    {
        'trigger': 'dev1_approve',
        'source': 'PROPOSAL_DEV1_DEV2_APPROVED',
        'dest': 'RESOLVE_HUNK',
        'before': 'set_dev1_approval',
    },
    {
        'trigger': 'dev1_propose',
        'source': 'PROPOSAL_DEV1_DEV2_APPROVED',
        'dest': 'PROPOSAL_DEV2_NEITHER',
        'before': 'store_dev1_proposal',
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

    # From PROPOSAL_DEV2_DEV1_APPROVED: dev2 can complete or counter-propose
    {
        'trigger': 'dev2_approve',
        'source': 'PROPOSAL_DEV2_DEV1_APPROVED',
        'dest': 'RESOLVE_HUNK',
        'before': 'set_dev2_approval',
    },
    {
        'trigger': 'dev2_propose',
        'source': 'PROPOSAL_DEV2_DEV1_APPROVED',
        'dest': 'PROPOSAL_DEV1_NEITHER',
        'before': 'store_dev2_proposal',
    },

    # From RESOLVE_HUNK: apply proposal and go to CHECK_REMAINING
    {
        'trigger': 'hunk_resolved',
        'source': 'RESOLVE_HUNK',
        'dest': 'CHECK_REMAINING',
        'before': 'apply_and_advance',
    },
]


# =============================================================================
# MODEL - holds the data
# =============================================================================

class HunkModel:
    """
    Model that holds hunk review data.
    The Machine attaches state and triggers to this model.
    """

    def __init__(self):
        # ALL FILES to process - list of filepath strings
        self.all_files: list = []
        self.file_index: int = 0

        # Current hunk info (derived from all_files[file_index])
        self.filepath: Optional[str] = None
        self.hunk_index: int = 0
        self.total_hunks: int = 0

        # Proposal data
        self.proposal: Optional[str] = None
        self.proposal_comment: Optional[str] = None
        self.proposed_by: Optional[str] = None

        # APPROVAL TRACKING - explicit flags per agent
        # These MUST be reset when counter-proposing
        self.dev1_approved: bool = False
        self.dev2_approved: bool = False

        # SEEN TRACKING - which agents have viewed the current proposal
        # Must run 'ralph merge show' before approving
        self.proposal_seen_by: list = []

        # This agent's identity
        self.agent: Optional[str] = None

        # Turn tracking - when did current turn start (Unix timestamp)
        # Used to verify staging files were written AFTER turn started
        self.turn_started_at: float = time.time()

        # State is managed by Machine, but we track it for persistence
        # (Machine will set self.state)

    # -------------------------------------------------------------------------
    # Callbacks: on_enter_<state> - auto-discovered by transitions
    # -------------------------------------------------------------------------

    def on_enter_NO_PROPOSAL_DEV1(self, event=None):
        """Clear proposal and approvals when entering initial state."""
        self.proposal = None
        self.proposal_comment = None
        self.proposed_by = None
        self.dev1_approved = False
        self.dev2_approved = False
        self.proposal_seen_by = []
        self.turn_started_at = time.time()

    def on_enter_PROPOSAL_DEV2_NEITHER(self, event=None):
        """Dev2's turn starts."""
        self.turn_started_at = time.time()

    def on_enter_PROPOSAL_DEV1_DEV2_APPROVED(self, event=None):
        """Dev1's turn starts."""
        self.turn_started_at = time.time()

    def on_enter_PROPOSAL_DEV1_NEITHER(self, event=None):
        """Dev1's turn starts."""
        self.turn_started_at = time.time()

    def on_enter_PROPOSAL_DEV2_DEV1_APPROVED(self, event=None):
        """Dev2's turn starts."""
        self.turn_started_at = time.time()

    def on_enter_CHECK_REMAINING(self, event=None):
        """Loop controller - are all files in staging with clean content?

        YES → DONE
        NO → CHECKING_FILE for the first incomplete file
        """
        for i, filepath in enumerate(self.all_files):
            if self._is_file_resolved(filepath):
                continue

            # This file needs processing
            self.file_index = i
            self.filepath = filepath
            self.hunk_index = 0
            print(f"\n>>> File {i + 1}/{len(self.all_files)}: {filepath}")
            self.has_more()
            return

        # All files in staging with clean content
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
        """Analyze current file via git - is it identical or does it have hunks?

        Git analysis determines:
        - 0 hunks → identical between branches → auto-stage
        - >0 hunks → has conflicts → enter proposal workflow
        """
        # Clear proposal state for new file/hunk
        self.proposal = None
        self.proposal_comment = None
        self.proposed_by = None
        self.dev1_approved = False
        self.dev2_approved = False
        self.proposal_seen_by = []

        # Git analysis - compare branches to find overlapping hunks
        file_info = get_file_hunks(self.filepath)
        unified_hunks = get_all_hunks_unified(file_info)
        self.total_hunks = len(unified_hunks)

        if self.total_hunks == 0:
            # File is identical between branches - auto-stage
            self.is_identical()
        else:
            # File has overlapping hunks - enter proposal workflow
            print(f"    {self.total_hunks} hunks remaining")
            self.has_hunks()

    def on_enter_RESOLVE_HUNK(self, event=None):
        """Both approved - apply the proposal and trigger advancement."""
        # VERIFY both agents actually approved
        if not self.dev1_approved or not self.dev2_approved:
            raise RuntimeError(
                f"RESOLVE_HUNK reached without both approvals! "
                f"dev1={self.dev1_approved}, dev2={self.dev2_approved}"
            )

        total_files = len(self.all_files) if self.all_files else 1
        print(f"Both approved! File {self.file_index + 1}/{total_files}: {self.filepath} - hunk resolved ({self.total_hunks - 1} remaining)")

        # Trigger the transition to CHECK_REMAINING
        self.hunk_resolved()


    def on_enter_DONE(self, event=None):
        """All hunks complete."""
        print("All hunks resolved! Run: ralph merge finalize")

    # -------------------------------------------------------------------------
    # Callbacks: registered in TRANSITIONS
    # -------------------------------------------------------------------------

    def store_dev1_proposal(self, event):
        """Store proposal from dev1."""
        self._store_proposal(event, 'dev1')

    def store_dev2_proposal(self, event):
        """Store proposal from dev2."""
        self._store_proposal(event, 'dev2')

    def set_dev1_approval(self, event=None):
        """Set dev1's approval flag."""
        self.dev1_approved = True

    def set_dev2_approval(self, event=None):
        """Set dev2's approval flag."""
        self.dev2_approved = True

    def _store_proposal(self, event, agent: str):
        """
        Common proposal storage logic.

        CRITICAL: Proposing RESETS ALL approvals per spec.
        "Proposing resets ALL approvals - new proposal needs fresh consensus"

        VALIDATION: Proposal must resolve exactly ONE hunk at a time.
        If staged file resolves more than one hunk, reject the proposal.
        """
        code = event.kwargs.get('code')
        comment = event.kwargs.get('comment')

        if not code or not code.strip():
            raise ValueError("Proposal code cannot be empty")
        if not comment or not comment.strip():
            raise ValueError("Proposal comment cannot be empty")

        # VALIDATE: Check that proposal resolves exactly ONE hunk
        # Compare staging file content against base to count unresolved hunks
        if self.total_hunks > 1:
            unresolved = count_unresolved_hunks_in_staging(self.filepath)
            if unresolved >= 0:  # -1 means staging file doesn't exist
                # After this proposal, we should have (total - 1) unresolved hunks
                # i.e., exactly ONE hunk should be resolved
                expected_unresolved = self.total_hunks - 1
                if unresolved < expected_unresolved:
                    hunks_resolved = self.total_hunks - unresolved
                    raise ValueError(
                        f"Proposal resolves {hunks_resolved} hunks at once (expected 1). "
                        f"Total hunks: {self.total_hunks}, unresolved in staging: {unresolved}. "
                        f"Please resolve ONE hunk at a time."
                    )

        self.proposal = code.strip()
        self.proposal_comment = comment.strip()
        self.proposed_by = agent

        # RESET ALL APPROVALS - new proposal needs fresh consensus
        self.dev1_approved = False
        self.dev2_approved = False

        # RESET SEEN TRACKING - new proposal must be viewed before approving
        self.proposal_seen_by = []

    def stage_identical_and_advance(self, event=None):
        """Auto-stage identical file content to staging directory."""
        print(f"✅ {self.filepath} - identical content, auto-staged")

        # Get the file content and stage it
        file_info = get_file_hunks(self.filepath)
        content = file_info.get('dev1_content', '')
        if content:
            staging_path = get_staging_path(self.filepath)
            staging_path.parent.mkdir(parents=True, exist_ok=True)
            staging_path.write_text(content)

    def apply_and_advance(self, event=None):
        """No-op - staging already contains the agreed proposal.

        Agent writes resolved code to staging before calling propose.
        Finalize will copy staging files to repo.
        """
        pass

    # -------------------------------------------------------------------------
    # Helpers: whose turn based on state
    # -------------------------------------------------------------------------

    def get_turn(self) -> str:
        """Get whose turn it is based on current state."""
        state = getattr(self, 'state', 'INIT')
        turn_map = {
            'INIT': None,             # Starting state
            'CHECK_REMAINING': None,  # Transient state
            'CHECKING_FILE': None,    # Transient state
            'NO_PROPOSAL_DEV1': 'dev1',
            'PROPOSAL_DEV2_NEITHER': 'dev2',
            'PROPOSAL_DEV1_DEV2_APPROVED': 'dev1',
            'PROPOSAL_DEV1_NEITHER': 'dev1',
            'PROPOSAL_DEV2_DEV1_APPROVED': 'dev2',
            'RESOLVE_HUNK': None,     # Transient state
            'DONE': None,
        }
        return turn_map.get(state, 'dev1')

    def get_actions(self) -> list:
        """
        Get ALL valid actions for current state.

        Based on mermaid diagram - each state with multiple outgoing
        transitions must present ALL options.
        """
        state = getattr(self, 'state', 'CHECK_REMAINING')

        # Map each state to ALL its valid outgoing transitions
        actions_map = {
            # Transient states - no user action
            'INIT': [],
            'CHECK_REMAINING': [],
            'CHECKING_FILE': [],
            'RESOLVE_HUNK': [],
            # Only propose - nothing to approve yet
            'NO_PROPOSAL_DEV1': [
                "ralph merge propose '<file>' '<comment>'"
            ],
            # Can approve OR counter-propose
            'PROPOSAL_DEV2_NEITHER': [
                "ralph merge approve",
                "ralph merge propose '<file>' '<counter-comment>'",
            ],
            # Can approve (completes) OR counter-propose (resets)
            'PROPOSAL_DEV1_DEV2_APPROVED': [
                "ralph merge approve",
                "ralph merge propose '<file>' '<counter-comment>'",
            ],
            # Can approve OR counter-propose
            'PROPOSAL_DEV1_NEITHER': [
                "ralph merge approve",
                "ralph merge propose '<file>' '<counter-comment>'",
            ],
            # Can approve (completes) OR counter-propose (resets)
            'PROPOSAL_DEV2_DEV1_APPROVED': [
                "ralph merge approve",
                "ralph merge propose '<file>' '<counter-comment>'",
            ],
            'DONE': ["ralph merge finalize"],
        }
        return actions_map.get(state, [])

    def is_my_turn(self) -> bool:
        """Check if it's this agent's turn."""
        return self.get_turn() == self.agent

    def mark_seen(self, agent: str):
        """Mark that an agent has seen the current proposal."""
        if agent not in self.proposal_seen_by:
            self.proposal_seen_by.append(agent)

    def has_seen_proposal(self, agent: str) -> bool:
        """Check if an agent has seen the current proposal."""
        return agent in self.proposal_seen_by

    # -------------------------------------------------------------------------
    # Serialization
    # -------------------------------------------------------------------------

    def to_dict(self) -> dict:
        """Serialize model to dict for persistence."""
        return {
            'state': self.state,
            'all_files': self.all_files,
            'file_index': self.file_index,
            'filepath': self.filepath,
            'hunk_index': self.hunk_index,
            'total_hunks': self.total_hunks,
            'proposal': self.proposal,
            'proposal_comment': self.proposal_comment,
            'proposed_by': self.proposed_by,
            'dev1_approved': self.dev1_approved,
            'dev2_approved': self.dev2_approved,
            'proposal_seen_by': self.proposal_seen_by,
            'turn_started_at': self.turn_started_at,
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'HunkModel':
        """Deserialize model from dict."""
        model = cls()
        model.all_files = data.get('all_files', [])
        model.file_index = data.get('file_index', 0)
        model.filepath = data.get('filepath')
        model.hunk_index = data.get('hunk_index', 0)
        model.total_hunks = data.get('total_hunks', 0)
        model.proposal = data.get('proposal')
        model.proposal_comment = data.get('proposal_comment')
        model.proposed_by = data.get('proposed_by')
        model.dev1_approved = data.get('dev1_approved', False)
        model.dev2_approved = data.get('dev2_approved', False)
        model.proposal_seen_by = data.get('proposal_seen_by', [])
        model.turn_started_at = data.get('turn_started_at', time.time())
        # Note: state is set by Machine after creation
        return model


# =============================================================================
# MACHINE FACTORY
# =============================================================================

def create_machine(model: HunkModel, initial_state: str) -> Machine:
    """
    Create a state machine attached to the given model.

    Args:
        model: HunkModel instance to attach machine to
        initial_state: Starting state (for restoring from persistence)

    Returns:
        Machine instance
    """
    machine = Machine(
        model=model,
        states=STATES,
        transitions=TRANSITIONS,
        initial=initial_state,
        send_event=True,  # Pass EventData to callbacks
        auto_transitions=False,  # Don't auto-generate to_STATE methods
    )
    return machine


# =============================================================================
# PERSISTENCE
# =============================================================================

def get_state_file() -> Path:
    """Get path to hunk state file."""
    from merge_state import get_base_branch_from_git
    branch = get_base_branch_from_git().replace("/", "-")
    return Path.home() / ".claude" / "coordination" / f"hunk-state-{branch}.json"


def save_model(model: HunkModel):
    """Persist model state to disk."""
    state_file = get_state_file()
    state_file.parent.mkdir(parents=True, exist_ok=True)
    with open(state_file, 'w') as f:
        json.dump(model.to_dict(), f, indent=2)


def load_model() -> HunkModel:
    """Load model state from disk, or create new if not exists."""
    state_file = get_state_file()

    if state_file.exists():
        with open(state_file) as f:
            data = json.load(f)
        model = HunkModel.from_dict(data)
        initial_state = data['state']
    else:
        model = HunkModel()
        initial_state = 'INIT'

    # Attach machine at the correct state
    create_machine(model, initial_state=initial_state)

    # Set agent identity
    from merge_state import get_agent
    model.agent = get_agent()

    return model


# =============================================================================
# DISPLAY
# =============================================================================

def format_state_display(model: HunkModel) -> str:
    """
    Format the state for display.

    Shows:
    - Header with HUNK and STATE
    - Proposal (if exists)
    - YOUR ACTION or WAITING (never both)
    """
    lines = []

    # Header
    lines.append("=" * 59)
    if model.filepath:
        lines.append(f"FILE: {model.filepath} ({model.total_hunks} hunks remaining)")
    else:
        lines.append("FILE: (none)")
    lines.append(f"STATE: {model.state}")
    lines.append("=" * 59)
    lines.append("")

    # Show proposal if exists
    if model.proposal:
        lines.append(f"PROPOSAL by {model.proposed_by}:")
        lines.append("```")
        lines.append(model.proposal)
        lines.append("```")

        if model.proposal_comment:
            lines.append(f"\nCOMMENT: \"{model.proposal_comment}\"")
        lines.append("")

    # Action or waiting - NEVER BOTH
    lines.append("-" * 59)
    if model.state == 'DONE':
        lines.append("ALL HUNKS RESOLVED")
        lines.append("YOUR ACTION: ralph merge finalize")
    elif model.is_my_turn():
        actions = model.get_actions()
        if len(actions) == 1:
            lines.append(f"YOUR ACTION: {actions[0]}")
        elif len(actions) > 1:
            lines.append("YOUR OPTIONS:")
            for i, action in enumerate(actions, 1):
                lines.append(f"  {i}. {action}")

        # ADVOCACY INSTRUCTIONS - show when reviewing other agent's proposal
        if model.proposal and model.proposed_by != model.agent:
            lines.append("")
            lines.append("⚠️  ADVOCACY CHECK:")
            lines.append(f"   You are {model.agent}. This proposal is from {model.proposed_by}.")
            lines.append("   ADVOCATE for your branch's work. If your files/exports are being")
            lines.append("   excluded, COUNTER-PROPOSE. Don't approve deletion of your own work.")
    else:
        turn = model.get_turn()
        if turn:
            lines.append(f"WAITING: {turn}'s turn.")
        else:
            lines.append("COMPLETE: Both approved.")
    lines.append("-" * 59)

    return "\n".join(lines)
