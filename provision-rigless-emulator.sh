#!/bin/bash
# User-space (no sudo) Android emulator on rigless: portable JDK, SDK cmdline-tools, one x86_64
# Pixel Tablet AVD "PIXEL_DEV". Idempotent: skips whatever is already installed. Ends with RESULT=ok|fail.
set -e
SDK=$HOME/Android/Sdk
JDK=$HOME/jdk17
IMAGE="system-images;android-34;google_apis;x86_64"
AVD=PIXEL_DEV

if [ ! -x "$JDK/bin/java" ]; then
  echo "== JDK"
  mkdir -p "$JDK"
  curl -fsSL "https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse" | tar -xz -C "$JDK" --strip-components=1
fi
export JAVA_HOME=$JDK PATH=$JDK/bin:$PATH

if [ ! -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ]; then
  echo "== cmdline-tools"
  mkdir -p "$SDK/cmdline-tools"
  curl -fsSL -o /tmp/cmdtools.zip "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
  python3 -c "import zipfile; zipfile.ZipFile('/tmp/cmdtools.zip').extractall('$SDK/cmdline-tools')"
  mv "$SDK/cmdline-tools/cmdline-tools" "$SDK/cmdline-tools/latest"
  chmod +x "$SDK"/cmdline-tools/latest/bin/*
fi

echo "== SDK packages"
yes | "$SDK/cmdline-tools/latest/bin/sdkmanager" --licenses > /dev/null || true
"$SDK/cmdline-tools/latest/bin/sdkmanager" "platform-tools" "emulator" "$IMAGE"

if ! "$SDK/cmdline-tools/latest/bin/avdmanager" list avd -c | grep -qx "$AVD"; then
  echo "== AVD"
  echo no | "$SDK/cmdline-tools/latest/bin/avdmanager" create avd -n "$AVD" -k "$IMAGE" -d pixel_tablet --force
fi
# 2 cores / 4 GB on a 4-core 15 GB box; never prompt to save state on exit.
CFG=$HOME/.android/avd/$AVD.avd/config.ini
grep -q '^hw.cpu.ncore=2' "$CFG" || echo 'hw.cpu.ncore=2' >> "$CFG"
grep -q '^hw.ramSize=4096' "$CFG" || echo 'hw.ramSize=4096' >> "$CFG"
printf 'saveOnExit = false\n' > "$HOME/.android/avd/$AVD.avd/quickbootChoice.ini"
echo RESULT=ok
