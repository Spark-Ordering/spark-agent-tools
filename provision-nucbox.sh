#!/usr/bin/env bash
# Provision a fresh GMKtec G3 Pro to match carlos-NucBox-G3-Pro (lab box, minimum viable).
# Run ON the new box after flashing Ubuntu 24.04:
#   bash provision-nucbox.sh carlos-NucBox-G3-Pro-2
# Idempotent: safe to re-run; tailscale up at the end prints the one auth URL to approve.
set -euo pipefail

NEW_HOST="${1:?usage: bash provision-nucbox.sh <hostname> (e.g. carlos-NucBox-G3-Pro-2)}"
SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

$SUDO hostnamectl set-hostname "$NEW_HOST"

$SUDO apt-get update
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y adb android-sdk-platform-tools-common git ffmpeg scrcpy curl

if ! command -v tailscale >/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
$SUDO systemctl enable --now tailscaled

id -nG carlos | grep -qw plugdev || $SUDO usermod -aG plugdev carlos

if [ "${SKIP_TAILSCALE_UP:-0}" != "1" ]; then
  $SUDO tailscale up --ssh
fi
echo "Done. Verify from the Mac: tailscale ssh carlos@$(echo "$NEW_HOST" | tr '[:upper:]' '[:lower:]') 'adb devices'"
