#!/bin/bash
# ralph-agent.sh - Single source of truth for agent identity
#
# Usage:
#   source ralph-agent.sh
#   echo $RALPH_AGENT  # "dev1" or "dev2" or "unknown"
#
# Detection order:
#   1. ~/.claude/agent-identity file (explicit config, most reliable)
#   2. RALPH_AGENT environment variable
#   3. ~/.claude/.ralph-mode flag (if contains agent:path format)
#   4. Hostname-based detection (fallback)
#
# To set explicitly: echo "dev1" > ~/.claude/agent-identity

RALPH_AGENT_CONFIG="$HOME/.claude/agent-identity"
RALPH_FLAG="$HOME/.claude/.ralph-mode"

detect_agent_from_hostname() {
    local host=$(hostname)
    case "$host" in
        # MacBook Air patterns (dev1 / team lead)
        MacBook-Air*)      echo "dev1" ;;
        *macbook-air*)     echo "dev1" ;;
        Mac.attlocal*)     echo "dev1" ;;
        Mac.local*)        echo "dev1" ;;
        Mac)               echo "dev1" ;;

        # MacBook Pro patterns (dev2 / remote agent)
        *MacBook-Pro*)     echo "dev2" ;;
        *macbook-pro*)     echo "dev2" ;;
        Carloss-MacBook*)  echo "dev2" ;;

        # Unknown - require explicit config
        *)                 echo "unknown" ;;
    esac
}

get_ralph_agent() {
    # Priority 1: Explicit config file (most reliable)
    if [[ -f "$RALPH_AGENT_CONFIG" ]] && [[ -s "$RALPH_AGENT_CONFIG" ]]; then
        local config_agent=$(cat "$RALPH_AGENT_CONFIG" | tr -d '[:space:]')
        if [[ "$config_agent" == "dev1" || "$config_agent" == "dev2" ]]; then
            echo "$config_agent"
            return
        fi
    fi

    # Priority 2: Environment variable
    if [[ -n "$RALPH_AGENT" ]] && [[ "$RALPH_AGENT" != "unknown" ]]; then
        echo "$RALPH_AGENT"
        return
    fi

    # Priority 3: Ralph mode flag (agent:path format)
    if [[ -f "$RALPH_FLAG" ]] && [[ -s "$RALPH_FLAG" ]]; then
        local content=$(cat "$RALPH_FLAG")
        if [[ "$content" == *":"* ]]; then
            local flag_agent="${content%%:*}"
            if [[ "$flag_agent" == "dev1" || "$flag_agent" == "dev2" ]]; then
                echo "$flag_agent"
                return
            fi
        elif [[ "$content" == "dev1" || "$content" == "dev2" ]]; then
            echo "$content"
            return
        fi
    fi

    # Priority 4: Hostname detection (fallback)
    detect_agent_from_hostname
}

# Set the agent if this script is sourced
RALPH_AGENT=$(get_ralph_agent)
export RALPH_AGENT
