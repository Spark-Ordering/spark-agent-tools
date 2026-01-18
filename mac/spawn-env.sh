#!/bin/bash
# Usage: ./spawn-env.sh [branch-name]

BRANCH=${1:-main}
REPO="Spark-Ordering/spark-agent-tools"

echo "Creating Codespace for branch: $BRANCH"

# Create codespace and capture output
CREATE_OUTPUT=$(gh codespace create \
  --repo $REPO \
  --branch $BRANCH \
  --machine basicLinux32gb \
  -d "spark-$BRANCH" \
  2>&1)

# Extract codespace name from output or list recent codespaces
CODESPACE=$(gh codespace list --repo $REPO --json name,state -q '.[0].name' 2>/dev/null)

if [ -z "$CODESPACE" ]; then
  echo "Error: Failed to create Codespace"
  echo "Output: $CREATE_OUTPUT"
  exit 1
fi

echo "Codespace created: $CODESPACE"
echo "Waiting for Codespace to be ready..."

# Wait for codespace to be available
sleep 10

# Get forwarded URLs
URLS=$(gh codespace ports -c $CODESPACE --json sourcePort,browseUrl 2>/dev/null)
RUBY_URL=$(echo $URLS | jq -r '.[] | select(.sourcePort==3000) | .browseUrl' 2>/dev/null)
JAVA_URL=$(echo $URLS | jq -r '.[] | select(.sourcePort==8080) | .browseUrl' 2>/dev/null)
METRO_URL=$(echo $URLS | jq -r '.[] | select(.sourcePort==8081) | .browseUrl' 2>/dev/null)

# Save environment config
cat > ~/.spark-env-$CODESPACE << EOF
CODESPACE_NAME=$CODESPACE
BRANCH=$BRANCH
RUBY_URL=$RUBY_URL
JAVA_URL=$JAVA_URL
METRO_URL=$METRO_URL
CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

ln -sf ~/.spark-env-$CODESPACE ~/.spark-env-current

echo ""
echo "=== Codespace created! ==="
echo "Name: $CODESPACE"
echo ""
echo "Connect: gh codespace ssh -c $CODESPACE"
echo "VS Code: gh codespace code -c $CODESPACE"
echo ""
echo "Note: Run .devcontainer/start-all.sh inside the codespace to start services"
