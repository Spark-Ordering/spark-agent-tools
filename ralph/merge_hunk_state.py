#!/usr/bin/env python3
"""
Deterministic hunk state machine using the `transitions` library.

ARCHITECTURE:
- HunkModel: holds data (filepath, proposal, approvals, etc.)
- Machine: manages state transitions, callbacks do all the work
- CLI commands just trigger events on the machine

STATES:
- NO_PROPOSAL_DEV1: No proposal exists, dev1's turn to propose
- PROPOSAL_DEV2_NEITHER: Proposal exists, dev2's turn, neither approved
- PROPOSAL_DEV1_DEV2_APPROVED: Proposal exists, dev1's turn, dev2 approved
- PROPOSAL_DEV1_NEITHER: Proposal exists, dev1's turn, neither approved
- PROPOSAL_DEV2_DEV1_APPROVED: Proposal exists, dev2's turn, dev1 approved
- COMPLETE: Both approved, advance to next hunk

TRIGGERS:
- dev1_propose: dev1 proposes (requires filepath, comment)
- dev2_propose: dev2 counter-proposes
- dev1_approve: dev1 approves current proposal
- dev2_approve: dev2 approves current proposal
"""

import json
import time
from pathlib import Path
from typing import Optional
from transitions import Machine, State


# =============================================================================
# STATES
# =============================================================================

STATES = [
    State(name='NO_PROPOSAL_DEV1'),
    State(name='PROPOSAL_DEV2_NEITHER'),
    State(name='PROPOSAL_DEV1_DEV2_APPROVED'),
    State(name='PROPOSAL_DEV1_NEITHER'),
    State(name='PROPOSAL_DEV2_DEV1_APPROVED'),
    State(name='COMPLETE'),
    State(name='DONE', final=True),
]


# =============================================================================
# TRANSITIONS
# =============================================================================

TRANSITIONS = [
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
        'dest': 'COMPLETE',
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
        'dest': 'COMPLETE',
        'before': 'set_dev2_approval',
    },
    {
        'trigger': 'dev2_propose',
        'source': 'PROPOSAL_DEV2_DEV1_APPROVED',
        'dest': 'PROPOSAL_DEV1_NEITHER',
        'before': 'store_dev2_proposal',
    },

    # From COMPLETE: auto-advance to next hunk or finalize
    {
        'trigger': 'advance_hunk',
        'source': 'COMPLETE',
        'dest': 'NO_PROPOSAL_DEV1',
        'before': 'setup_next_hunk',
    },
    {
        'trigger': 'all_done',
        'source': 'COMPLETE',
        'dest': 'DONE',
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
        # Current hunk info
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

    def on_enter_COMPLETE(self, event=None):
        """Both approved - APPLY the proposal to the file, then advance."""
        # VERIFY both agents actually approved
        if not self.dev1_approved or not self.dev2_approved:
            raise RuntimeError(
                f"COMPLETE reached without both approvals! "
                f"dev1={self.dev1_approved}, dev2={self.dev2_approved}"
            )

        print(f"Both approved! Hunk {self.hunk_index + 1}/{self.total_hunks} resolved.")

        # CRITICAL: Apply the agreed proposal to the actual conflict file
        if self.proposal and self.filepath:
            self._apply_proposal_to_file()

        # Auto-trigger next transition
        if self.hunk_index + 1 < self.total_hunks:
            self.advance_hunk()
        else:
            self.all_done()

    def _apply_proposal_to_file(self):
        """Write the agreed proposal to resolve the conflict in the actual file."""
        from pathlib import Path
        import subprocess

        # Get the conflicted file path
        repo_root = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True
        ).stdout.strip()

        conflict_file = Path(repo_root) / self.filepath

        if not conflict_file.exists():
            print(f"ERROR: Conflict file not found: {conflict_file}")
            return

        # Read current content with conflict markers
        content = conflict_file.read_text()

        # Find and replace the conflict block with the proposal
        # Conflict markers look like:
        # <<<<<<< HEAD
        # ... dev1 changes ...
        # =======
        # ... dev2 changes ...
        # >>>>>>> branch

        import re
        conflict_pattern = r'<<<<<<<[^\n]*\n.*?=======\n.*?>>>>>>>[^\n]*\n?'

        # Replace the FIRST conflict with the proposal
        # (We handle one hunk at a time)
        new_content, count = re.subn(
            conflict_pattern,
            self.proposal + '\n',
            content,
            count=1,
            flags=re.DOTALL
        )

        if count == 0:
            print(f"WARNING: No conflict markers found in {self.filepath}")
            print("The file may have already been resolved or has different format.")
            return

        # Write the resolved content
        conflict_file.write_text(new_content)
        print(f"✓ Applied proposal to {self.filepath}")

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
        """
        code = event.kwargs.get('code')
        comment = event.kwargs.get('comment')

        if not code or not code.strip():
            raise ValueError("Proposal code cannot be empty")
        if not comment or not comment.strip():
            raise ValueError("Proposal comment cannot be empty")

        self.proposal = code.strip()
        self.proposal_comment = comment.strip()
        self.proposed_by = agent

        # RESET ALL APPROVALS - new proposal needs fresh consensus
        self.dev1_approved = False
        self.dev2_approved = False

    def setup_next_hunk(self, event=None):
        """Advance to next hunk, clear proposal and approvals."""
        self.hunk_index += 1
        self.proposal = None
        self.proposal_comment = None
        self.proposed_by = None
        self.dev1_approved = False
        self.dev2_approved = False

    # -------------------------------------------------------------------------
    # Helpers: whose turn based on state
    # -------------------------------------------------------------------------

    def get_turn(self) -> str:
        """Get whose turn it is based on current state."""
        state = getattr(self, 'state', 'NO_PROPOSAL_DEV1')
        turn_map = {
            'NO_PROPOSAL_DEV1': 'dev1',
            'PROPOSAL_DEV2_NEITHER': 'dev2',
            'PROPOSAL_DEV1_DEV2_APPROVED': 'dev1',
            'PROPOSAL_DEV1_NEITHER': 'dev1',
            'PROPOSAL_DEV2_DEV1_APPROVED': 'dev2',
            'COMPLETE': None,
            'DONE': None,
        }
        return turn_map.get(state, 'dev1')

    def get_actions(self) -> list:
        """
        Get ALL valid actions for current state.

        Based on mermaid diagram - each state with multiple outgoing
        transitions must present ALL options.
        """
        state = getattr(self, 'state', 'NO_PROPOSAL_DEV1')

        # Map each state to ALL its valid outgoing transitions
        actions_map = {
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
            'COMPLETE': [],
            'DONE': ["ralph merge finalize"],
        }
        return actions_map.get(state, [])

    def is_my_turn(self) -> bool:
        """Check if it's this agent's turn."""
        return self.get_turn() == self.agent

    # -------------------------------------------------------------------------
    # Serialization
    # -------------------------------------------------------------------------

    def to_dict(self) -> dict:
        """Serialize model to dict for persistence."""
        return {
            'state': getattr(self, 'state', 'NO_PROPOSAL_DEV1'),
            'filepath': self.filepath,
            'hunk_index': self.hunk_index,
            'total_hunks': self.total_hunks,
            'proposal': self.proposal,
            'proposal_comment': self.proposal_comment,
            'proposed_by': self.proposed_by,
            'dev1_approved': self.dev1_approved,
            'dev2_approved': self.dev2_approved,
            'turn_started_at': self.turn_started_at,
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'HunkModel':
        """Deserialize model from dict."""
        model = cls()
        model.filepath = data.get('filepath')
        model.hunk_index = data.get('hunk_index', 0)
        model.total_hunks = data.get('total_hunks', 0)
        model.proposal = data.get('proposal')
        model.proposal_comment = data.get('proposal_comment')
        model.proposed_by = data.get('proposed_by')
        model.dev1_approved = data.get('dev1_approved', False)
        model.dev2_approved = data.get('dev2_approved', False)
        model.turn_started_at = data.get('turn_started_at', time.time())
        # Note: state is set by Machine after creation
        return model


# =============================================================================
# MACHINE FACTORY
# =============================================================================

def create_machine(model: HunkModel, initial_state: str = 'NO_PROPOSAL_DEV1') -> Machine:
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
        initial_state = data.get('state', 'NO_PROPOSAL_DEV1')
    else:
        model = HunkModel()
        initial_state = 'NO_PROPOSAL_DEV1'

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
        lines.append(f"HUNK: {model.filepath} ({model.hunk_index + 1}/{model.total_hunks})")
    else:
        lines.append("HUNK: (none)")
    lines.append(f"STATE: {model.state}")
    lines.append("=" * 59)
    lines.append("")

    # Show proposal if exists
    if model.proposal:
        lines.append(f"PROPOSAL by {model.proposed_by}:")
        lines.append("```")
        proposal_text = model.proposal
        if len(proposal_text) > 2000:
            proposal_text = proposal_text[:2000] + "\n... (truncated)"
        lines.append(proposal_text)
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
    else:
        turn = model.get_turn()
        if turn:
            lines.append(f"WAITING: {turn}'s turn.")
        else:
            lines.append("COMPLETE: Both approved.")
    lines.append("-" * 59)

    return "\n".join(lines)
