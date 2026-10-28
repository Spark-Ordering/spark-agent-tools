#!/bin/bash
# android-build-clean.sh [repo-dir]   (default: cwd)
# Delete the Android native/gradle build outputs that go stale when node_modules changes
# under a checkout: android/app/.cxx, android/app/build, android/build. Symptom this cures:
# CMake "Cannot specify link libraries for target react_codegen_<X>Spec which is not built".
set -euo pipefail
root="${1:-$PWD}"
[ -d "$root/android/app" ] || { echo "no android/app under $root" >&2; exit 1; }
pkill -f GradleDaemon 2>/dev/null && echo "stopped gradle daemons" || echo "no gradle daemons running"
for d in android/app/.cxx android/app/build android/build; do
  if [ -e "$root/$d" ]; then
    echo "removing $d ($(du -sh "$root/$d" | cut -f1))"
    rm -rf "$root/$d"
  else
    echo "nothing at $d"
  fi
done
df -h / | tail -1
