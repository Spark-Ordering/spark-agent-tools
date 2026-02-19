#!/bin/bash
# ralph-split.sh - Automatically split tasks between dev1 and dev2
#
# Usage:
#   ralph-split.sh <plan_file>
#
# Splits uncategorized sections alternately between dev1 and dev2.
# Preserves existing agent markers. Adds markers before ## headers.

plan_file="${1:-}"

if [[ -z "$plan_file" ]] || [[ ! -f "$plan_file" ]]; then
    echo "Usage: ralph-split.sh <plan_file>" >&2
    exit 1
fi

# Create backup
cp "$plan_file" "${plan_file}.bak"

# Use awk to process the file
awk '
BEGIN {
    agent_index = 0
    agents[0] = "dev1"
    agents[1] = "dev2"
    current_agent = ""
    pending_marker = ""
}

# If we see an existing agent marker, remember it
/<!-- agent:/ {
    # Extract agent name
    gsub(/.*<!-- agent: */, "")
    gsub(/ *-->.*/, "")
    current_agent = $0
    print
    next
}

# Section headers (##) - assign agent if not already assigned
/^##[^#]/ {
    # Check if previous line was an agent marker (within last 2 lines)
    if (current_agent == "") {
        # No agent assigned yet, assign one
        print "<!-- agent: " agents[agent_index % 2] " -->"
        agent_index++
    }
    current_agent = ""  # Reset for next section
    print
    next
}

# Everything else: just print
{ print }
' "$plan_file" > "${plan_file}.tmp"

mv "${plan_file}.tmp" "$plan_file"

# Count tasks per agent
dev1_tasks=$("$SCRIPT_DIR/ralph-count.sh" dev1 "$plan_file" | tail -1)
dev2_tasks=$("$SCRIPT_DIR/ralph-count.sh" dev2 "$plan_file" | tail -1)

echo "Split complete:"
echo "  dev1: $dev1_tasks unchecked tasks"
echo "  dev2: $dev2_tasks unchecked tasks"
