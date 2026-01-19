#!/bin/bash
# Usage: ./connect-metro.sh [codespace-name]
# Connects local Mac to Codespace Metro for React Native development

set -e

# Get codespace name from arg or current environment
if [ -n "$1" ]; then
  CODESPACE="$1"
elif [ -f ~/.spark-env-current ]; then
  CODESPACE=$(grep "^CODESPACE_NAME=" ~/.spark-env-current 2>/dev/null | cut -d= -f2)
fi

if [ -z "$CODESPACE" ]; then
  # Try to find the most recent spark codespace
  CODESPACE=$(gh codespace list --json name,displayName -q '.[] | select(.displayName | startswith("spark-")) | .name' | head -1)
fi

if [ -z "$CODESPACE" ]; then
  echo "Error: No codespace specified and none found"
  echo "Usage: ./connect-metro.sh <codespace-name>"
  exit 1
fi

echo "=== Connecting to Codespace: $CODESPACE ==="

# Step 1: Kill any existing port forward
echo "[1/4] Stopping existing port forwards..."
pkill -f "spark-tunnel" 2>/dev/null || true
pkill -f "gh codespace ports forward" 2>/dev/null || true

# Step 2: Start port forwarding in background
echo "[2/4] Starting port forwarding (3000, 8081)..."
TUNNEL_SCRIPT="/tmp/spark-tunnel-$CODESPACE.sh"
cat > "$TUNNEL_SCRIPT" << TUNNEL
#!/bin/bash
while true; do
  gh codespace ports forward 8081:8081 3000:3000 54321:54321 -c "$CODESPACE" 2>&1
  sleep 2
done
TUNNEL
chmod +x "$TUNNEL_SCRIPT"
nohup "$TUNNEL_SCRIPT" > /tmp/spark-tunnel.log 2>&1 &
echo $! > /tmp/spark-tunnel.pid
sleep 2

# Step 3: Set up adb reverse for emulator
echo "[3/5] Setting up adb reverse..."
if adb devices | grep -q "emulator"; then
  adb reverse tcp:8081 tcp:8081
  adb reverse tcp:3000 tcp:3000
  adb reverse tcp:54321 tcp:54321
  echo "  adb reverse configured (Metro, Rails, Supabase)"
else
  echo "  No emulator detected - skipping adb reverse"
fi

# Step 4: Kill any background Metro so we can run interactively
echo "[4/5] Killing background Metro..."
gh codespace ssh -c "$CODESPACE" -- "pkill -9 -f 'react-native start' 2>/dev/null; pkill -9 -f 'node.*8081' 2>/dev/null; exit 0" 2>/dev/null || true
sleep 3

# Step 5: Open Metro in new terminal window (terminal-agnostic)
echo "[5/5] Opening Metro in new terminal window..."
METRO_CMD="gh codespace ssh -c $CODESPACE -- -t 'cd /workspaces/spark-agent-tools/sparkpos && npm start -- --port 8081'"

if [ "$TERM_PROGRAM" = "iTerm.app" ]; then
  osascript -e "tell application \"iTerm\"
    activate
    set newWindow to (create window with default profile)
    tell current session of newWindow
      write text \"$METRO_CMD\"
    end tell
  end tell"
elif [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
  osascript -e "tell application \"Terminal\" to do script \"$METRO_CMD\""
else
  # Fallback: create a temp script and open with default terminal
  METRO_SCRIPT="/tmp/spark-metro-$$.sh"
  echo "#!/bin/bash" > "$METRO_SCRIPT"
  echo "$METRO_CMD" >> "$METRO_SCRIPT"
  chmod +x "$METRO_SCRIPT"
  open -a Terminal "$METRO_SCRIPT"
fi

# Wait for Metro and open DevTools
echo "Waiting for Metro to start..."
for i in {1..30}; do
  if curl -s http://localhost:8081/json | grep -q "devtoolsFrontendUrl" 2>/dev/null; then
    echo "Metro ready!"
    sleep 2
    DEVTOOLS_PATH=$(curl -s http://localhost:8081/json | jq -r '.[0].devtoolsFrontendUrl // empty')
    if [ -n "$DEVTOOLS_PATH" ]; then
      open "http://localhost:8081$DEVTOOLS_PATH"
      echo "DevTools opened!"
    fi
    break
  fi
  sleep 2
done

echo ""
echo "============================================"
echo "  CONNECTION READY"
echo "============================================"
echo ""
echo "Port forwarding active (PID: $(cat /tmp/spark-tunnel.pid))"
echo "Metro running in separate Terminal window."
echo ""
echo "  R - reload app"
echo "  D - dev menu"
echo "  J - reopen DevTools"
echo ""
echo "DevTools: open \"http://localhost:8081\$(curl -s http://localhost:8081/json | jq -r '.[0].devtoolsFrontendUrl')\""
echo ""
echo "To stop: kill \$(cat /tmp/spark-tunnel.pid)"
