#!/bin/bash
# Attach the rigless emulator to the nucbox adb server (the one the Mac's adb uses) as localhost:5565.
# rigless's own adb server must let go first: the emulator's adbd takes one server connection at a time.
NUC=$(tailscale ip -4 carlos-nucbox-g3-pro)
ssh carlos@rigless '~/Android/Sdk/platform-tools/adb kill-server' 2>/dev/null
ssh carlos@$NUC 'pgrep -f "ssh.*-L5565:localhost:5555" >/dev/null || ssh -fN -o BatchMode=yes -o ExitOnForwardFailure=yes -L5565:localhost:5555 carlos@rigless'
adb connect localhost:5565
adb -s localhost:5565 shell getprop ro.product.model
