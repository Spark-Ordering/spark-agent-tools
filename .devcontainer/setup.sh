#!/bin/bash
set -e

# Usage: ./setup.sh [sparkpos-branch]
SPARKPOS_BRANCH=${1:-master}

echo "=== Spark Development Environment Setup ==="
echo "SparkPos branch: $SPARKPOS_BRANCH"

# Clone repos using GitHub token
if [ -z "$GH_TOKEN" ]; then
  echo "ERROR: GH_TOKEN environment variable not set"
  exit 1
fi

echo ""
echo "[clone] Cloning repositories in parallel..."
git clone "https://${GH_TOKEN}@github.com/Spark-Ordering/spark_backend.git" &
git clone "https://${GH_TOKEN}@github.com/Spark-Ordering/RequestManager.git" &
git clone "https://${GH_TOKEN}@github.com/carlosdelivery/SparkPos.git" sparkpos &
wait
echo "[clone] Done!"

# Install Supabase CLI (needed before tracks start)
echo ""
echo "[deps] Installing Supabase CLI..."
SUPABASE_DEB_URL=$(curl -sL https://api.github.com/repos/supabase/cli/releases/latest | grep -oE 'https://[^"]+linux_amd64\.deb' | head -1)
curl -fsSL -o /tmp/supabase.deb "$SUPABASE_DEB_URL"
sudo dpkg -i /tmp/supabase.deb

# Make track scripts executable
chmod +x .devcontainer/tracks/*.sh

# Run all tracks in parallel
echo ""
echo "=== Starting parallel tracks ==="
echo "  [sparkpos]  supabase + npm + migrations"
echo "  [rails]     apt-get + bundle + MySQL + migrations"
echo "  [java]      mvn package"
echo "  [powersync] mongodb + powersync service (waits for supabase)"
echo ""

START_TIME=$(date +%s)

.devcontainer/tracks/sparkpos-track.sh "$SPARKPOS_BRANCH" &
SPARKPOS_PID=$!

.devcontainer/tracks/rails-track.sh &
RAILS_PID=$!

.devcontainer/tracks/java-track.sh &
JAVA_PID=$!

.devcontainer/tracks/powersync-track.sh &
POWERSYNC_PID=$!

# Wait for all tracks
wait $JAVA_PID
echo "✓ Java track complete"

wait $SPARKPOS_PID
echo "✓ SparkPos track complete"

wait $RAILS_PID
echo "✓ Rails track complete"

wait $POWERSYNC_PID
echo "✓ PowerSync track complete"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

touch /tmp/setup-complete
echo ""
echo "=== Environment ready! ==="
echo "Total time: ${DURATION} seconds"
echo "Run .devcontainer/start-all.sh to start services"
