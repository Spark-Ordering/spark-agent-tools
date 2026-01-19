#!/bin/bash
set -e

# Java Track: Maven build
# Fully independent - can run in parallel with other tracks

echo "[java] Starting track..."

cd /workspaces/spark-agent-tools/RequestManager

echo "[java] Running mvn package (parallel, 1 thread per core)..."
mvn package -DskipTests -q -T 1C

touch /tmp/java-track-done
echo "[java] Track complete!"
