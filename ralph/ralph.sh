#!/bin/bash
# ralph.sh - Ralph Wiggum autonomous loop for Claude Code
#
# Usage:
#   ralph.sh PROMPT.md              # Run until <done/> marker found
#   ralph.sh PROMPT.md 20           # Max 20 iterations
#   ralph.sh --plan PLAN.md         # Auto-generate prompt from plan file
#
# The prompt file should end with instructions like:
#   "When ALL tasks are complete, output: <done/>"

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

COMPLETION_MARKER="<done/>"
MAX_ITERATIONS=200
PROMPT_FILE=""
PLAN_MODE=false

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --plan)
            PLAN_MODE=true
            PLAN_FILE="$2"
            shift 2
            ;;
        --max)
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        *)
            if [[ -z "$PROMPT_FILE" ]]; then
                PROMPT_FILE="$1"
            else
                MAX_ITERATIONS="$1"
            fi
            shift
            ;;
    esac
done

# Generate prompt from plan file
if [[ "$PLAN_MODE" == true ]]; then
    if [[ ! -f "$PLAN_FILE" ]]; then
        echo -e "${RED}Plan file not found: $PLAN_FILE${NC}"
        exit 1
    fi

    PROMPT_FILE="/tmp/ralph-prompt-$$.md"
    cat > "$PROMPT_FILE" << 'PROMPT_TEMPLATE'
# Autonomous Task Execution

## Instructions
1. Read the plan file below
2. Find the NEXT unchecked task (marked with `- [ ]`)
3. Complete it fully, including any verification steps (like POS checks)
4. Update the plan file to mark it done (change `- [ ]` to `- [x]`)
5. **BEFORE moving to the next task**: Check if you saw any error (snackbar, log box, console error, etc.)
   - If YES: Add a bug fix task to the plan and address it NOW before other tasks
   - Do NOT proceed to unrelated tasks while a visible error exists from your recent work
6. Move to the next task immediately - NO stopping for confirmation
7. Repeat until ALL tasks are checked

## Completion Signal
When ALL tasks in the plan are complete (no more `- [ ]` remaining), output exactly:
<done/>

## Plan File
PROMPT_TEMPLATE

    echo "Path: $PLAN_FILE" >> "$PROMPT_FILE"
    echo '```markdown' >> "$PROMPT_FILE"
    cat "$PLAN_FILE" >> "$PROMPT_FILE"
    echo '```' >> "$PROMPT_FILE"

    echo -e "${CYAN}Generated prompt from plan: $PLAN_FILE${NC}"
fi

if [[ -z "$PROMPT_FILE" ]] || [[ ! -f "$PROMPT_FILE" ]]; then
    echo -e "${RED}Usage: ralph.sh PROMPT.md [max_iterations]${NC}"
    echo -e "${RED}   or: ralph.sh --plan PLAN.md${NC}"
    exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔄 RALPH WIGGUM LOOP${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Prompt: ${YELLOW}$PROMPT_FILE${NC}"
echo -e "Max iterations: ${YELLOW}$MAX_ITERATIONS${NC}"
echo -e "Completion marker: ${YELLOW}$COMPLETION_MARKER${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

iteration=0
while [[ $iteration -lt $MAX_ITERATIONS ]]; do
    iteration=$((iteration + 1))

    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  ITERATION $iteration / $MAX_ITERATIONS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    # Run claude with the prompt, capture output
    # Using --print to get output without interactive mode
    output=$(cat "$PROMPT_FILE" | claude --print 2>&1) || true

    echo "$output"
    echo ""

    # Check for completion marker
    if echo "$output" | grep -q "$COMPLETION_MARKER"; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ TASK COMPLETE - Found completion marker${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        # Cleanup temp file if we created it
        [[ "$PLAN_MODE" == true ]] && rm -f "$PROMPT_FILE"
        exit 0
    fi

    echo -e "${YELLOW}⏳ Completion marker not found, continuing...${NC}"
    sleep 2
done

echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}⚠️  MAX ITERATIONS REACHED ($MAX_ITERATIONS)${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

[[ "$PLAN_MODE" == true ]] && rm -f "$PROMPT_FILE"
exit 1
