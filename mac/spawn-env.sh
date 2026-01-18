#!/bin/bash
# Usage: ./spawn-env.sh [branch-name]

BRANCH=${1:-main}
REPO="Spark-Ordering/spark-agent-tools"

echo "Creating Codespace for branch: $BRANCH"

CODESPACE=$(gh codespace create \
  --repo $REPO \
  --branch $BRANCH \
  --machine basicLinux32gb \
  --json | jq -r '.name')

if [ -z "$CODESPACE" ]; then
  echo "Error: Failed to create Codespace"
  exit 1
fi

echo "Codespace created: $CODESPACE"
echo "Waiting for setup to complete..."

gh codespace ssh -c $CODESPACE -- "while [ ! -f /tmp/setup-complete ]; do sleep 5; done"

# Get forwarded URLs
URLS=$(gh codespace ports -c $CODESPACE --json sourcePort,browseUrl)
RUBY_URL=$(echo $URLS | jq -r '.[] | select(.sourcePort==3000) | .browseUrl')
JAVA_URL=$(echo $URLS | jq -r '.[] | select(.sourcePort==8080) | .browseUrl')
METRO_URL=$(echo $URLS | jq -r '.[] | select(.sourcePort==8081) | .browseUrl')

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
echo "=== Environment ready! ==="
echo "  Ruby:  $RUBY_URL"
echo "  Java:  $JAVA_URL"
echo "  Metro: $METRO_URL"
echo ""
echo "Connect: gh codespace ssh -c $CODESPACE"
echo "Switch:  ./switch-env.sh $CODESPACE"
