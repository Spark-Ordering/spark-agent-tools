#!/bin/bash
# Usage: ./spawn-env.sh [branch-name] [--sparkpos <branch>]
# Fully automated: creates Codespace, waits for services, sets up port forwarding
#
# Examples:
#   ./spawn-env.sh                              # master branch, SparkPos master
#   ./spawn-env.sh --sparkpos add-logout-button # master branch, SparkPos add-logout-button
#   ./spawn-env.sh feature-x --sparkpos my-feat # feature-x branch, SparkPos my-feat

set -e

# Parse arguments
BRANCH="master"
SPARKPOS_BRANCH="master"

while [[ $# -gt 0 ]]; do
  case $1 in
    --sparkpos)
      SPARKPOS_BRANCH="$2"
      shift 2
      ;;
    *)
      BRANCH="$1"
      shift
      ;;
  esac
done

REPO="Spark-Ordering/spark-agent-tools"
ENV_NAME="spark-${BRANCH}"

echo "=== Spark Environment Spawner ==="
echo "Branch: $BRANCH"
if [ "$SPARKPOS_BRANCH" != "master" ]; then
  echo "SparkPos Branch: $SPARKPOS_BRANCH"
fi
echo ""

# Step 1: Create Codespace with 16GB RAM
echo "[1/5] Creating Codespace (16GB RAM)..."
CODESPACE=$(gh codespace create \
  --repo "$REPO" \
  --branch "$BRANCH" \
  --machine standardLinux32gb \
  --display-name "$ENV_NAME" \
  2>&1 | tee /dev/stderr | tail -1)

if [ -z "$CODESPACE" ]; then
  echo "Error: Failed to find Codespace"
  exit 1
fi

echo "Codespace: $CODESPACE"

# Step 2: Run setup via SSH
echo ""
echo "[2/5] Running setup (SparkPos branch: $SPARKPOS_BRANCH)..."
GH_PAT=$(cat ~/.github_codespace_pat 2>/dev/null || echo "")
if [ -z "$GH_PAT" ]; then
  echo "ERROR: No GitHub PAT found at ~/.github_codespace_pat"
  echo "Please create a GitHub Personal Access Token and save it to ~/.github_codespace_pat"
  exit 1
fi
gh codespace ssh -c "$CODESPACE" -- "cd /workspaces/spark-agent-tools && export GH_TOKEN='$GH_PAT' && .devcontainer/setup.sh $SPARKPOS_BRANCH"
echo "Setup complete!"

# Step 3: Start services
echo ""
echo "[3/5] Starting services..."
gh codespace ssh -c "$CODESPACE" -- "cd /workspaces/spark-agent-tools && .devcontainer/start-all.sh" &
sleep 5
echo "Services starting in background!"

# Step 4: Get port URLs
echo ""
echo "[4/5] Getting port URLs..."
sleep 5  # Give ports time to register

URLS=$(gh codespace ports -c "$CODESPACE" --json sourcePort,browseUrl)
RAILS_URL=$(echo "$URLS" | jq -r '.[] | select(.sourcePort==3000) | .browseUrl')
METRO_URL=$(echo "$URLS" | jq -r '.[] | select(.sourcePort==8081) | .browseUrl')
SUPABASE_URL=$(echo "$URLS" | jq -r '.[] | select(.sourcePort==54322) | .browseUrl')

# Save environment config
mkdir -p ~/.spark-envs
cat > ~/.spark-envs/"$CODESPACE" << EOF
CODESPACE_NAME=$CODESPACE
BRANCH=$BRANCH
RAILS_URL=$RAILS_URL
METRO_URL=$METRO_URL
SUPABASE_URL=$SUPABASE_URL
CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

ln -sf ~/.spark-envs/"$CODESPACE" ~/.spark-env-current

# Step 5: Start port forwarding in background
echo ""
echo "[5/5] Starting port forwarding..."

# Create auto-reconnecting tunnel script
TUNNEL_SCRIPT="/tmp/spark-tunnel-$CODESPACE.sh"
cat > "$TUNNEL_SCRIPT" << TUNNEL
#!/bin/bash
while true; do
  echo "[\$(date)] Connecting port forward..."
  gh codespace ports forward 8081:8081 3000:3000 54321:54321 -c "$CODESPACE"
  echo "[\$(date)] Tunnel dropped, reconnecting in 2s..."
  sleep 2
done
TUNNEL
chmod +x "$TUNNEL_SCRIPT"

# Start tunnel in background
nohup "$TUNNEL_SCRIPT" > /tmp/spark-tunnel.log 2>&1 &
TUNNEL_PID=$!
echo "$TUNNEL_PID" > /tmp/spark-tunnel.pid

# Set up adb reverse for emulator
if adb devices 2>/dev/null | grep -q "emulator"; then
  adb reverse tcp:8081 tcp:8081
  adb reverse tcp:3000 tcp:3000
  adb reverse tcp:54321 tcp:54321
  echo "adb reverse configured for emulator (Metro, Rails, Supabase)"
fi

# Step 6: Kill background Metro and open interactive Metro in new Terminal
echo ""
echo "[6/7] Opening Metro in new Terminal window..."

# Kill background Metro so we can run interactively
gh codespace ssh -c "$CODESPACE" -- "pkill -f metro 2>/dev/null || true; pkill -f 'npm start' 2>/dev/null || true" 2>/dev/null || true
sleep 2

# Open new terminal window with interactive Metro (terminal-agnostic)
METRO_CMD="gh codespace ssh -c $CODESPACE -- -t 'cd /workspaces/spark-agent-tools/sparkpos && npm start -- --port 8081'"

# Detect terminal app and open appropriately
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

# Step 7: Wait for Metro and open DevTools
echo "[7/7] Waiting for Metro to start, then opening DevTools..."

# Wait for Metro to be ready (serves /json endpoint)
for i in {1..30}; do
  if curl -s http://localhost:8081/json | grep -q "devtoolsFrontendUrl" 2>/dev/null; then
    echo "Metro ready!"
    sleep 2  # Give app time to connect
    # Open DevTools in browser
    DEVTOOLS_PATH=$(curl -s http://localhost:8081/json | jq -r '.[0].devtoolsFrontendUrl // empty')
    if [ -n "$DEVTOOLS_PATH" ]; then
      open "http://localhost:8081$DEVTOOLS_PATH"
      echo "DevTools opened!"
    else
      echo "Note: No app connected yet. Reload app, then run: open \"http://localhost:8081\$(curl -s http://localhost:8081/json | jq -r '.[0].devtoolsFrontendUrl')\""
    fi
    break
  fi
  sleep 2
done

echo ""
echo "============================================"
echo "  SPARK ENVIRONMENT READY"
echo "============================================"
echo ""
echo "Codespace:  $CODESPACE"
echo "Branch:     $BRANCH"
echo ""
echo "Local URLs (via port forward):"
echo "  Rails:    http://localhost:3000"
echo "  Metro:    http://localhost:8081"
echo ""
echo "Metro is running in a separate Terminal window."
echo "  R - reload app"
echo "  D - dev menu"
echo "  J - reopen DevTools"
echo ""
echo "Commands:"
echo "  SSH:      gh codespace ssh -c $CODESPACE"
echo "  VS Code:  gh codespace code -c $CODESPACE"
echo "  DevTools: open \"http://localhost:8081\$(curl -s http://localhost:8081/json | jq -r '.[0].devtoolsFrontendUrl')\""
echo "  Stop:     kill \$(cat /tmp/spark-tunnel.pid)"
echo ""
echo "Port forwarding running in background (PID: $TUNNEL_PID)"
