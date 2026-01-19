#!/bin/bash
# Ensures all required Codespace ports are forwarded
# Run this whenever you get "Network request failed" errors
#
# Usage: ./ensure-ports.sh [codespace-name]
#        ./ensure-ports.sh  # auto-detects active codespace

set -e

# Ports required for SparkPos development
REQUIRED_PORTS="54321 8080 8081"

# Get codespace name
if [ -n "$1" ]; then
  CODESPACE="$1"
else
  # Auto-detect running codespace
  CODESPACE=$(gh codespace list --json name,state -q '.[] | select(.state=="Available") | .name' | head -1)
  if [ -z "$CODESPACE" ]; then
    echo "Error: No active codespace found. Specify one: ./ensure-ports.sh <codespace-name>"
    exit 1
  fi
fi

echo "Codespace: $CODESPACE"
echo "Checking port forwarding..."

# Check which ports need forwarding
MISSING_PORTS=""
for PORT in $REQUIRED_PORTS; do
  if ! lsof -i:$PORT 2>/dev/null | grep -q LISTEN; then
    MISSING_PORTS="$MISSING_PORTS $PORT:$PORT"
    echo "  Port $PORT: NOT forwarded"
  else
    echo "  Port $PORT: OK"
  fi
done

if [ -z "$MISSING_PORTS" ]; then
  echo ""
  echo "✓ All ports are already forwarded!"
  exit 0
fi

echo ""
echo "Starting port forwarding for:$MISSING_PORTS"

# Start port forwarding in background with nohup to survive shell closure
nohup gh codespace ports forward $MISSING_PORTS -c "$CODESPACE" > /tmp/gh-ports-forward.log 2>&1 &
FORWARD_PID=$!

# Wait for ports to come up
sleep 5

# Verify ports are now forwarded
ALL_OK=true
for PORT in $REQUIRED_PORTS; do
  if ! lsof -i:$PORT 2>/dev/null | grep -q LISTEN; then
    echo "WARNING: Port $PORT still not forwarded"
    ALL_OK=false
  fi
done

if [ "$ALL_OK" = true ]; then
  echo ""
  echo "✓ All ports forwarded successfully (PID: $FORWARD_PID)"
  echo ""
  echo "Ports:"
  echo "  54321 → Supabase API"
  echo "  8080  → PowerSync"
  echo "  8081  → Metro"
  echo ""
  echo "Log: /tmp/gh-ports-forward.log"
else
  echo ""
  echo "Some ports failed. Log:"
  cat /tmp/gh-ports-forward.log
  exit 1
fi
