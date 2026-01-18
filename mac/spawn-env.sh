#!/bin/bash
# Usage: ./spawn-env.sh [branch-name]
# Fully automated: creates Codespace, waits for services, sets up port forwarding

set -e

BRANCH=${1:-master}
REPO="Spark-Ordering/spark-agent-tools"
ENV_NAME="spark-${BRANCH}"

echo "=== Spark Environment Spawner ==="
echo "Branch: $BRANCH"
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

# Step 2: Wait for setup to complete
echo ""
echo "[2/5] Waiting for setup to complete..."
while true; do
  if gh codespace ssh -c "$CODESPACE" -- "test -f /tmp/setup-complete" 2>/dev/null; then
    echo "Setup complete!"
    break
  fi
  echo "  Still setting up..."
  sleep 15
done

# Step 3: Wait for services to start
echo ""
echo "[3/5] Waiting for services to start..."
while true; do
  if gh codespace ssh -c "$CODESPACE" -- "test -f /tmp/services-started" 2>/dev/null; then
    echo "Services started!"
    break
  fi
  echo "  Starting services..."
  sleep 5
done

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
  gh codespace ports forward 8081:8081 3000:3000 -c "$CODESPACE"
  echo "[\$(date)] Tunnel dropped, reconnecting in 2s..."
  sleep 2
done
TUNNEL
chmod +x "$TUNNEL_SCRIPT"

# Start tunnel in background
nohup "$TUNNEL_SCRIPT" > /tmp/spark-tunnel.log 2>&1 &
TUNNEL_PID=$!
echo "$TUNNEL_PID" > /tmp/spark-tunnel.pid

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
echo "Remote URLs:"
echo "  Rails:    $RAILS_URL"
echo "  Metro:    $METRO_URL"
echo "  Supabase: $SUPABASE_URL"
echo ""
echo "Commands:"
echo "  SSH:      gh codespace ssh -c $CODESPACE"
echo "  VS Code:  gh codespace code -c $CODESPACE"
echo "  Logs:     tail -f /tmp/spark-tunnel.log"
echo "  Stop:     kill \$(cat /tmp/spark-tunnel.pid)"
echo ""
echo "Port forwarding running in background (PID: $TUNNEL_PID)"
