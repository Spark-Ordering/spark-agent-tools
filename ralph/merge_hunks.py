#!/usr/bin/env python3
"""
Hunk-by-hunk merge resolution.

Parses git diffs into individual hunks and manages collaborative resolution
where both agents build the merged file together, one hunk at a time.
"""

import os
import re
import subprocess
from pathlib import Path
from typing import List, Dict, Optional, Tuple

STAGING_DIR = Path.home() / ".claude" / "merge-staging"


def get_branch_info() -> Tuple[str, str, str]:
    """Get current branch, base branch, and other agent's branch."""
    current = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True, text=True
    ).stdout.strip()
    base = current.replace("-dev1", "").replace("-dev2", "")
    other = f"{base}-dev2" if current.endswith("-dev1") else f"{base}-dev1"
    return current, base, other


def parse_hunks(diff_text: str) -> List[Dict]:
    """
    Parse a unified diff into individual hunks.

    Returns list of dicts with:
    - header: The @@ line
    - old_start, old_count: Lines in original file
    - new_start, new_count: Lines in new file
    - content: The actual diff lines (-, +, context)
    - raw: Full hunk text including header
    """
    hunks = []

    # Split by hunk headers
    hunk_pattern = r'(@@ -(\d+),?(\d*) \+(\d+),?(\d*) @@.*?)(?=@@ -|\Z)'
    matches = re.findall(hunk_pattern, diff_text, re.DOTALL)

    for match in matches:
        header_line = match[0].split('\n')[0]
        content_lines = '\n'.join(match[0].split('\n')[1:])

        hunks.append({
            'header': header_line,
            'old_start': int(match[1]),
            'old_count': int(match[2]) if match[2] else 1,
            'new_start': int(match[3]),
            'new_count': int(match[4]) if match[4] else 1,
            'content': content_lines,
            'raw': match[0]
        })

    return hunks


def get_file_hunks(filepath: str) -> Dict:
    """
    Get hunks for a file from both branches.

    Returns dict with:
    - dev1_hunks: List of hunks from dev1's changes
    - dev2_hunks: List of hunks from dev2's changes
    - base_content: Content at merge base
    - dev1_content: Content in dev1's branch
    - dev2_content: Content in dev2's branch
    """
    current, base, other = get_branch_info()

    # Fetch latest
    subprocess.run(["git", "fetch", "origin"], capture_output=True)

    # Get merge base
    result = subprocess.run(
        ["git", "merge-base", f"origin/{base}-dev1", f"origin/{base}-dev2"],
        capture_output=True, text=True
    )
    merge_base = result.stdout.strip()

    # Get diffs from merge base to each branch
    dev1_diff = subprocess.run(
        ["git", "diff", merge_base, f"origin/{base}-dev1", "--", filepath],
        capture_output=True, text=True
    ).stdout

    dev2_diff = subprocess.run(
        ["git", "diff", merge_base, f"origin/{base}-dev2", "--", filepath],
        capture_output=True, text=True
    ).stdout

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
        'filepath': filepath,
        'dev1_hunks': parse_hunks(dev1_diff),
        'dev2_hunks': parse_hunks(dev2_diff),
        'base_content': base_content,
        'dev1_content': dev1_content,
        'dev2_content': dev2_content,
        'dev1_diff': dev1_diff,
        'dev2_diff': dev2_diff
    }


def get_overlapping_hunks(file_info: Dict) -> List[Dict]:
    """
    Find hunks that overlap between dev1 and dev2 (actual conflicts).

    Returns list of overlapping regions with hunks from both sides.
    """
    dev1_hunks = file_info['dev1_hunks']
    dev2_hunks = file_info['dev2_hunks']

    overlaps = []

    for h1 in dev1_hunks:
        h1_start = h1['old_start']
        h1_end = h1_start + h1['old_count']

        for h2 in dev2_hunks:
            h2_start = h2['old_start']
            h2_end = h2_start + h2['old_count']

            # Check if ranges overlap
            if h1_start < h2_end and h2_start < h1_end:
                overlaps.append({
                    'dev1_hunk': h1,
                    'dev2_hunk': h2,
                    'overlap_start': max(h1_start, h2_start),
                    'overlap_end': min(h1_end, h2_end)
                })

    return overlaps


def get_all_hunks_unified(file_info: Dict) -> List[Dict]:
    """
    Get all hunks from both branches, sorted by line number.
    Marks whether each hunk is dev1-only, dev2-only, or overlapping.

    This gives us a sequential list to work through.
    """
    dev1_hunks = file_info['dev1_hunks']
    dev2_hunks = file_info['dev2_hunks']
    overlaps = get_overlapping_hunks(file_info)

    # Track which hunks are part of overlaps
    dev1_overlap_indices = set()
    dev2_overlap_indices = set()

    for i, h1 in enumerate(dev1_hunks):
        for overlap in overlaps:
            if overlap['dev1_hunk'] == h1:
                dev1_overlap_indices.add(i)

    for i, h2 in enumerate(dev2_hunks):
        for overlap in overlaps:
            if overlap['dev2_hunk'] == h2:
                dev2_overlap_indices.add(i)

    unified = []

    # Add overlapping hunks (conflicts - need discussion)
    for overlap in overlaps:
        unified.append({
            'type': 'conflict',
            'dev1_hunk': overlap['dev1_hunk'],
            'dev2_hunk': overlap['dev2_hunk'],
            'line_start': overlap['overlap_start']
        })

    # Add dev1-only hunks
    for i, h in enumerate(dev1_hunks):
        if i not in dev1_overlap_indices:
            unified.append({
                'type': 'dev1_only',
                'dev1_hunk': h,
                'dev2_hunk': None,
                'line_start': h['old_start']
            })

    # Add dev2-only hunks
    for i, h in enumerate(dev2_hunks):
        if i not in dev2_overlap_indices:
            unified.append({
                'type': 'dev2_only',
                'dev1_hunk': None,
                'dev2_hunk': h,
                'line_start': h['old_start']
            })

    # Sort by line number
    unified.sort(key=lambda x: x['line_start'])

    return unified


def init_staging(filepath: str, base_content: str):
    """Initialize staging file with base content."""
    staging_path = STAGING_DIR / filepath
    staging_path.parent.mkdir(parents=True, exist_ok=True)
    staging_path.write_text(base_content)


def get_staging_path(filepath: str) -> Path:
    """Get path to staging file."""
    return STAGING_DIR / filepath


def read_staging(filepath: str) -> str:
    """Read current staging file content."""
    staging_path = STAGING_DIR / filepath
    if staging_path.exists():
        return staging_path.read_text()
    return ""


def write_staging(filepath: str, content: str):
    """Write content to staging file."""
    staging_path = STAGING_DIR / filepath
    staging_path.parent.mkdir(parents=True, exist_ok=True)
    staging_path.write_text(content)


def apply_staging_to_repo(filepath: str):
    """Copy staging file to actual repo location."""
    staging_path = STAGING_DIR / filepath
    if not staging_path.exists():
        raise FileNotFoundError(f"No staging file for {filepath}")

    # Read staging content
    content = staging_path.read_text()

    # Write to actual file
    Path(filepath).parent.mkdir(parents=True, exist_ok=True)
    Path(filepath).write_text(content)

    # Stage for commit
    subprocess.run(["git", "add", filepath])


def clear_staging():
    """Remove all staging files."""
    import shutil
    if STAGING_DIR.exists():
        shutil.rmtree(STAGING_DIR)


def format_hunk_for_display(hunk: Dict, agent: str) -> str:
    """Format a hunk for display to agents."""
    if not hunk:
        return "(no changes)"

    lines = []
    lines.append(f"=== {agent}'s changes ===")
    lines.append(f"Lines {hunk['old_start']}-{hunk['old_start'] + hunk['old_count']}")
    lines.append(hunk['header'])
    lines.append(hunk['content'])
    return '\n'.join(lines)


def format_conflict_for_display(unified_hunk: Dict) -> str:
    """Format a conflict hunk showing both sides."""
    lines = []
    lines.append("=" * 60)
    lines.append(f"CONFLICT at lines {unified_hunk['line_start']}")
    lines.append("=" * 60)
    lines.append("")
    lines.append(format_hunk_for_display(unified_hunk['dev1_hunk'], 'dev1'))
    lines.append("")
    lines.append(format_hunk_for_display(unified_hunk['dev2_hunk'], 'dev2'))
    lines.append("")
    lines.append("=" * 60)
    lines.append("INSTRUCTIONS:")
    lines.append("1. Discuss what the resolution should be")
    lines.append("2. One agent writes the resolved code: ralph merge write-hunk")
    lines.append("3. Other agent reviews and approves: ralph merge approve-hunk")
    lines.append("=" * 60)
    return '\n'.join(lines)


def count_unresolved_hunks_in_staging(filepath: str) -> int:
    """
    Count how many hunks in the staging file are still unresolved.

    A hunk is "resolved" if the staging file's content for that region
    differs from the base content (i.e., someone wrote merged content).

    A hunk is "unresolved" if the staging file still matches the base
    for that region (i.e., no merge work done yet).

    Returns the count of unresolved hunks.
    """
    staging_path = get_staging_path(filepath)
    if not staging_path.exists():
        # No staging file = can't count, return -1 to signal error
        return -1

    staging_content = staging_path.read_text()
    staging_lines = staging_content.splitlines()

    # Get base content and hunks from git
    file_info = get_file_hunks(filepath)
    base_lines = file_info['base_content'].splitlines()
    unified_hunks = get_all_hunks_unified(file_info)

    if not unified_hunks:
        return 0

    unresolved = 0
    for hunk in unified_hunks:
        # Get the line range this hunk affects (1-indexed in git, convert to 0-indexed)
        start = hunk['line_start'] - 1

        # Determine how many lines this hunk spans in the original (base) file
        if hunk['type'] == 'conflict':
            # Use the larger of the two hunk sizes
            dev1_count = hunk['dev1_hunk']['old_count'] if hunk['dev1_hunk'] else 0
            dev2_count = hunk['dev2_hunk']['old_count'] if hunk['dev2_hunk'] else 0
            span = max(dev1_count, dev2_count)
        else:
            # dev1_only or dev2_only
            h = hunk['dev1_hunk'] or hunk['dev2_hunk']
            span = h['old_count'] if h else 0

        end = start + span

        # Safely extract regions (handle out of bounds)
        base_region = base_lines[start:end] if start < len(base_lines) else []
        staging_region = staging_lines[start:end] if start < len(staging_lines) else []

        # If staging matches base for this region, hunk is unresolved
        if staging_region == base_region:
            unresolved += 1

    return unresolved
