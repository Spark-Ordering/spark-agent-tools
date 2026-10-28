#!/bin/bash
# Block until the rigless emulator finishes booting (or 10 min), then print BOOTED/TIMEOUT + adb devices.
ssh carlos@rigless 'ADB=~/Android/Sdk/platform-tools/adb; timeout 600 $ADB wait-for-device; for i in $(seq 1 300); do [ "$($ADB shell getprop sys.boot_completed 2>/dev/null | tr -d "\r")" = 1 ] && { echo BOOTED; $ADB devices; exit 0; }; sleep 2; done; echo TIMEOUT; tail -5 ~/emulator.log'
