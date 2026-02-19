#!/bin/bash
# ralph-count.sh - Count tasks for an agent in a plan file
# Usage: ralph-count.sh <agent> <plan_file>
# Returns two lines: checked_count, unchecked_count

agent="${1:-all}"
plan_file="$2"

if [[ ! -f "$plan_file" ]]; then
    echo "0"
    echo "0"
    exit 0
fi

if [[ "$agent" == "all" ]]; then
    grep -c '^\s*- \[x\]' "$plan_file" 2>/dev/null || echo "0"
    grep -c '^\s*- \[ \]' "$plan_file" 2>/dev/null || echo "0"
    exit 0
fi

# Team mode - count tasks in agent's sections
# Uses awk to track which sections belong to which agent
awk -v agent="$agent" '
BEGIN { in_section = 1; checked = 0; unchecked = 0 }
/<!-- agent:/ {
    gsub(/.*<!-- agent: */, "")
    gsub(/ *-->.*/, "")
    gsub(/[[:space:]]/, "")
    section_agent = $0
    in_section = (section_agent == agent || section_agent == "" || section_agent == "all")
    next
}
in_section && /^[[:space:]]*- \[x\]/ { checked++ }
in_section && /^[[:space:]]*- \[ \]/ { unchecked++ }
END {
    print checked
    print unchecked
}
' "$plan_file"
