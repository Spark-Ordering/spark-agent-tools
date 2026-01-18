#!/bin/bash
# Usage: ./teardown-env.sh [codespace-name]
# Cleans up Codespace, port forwarding tunnel, and config files

if [ -z "$1" ]; then
  if [ -L ~/.spark-env-current ]; then
    CODESPACE=$(grep "^CODESPACE_NAME=" ~/.spark-env-current 2>/dev/null | cut -d= -f2)
  fi

  if [ -z "$CODESPACE" ]; then
    echo "Usage: ./teardown-env.sh <codespace-name>"
    echo "Or switch to an environment first with ./switch-env.sh"
    exit 1
  fi

  echo "No codespace specified, using current: $CODESPACE"
else
  CODESPACE=$1
fi

echo "Deleting Codespace: $CODESPACE"
read -p "Are you sure? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Kill port forwarding tunnel if running
  if [ -f /tmp/spark-tunnel.pid ]; then
    TUNNEL_PID=$(cat /tmp/spark-tunnel.pid)
    if ps -p "$TUNNEL_PID" > /dev/null 2>&1; then
      echo "Stopping port forwarding tunnel (PID: $TUNNEL_PID)..."
      kill "$TUNNEL_PID" 2>/dev/null
    fi
    rm -f /tmp/spark-tunnel.pid
  fi
  rm -f /tmp/spark-tunnel-*.sh /tmp/spark-tunnel.log

  # Delete the Codespace
  gh codespace delete -c "$CODESPACE" -f

  # Clean up config files (both old and new locations)
  rm -f ~/.spark-env-"$CODESPACE"
  rm -f ~/.spark-envs/"$CODESPACE"

  # If this was the current environment, remove the symlink
  if [ -L ~/.spark-env-current ]; then
    CURRENT_TARGET=$(readlink ~/.spark-env-current)
    if [[ "$CURRENT_TARGET" == *"$CODESPACE"* ]]; then
      rm -f ~/.spark-env-current
    fi
  fi

  echo "Deleted: $CODESPACE"
else
  echo "Cancelled"
fi
