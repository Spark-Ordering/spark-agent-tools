#!/bin/bash
# gradle-cache-reset.sh [subpath]
# Stop every Gradle daemon, then delete ~/.gradle/caches/<subpath> (default: all caches).
# Use after a cache wipe corrupts a live daemon's workspace ("Could not read workspace
# metadata … kotlin-dsl/accessors/…/metadata.bin"): gradle-cache-reset.sh 9.0.0/kotlin-dsl
set -euo pipefail
sub="${1:-}"
target="$HOME/.gradle/caches/$sub"
case "$target" in "$HOME/.gradle/caches/"*) ;; *) echo "refusing: $target" >&2; exit 1;; esac
pkill -f GradleDaemon 2>/dev/null && echo "stopped gradle daemons" || echo "no gradle daemons running"
sleep 1
if [ -e "$target" ]; then
  du -sh "$target" | cut -f1 | xargs -I{} echo "removing $target ({})"
  rm -rf "$target"
else
  echo "nothing at $target"
fi
df -h / | tail -1
