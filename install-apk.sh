#!/bin/bash
# install-apk.sh - Install SparkPos release APK on attached Android emulators
#
# Usage:
#   install-apk.sh                                    install on ALL attached devices (default)
#   install-apk.sh emulator-5554 emulator-5556       install only on listed serials
#   install-apk.sh --apk /path/to/foo.apk             use custom APK path
#   install-apk.sh --apk /path/foo.apk emulator-5554  combine
#
# Replaces ad-hoc `adb -s <serial> install ...` invocations. Installs in parallel.
# Default APK: $SPARKPOS_DIR/android/app/build/outputs/apk/release/app-release.apk

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/repo-finder.sh"

ADB="$HOME/Library/Android/sdk/platform-tools/adb"

APK=""
TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apk)
      APK="$2"
      shift 2
      ;;
    -h|--help)
      grep -E '^#' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      TARGETS+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$APK" ]]; then
  SPARKPOS_DIR=$(find_repo "SparkPos.git")
  APK="$SPARKPOS_DIR/android/app/build/outputs/apk/release/app-release.apk"
fi

if [[ ! -f "$APK" ]]; then
  echo "ERROR: APK not found: $APK" >&2
  echo "Build it first: cd \$SPARKPOS_DIR && npm run ab" >&2
  exit 1
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  while IFS= read -r line; do
    TARGETS+=("$line")
  done < <("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  echo "ERROR: no attached devices found" >&2
  exit 1
fi

echo "Installing $APK on ${#TARGETS[@]} device(s): ${TARGETS[*]}"

pids=()
for serial in "${TARGETS[@]}"; do
  (
    echo "[$serial] installing..."
    "$ADB" -s "$serial" install -r "$APK" 2>&1 | sed "s/^/[$serial] /"
  ) &
  pids+=($!)
done

fail=0
for pid in "${pids[@]}"; do
  wait "$pid" || fail=1
done

if [[ $fail -ne 0 ]]; then
  echo "ERROR: one or more installs failed" >&2
  exit 1
fi

echo "All installs complete"
