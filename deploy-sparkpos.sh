#!/bin/bash
# deploy-sparkpos-headless.sh — Deploy SparkPos without needing Terminal GUI
# Works even when Mac is locked.
#
# Usage:
#   deploy-sparkpos-headless.sh [1|2|3]   (default: 2)

set -e

VERSION="${1:-2}"

case "$VERSION" in
    1) DIR="$HOME/code/SparkPos" ;;
    2) DIR="$HOME/code/SparkPos2" ;;
    3) DIR="$HOME/code/SparkPos3" ;;
    *) echo "Unknown version: $VERSION (use 1, 2, or 3)"; exit 1 ;;
esac

if [ ! -d "$DIR" ]; then
    echo "ERROR: Directory not found: $DIR"
    exit 1
fi

echo "Deploying SparkPos$VERSION from $DIR (headless)..."

# Ensure ANDROID_HOME is set
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

# Step 1: Kill any existing Metro on port 8081
echo "Killing port 8081..."
lsof -ti:8081 2>/dev/null | xargs kill -9 2>/dev/null || true
sleep 1

cd "$DIR"

# Step 2: Make sure switch-env has been run (build.gradle exists)
if [ ! -f "android/app/build.gradle" ]; then
    echo "android/app/build.gradle missing — running switch-env..."
    ACTIVE_ENV=$(cat .env.active 2>/dev/null || echo "develop2")
    ./switch-env.sh "$ACTIVE_ENV"
fi

# Step 3: Check emulator is running
if ! adb devices 2>/dev/null | grep -q "emulator.*device"; then
    echo "Starting emulator..."
    nohup $ANDROID_HOME/emulator/emulator -avd Pixel_Tablet -no-window > /tmp/emu.log 2>&1 &
    echo "Waiting for emulator to boot..."
    adb wait-for-device
    while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
        sleep 2
    done
    echo "Emulator booted."
fi

DEVICE_ID=$(adb devices | grep "emulator" | awk '{print $1}' | head -1)

# Step 4: Clear caches
echo "Clearing caches..."
pkill -f "react-native.*start" 2>/dev/null || true
rm -rf $TMPDIR/metro-* $TMPDIR/haste-* node_modules/.cache 2>/dev/null
rm -rf android/app/build/generated/assets android/app/build/intermediates/assets 2>/dev/null

# Step 5: Check env
if [ ! -f ".env.local" ]; then
    echo "Error: .env.local file not found"
    exit 1
fi

# Step 6: Start Metro in background
echo "Starting Metro bundler..."
npx react-native start --port 8081 &
METRO_PID=$!
sleep 5

# Step 7: Build and install
echo "Building and installing on $DEVICE_ID..."
npx react-native run-android --deviceId "$DEVICE_ID" --no-packager

echo "Deploy complete. Metro PID: $METRO_PID"
