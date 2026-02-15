#!/bin/bash
# Android Emulator Control Script for Claude
# Usage: emu.sh <command> [args...]
#
# Commands:
#   shot                    - Take screenshot, save to /tmp/screen.png
#   tap <x> <y>             - Tap at coordinates
#   swipe <x1> <y1> <x2> <y2> [duration_ms] - Swipe gesture
#   text <string>           - Type text (use quotes for spaces)
#   key <keycode>           - Press key (back, home, enter, del, tab)
#   size                    - Get screen dimensions
#   list                    - List connected devices
#   wait                    - Wait for emulator to be ready
#
# Examples:
#   emu.sh shot
#   emu.sh tap 500 800
#   emu.sh swipe 500 1000 500 500
#   emu.sh text "hello world"
#   emu.sh key back

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UI_MAP="$SCRIPT_DIR/sparkpos-ui-map.json"

# Find the emulator device (prefer emulator over physical device)
get_device() {
    local devices=$(adb devices | grep -v "List of devices" | grep -v "^$")
    local emulator=$(echo "$devices" | grep "emulator" | head -1 | cut -f1)

    if [ -n "$emulator" ]; then
        echo "$emulator"
    else
        # Fall back to first device
        echo "$devices" | head -1 | cut -f1
    fi
}

DEVICE=$(get_device)

if [ -z "$DEVICE" ]; then
    echo "Error: No device found"
    exit 1
fi

ADB="adb -s $DEVICE"

case "$1" in
    shot|screenshot|s)
        timeout 15 $ADB exec-out screencap -p > /tmp/screen.png
        if [ $? -eq 0 ]; then
            echo "/tmp/screen.png"
        else
            echo "Error: Screenshot timed out (15s). Emulator may be slow or unresponsive."
            exit 1
        fi
        ;;

    tap|t)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: emu.sh tap <x> <y>"
            exit 1
        fi
        $ADB shell input tap "$2" "$3"
        echo "Tapped at $2, $3"
        ;;

    swipe|sw)
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
            echo "Usage: emu.sh swipe <x1> <y1> <x2> <y2> [duration_ms]"
            exit 1
        fi
        duration="${6:-300}"
        $ADB shell input swipe "$2" "$3" "$4" "$5" "$duration"
        echo "Swiped from ($2,$3) to ($4,$5)"
        ;;

    text|type|txt)
        if [ -z "$2" ]; then
            echo "Usage: emu.sh text <string>"
            exit 1
        fi
        # Escape spaces for adb
        escaped=$(echo "$2" | sed 's/ /%s/g')
        $ADB shell input text "$escaped"
        echo "Typed: $2"
        ;;

    key|k)
        if [ -z "$2" ]; then
            echo "Usage: emu.sh key <keycode>"
            echo "Common keys: back, home, enter, del, tab, menu"
            exit 1
        fi
        case "$2" in
            back)    keycode=4 ;;
            home)    keycode=3 ;;
            enter)   keycode=66 ;;
            del)     keycode=67 ;;
            tab)     keycode=61 ;;
            menu)    keycode=82 ;;
            up)      keycode=19 ;;
            down)    keycode=20 ;;
            left)    keycode=21 ;;
            right)   keycode=22 ;;
            *)       keycode="$2" ;;
        esac
        $ADB shell input keyevent "$keycode"
        echo "Pressed key: $2"
        ;;

    size|resolution)
        $ADB shell wm size | grep "Physical" | cut -d: -f2 | tr -d ' '
        ;;

    list|devices)
        adb devices
        ;;

    wait|ready)
        echo "Waiting for emulator device..."
        adb wait-for-device
        echo "Device connected. Waiting for boot..."
        for i in $(seq 1 30); do
            BOOT=$(timeout 5 $ADB shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
            if [ "$BOOT" = "1" ]; then
                echo "Emulator fully booted: $(get_device)"
                exit 0
            fi
            echo "  ...booting ($((i * 5))s / 150s)"
            sleep 5
        done
        echo "Warning: Boot did not complete in 150s, but device is connected."
        ;;

    device)
        echo "$DEVICE"
        ;;

    # ─── App lifecycle commands ───

    start|launch)
        # Start SparkPos app and wait for it to load
        PKG="${2:-com.starter.pad}"
        ACT="com.starter.pad.MainActivity"
        echo "Starting $PKG..."
        $ADB shell am force-stop "$PKG" 2>/dev/null
        sleep 1
        $ADB shell am start -n "$PKG/$ACT"
        echo "Waiting for app to load (up to 90s)..."
        for i in $(seq 1 18); do
            sleep 5
            # Check if app process is running
            if $ADB shell pidof "$PKG" >/dev/null 2>&1; then
                # Try a screenshot to see if bundling is done
                $ADB exec-out screencap -p > /tmp/screen.png 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo "App running (${i}x5=${i}0s). Screenshot at /tmp/screen.png"
                    # Check if still bundling by looking for the bundling bar
                    # (simple heuristic — if the screenshot is mostly white/blank, still loading)
                    break
                fi
            fi
            echo "  ...waiting (${i}0s / 90s)"
        done
        echo "App started. Use 'emu.sh shot' to check screen."
        ;;

    stop|kill)
        PKG="${2:-com.starter.pad}"
        $ADB shell am force-stop "$PKG"
        echo "Stopped $PKG"
        ;;

    restart)
        PKG="${2:-com.starter.pad}"
        "$0" stop "$PKG"
        sleep 2
        "$0" start "$PKG"
        ;;

    alive|running)
        # Check if app is running (exit 0 = yes, exit 1 = no)
        PKG="${2:-com.starter.pad}"
        PID=$($ADB shell pidof "$PKG" 2>/dev/null | tr -d '\r')
        if [ -n "$PID" ]; then
            echo "Running (PID: $PID)"
        else
            echo "Not running"
            exit 1
        fi
        ;;

    metro-status)
        # Check if Metro bundler is alive
        STATUS=$(curl -s --connect-timeout 3 http://localhost:8081/status 2>/dev/null)
        if [ "$STATUS" = "packager-status:running" ]; then
            echo "Metro: running"
        else
            echo "Metro: NOT running"
            exit 1
        fi
        ;;

    deploy)
        # Full deploy: kill metro, rebuild, install, start, wait
        VERSION="${2:-2}"
        SCRIPT_DIR_DEPLOY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        echo "Deploying SparkPos$VERSION..."
        "$SCRIPT_DIR_DEPLOY/deploy-sparkpos.sh" "$VERSION"
        echo "Deploy done. Waiting for app to be ready..."
        sleep 5
        $ADB reverse tcp:8081 tcp:8081
        "$0" start
        ;;

    # ─── Navigation commands ───

    nav-settings)
        # Navigate to Settings (requires FORCE_SETTINGS_UNLOCKED=true)
        echo "Opening hamburger menu..."
        $ADB shell input tap 56 64
        sleep 2
        # Dump to find Settings
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        SETTINGS_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i 'text="Settings"' | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        if [ -n "$SETTINGS_BOUNDS" ]; then
            read x1 y1 x2 y2 <<< "$SETTINGS_BOUNDS"
            cx=$(( (x1 + x2) / 2 ))
            cy=$(( (y1 + y2) / 2 ))
            echo "Tapping Settings at $cx, $cy"
            $ADB shell input tap "$cx" "$cy"
            sleep 2
            echo "Settings opened. Use 'emu.sh shot' to verify."
        else
            echo "Settings not found in drawer. Is FORCE_SETTINGS_UNLOCKED=true set?"
        fi
        ;;

    nav-card-reader)
        # Navigate to Card Reader settings
        "$0" nav-settings
        sleep 1
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        CR_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i 'text="Card Reader"' | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        if [ -n "$CR_BOUNDS" ]; then
            read x1 y1 x2 y2 <<< "$CR_BOUNDS"
            cx=$(( (x1 + x2) / 2 ))
            cy=$(( (y1 + y2) / 2 ))
            echo "Tapping Card Reader at $cx, $cy"
            $ADB shell input tap "$cx" "$cy"
            sleep 2
            echo "Card Reader settings opened. Use 'emu.sh shot' to verify."
        else
            echo "Card Reader not found. Try 'emu.sh shot' to see current screen."
        fi
        ;;

    setup-card-reader)
        # Full card reader setup: navigate to Card Reader, then Link → Activate → Check Connection
        "$0" nav-card-reader
        sleep 1
        # Dump to find buttons
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        get_center() {
            local text="$1"
            local bounds=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i "text=\"$text\"" | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
            if [ -n "$bounds" ]; then
                read x1 y1 x2 y2 <<< "$bounds"
                echo "$(( (x1 + x2) / 2 )) $(( (y1 + y2) / 2 ))"
            fi
        }
        LINK=$(get_center "Link Device")
        ACTIVATE=$(get_center "Activate Device")
        CHECK=$(get_center "Check Connection")
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        if [ -z "$LINK" ] || [ -z "$ACTIVATE" ] || [ -z "$CHECK" ]; then
            echo "Could not find all Card Reader buttons. Use 'emu.sh shot' to check."
            exit 1
        fi
        echo "Link Device..."
        $ADB shell input tap $LINK
        sleep 1
        echo "Activate Device..."
        $ADB shell input tap $ACTIVATE
        sleep 1
        echo "Check Connection..."
        $ADB shell input tap $CHECK
        sleep 2
        echo "Card reader setup complete. Use 'emu.sh shot' to verify."
        ;;

    # ─── Smart screenshot with retry ───

    wait-shot)
        # Take screenshot with retry (useful when emulator is slow)
        MAX_TRIES="${2:-3}"
        DELAY="${3:-5}"
        for i in $(seq 1 $MAX_TRIES); do
            if timeout 10 $ADB exec-out screencap -p > /tmp/screen.png 2>/dev/null; then
                echo "/tmp/screen.png"
                exit 0
            fi
            echo "  Screenshot attempt $i/$MAX_TRIES failed, waiting ${DELAY}s..."
            sleep "$DELAY"
        done
        echo "Error: Could not take screenshot after $MAX_TRIES attempts"
        exit 1
        ;;

    dump|ui)
        # Dump UI hierarchy and extract clickable elements
        $ADB shell uiautomator dump /sdcard/ui.xml
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        echo "Clickable elements:"
        cat /tmp/ui.xml | tr '>' '\n' | grep 'clickable="true"' | \
            sed 's/.*content-desc="\([^"]*\)".*bounds="\([^"]*\)".*/  \1: \2/' | \
            grep -v "^  :" | head -30
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        ;;

    clean|cleanup)
        # Clean up temp files
        rm -f /tmp/screen.png /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        echo "Cleaned up temp files"
        ;;

    lookup|find)
        # Look up element coordinates from UI map
        if [ -z "$2" ]; then
            echo "Usage: emu.sh lookup <screen>.<element>"
            echo "Example: emu.sh lookup customItemDialog.priceField"
            exit 1
        fi
        if [ ! -f "$UI_MAP" ]; then
            echo "Error: UI map not found at $UI_MAP"
            exit 1
        fi
        screen=$(echo "$2" | cut -d. -f1)
        element=$(echo "$2" | cut -d. -f2)
        # Extract center coordinates using jq or python
        if command -v jq &> /dev/null; then
            center=$(jq -r ".screens.\"$screen\".elements.\"$element\".center | @csv" "$UI_MAP" 2>/dev/null)
            if [ "$center" != "null" ] && [ -n "$center" ]; then
                echo "$center" | tr -d '"'
            else
                echo "Element not found: $2"
                exit 1
            fi
        else
            echo "jq not installed - install with: brew install jq"
            exit 1
        fi
        ;;

    tap-element|te)
        # Tap an element by name from UI map
        if [ -z "$2" ]; then
            echo "Usage: emu.sh tap-element <screen>.<element>"
            echo "Example: emu.sh tap-element customItemDialog.addToCartButton"
            exit 1
        fi
        coords=$("$0" lookup "$2")
        if [ $? -eq 0 ]; then
            x=$(echo "$coords" | cut -d, -f1)
            y=$(echo "$coords" | cut -d, -f2)
            $ADB shell input tap "$x" "$y"
            echo "Tapped $2 at $x, $y"
        fi
        ;;

    nav-menu-settings)
        # Navigate to Menu Settings page
        "$0" nav-settings
        sleep 1
        # Find and tap "Menu Settings" in the sidebar
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        MS_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i 'text="Menu Settings"' | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        if [ -n "$MS_BOUNDS" ]; then
            read x1 y1 x2 y2 <<< "$MS_BOUNDS"
            cx=$(( (x1 + x2) / 2 ))
            cy=$(( (y1 + y2) / 2 ))
            echo "Tapping Menu Settings at $cx, $cy"
            $ADB shell input tap "$cx" "$cy"
            sleep 2
            echo "Menu Settings opened. Use 'emu.sh shot' to verify."
        else
            echo "Menu Settings not found. Try 'emu.sh shot' to see current screen."
        fi
        ;;

    nav-menu-editor)
        # Navigate to Menu Editor (Settings → Menu Settings → Edit Menu)
        "$0" nav-menu-settings
        sleep 1
        # Find and tap "Edit Menu" button
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        EM_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i 'text="Edit Menu"' | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        if [ -n "$EM_BOUNDS" ]; then
            read x1 y1 x2 y2 <<< "$EM_BOUNDS"
            cx=$(( (x1 + x2) / 2 ))
            cy=$(( (y1 + y2) / 2 ))
            echo "Tapping Edit Menu at $cx, $cy"
            $ADB shell input tap "$cx" "$cy"
            sleep 2
            echo "Menu Editor opened. Use 'emu.sh shot' to verify."
        else
            echo "Edit Menu button not found. Try 'emu.sh shot' to see current screen."
        fi
        ;;

    tap-text)
        # Tap on any UI element by its text content
        if [ -z "$2" ]; then
            echo "Usage: emu.sh tap-text <text>"
            echo "Example: emu.sh tap-text 'Settings'"
            exit 1
        fi
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        TT_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep "text=\"$2\"" | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        if [ -n "$TT_BOUNDS" ]; then
            read x1 y1 x2 y2 <<< "$TT_BOUNDS"
            cx=$(( (x1 + x2) / 2 ))
            cy=$(( (y1 + y2) / 2 ))
            echo "Tapping '$2' at $cx, $cy"
            $ADB shell input tap "$cx" "$cy"
        else
            echo "Element with text '$2' not found. Try 'emu.sh dump' to see available elements."
        fi
        ;;

    select-all)
        # Select all text in currently focused field
        $ADB shell input keyevent 123  # End
        sleep 0.2
        $ADB shell input keyevent --longpress 59 122  # Shift+Home
        echo "Selected all text in focused field"
        ;;

    replace-text)
        # Select all text in focused field and replace with new text
        if [ -z "$2" ]; then
            echo "Usage: emu.sh replace-text <new_text>"
            exit 1
        fi
        $ADB shell input keyevent 123  # End
        sleep 0.2
        $ADB shell input keyevent --longpress 59 122  # Shift+Home
        sleep 0.2
        $ADB shell input text "$2"
        echo "Replaced text with: $2"
        ;;

    confirm)
        # Press Enter key to confirm/submit
        $ADB shell input keyevent 66
        echo "Pressed Enter"
        ;;

    back)
        # Press Back button (dismiss keyboard, go back, etc.)
        $ADB shell input keyevent 4
        echo "Pressed Back"
        ;;

    map)
        # Show all mapped elements
        if [ ! -f "$UI_MAP" ]; then
            echo "Error: UI map not found at $UI_MAP"
            exit 1
        fi
        if command -v jq &> /dev/null; then
            echo "Mapped screens and elements:"
            jq -r '.screens | to_entries[] | "\n[\(.key)]", (.value.elements | to_entries[] | "  \(.key): \(.value.center)")' "$UI_MAP"
        else
            cat "$UI_MAP"
        fi
        ;;

    *)
        echo "Android Emulator Control Script"
        echo ""
        echo "Usage: emu.sh <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  shot                    - Take screenshot (/tmp/screen.png)"
        echo "  wait-shot [tries] [delay] - Screenshot with retry (default 3 tries, 5s delay)"
        echo "  tap <x> <y>             - Tap at coordinates"
        echo "  tap-element <s>.<e>     - Tap element by name from UI map"
        echo "  swipe <x1> <y1> <x2> <y2> - Swipe gesture"
        echo "  text <string>           - Type text"
        echo "  key <keycode>           - Press key (back/home/enter/del)"
        echo "  size                    - Get screen dimensions"
        echo "  list                    - List devices"
        echo "  wait                    - Wait for emulator"
        echo "  device                  - Show current device"
        echo "  dump                    - Dump UI hierarchy, show clickable elements"
        echo "  lookup <screen>.<elem>  - Get coordinates from UI map"
        echo "  map                     - Show all mapped elements"
        echo "  clean                   - Remove temp files"
        echo ""
        echo "App lifecycle:"
        echo "  start [pkg]             - Start app and wait for load (up to 90s)"
        echo "  stop [pkg]              - Force stop app"
        echo "  restart [pkg]           - Stop + start"
        echo "  alive [pkg]             - Check if app is running"
        echo "  metro-status            - Check if Metro bundler is alive"
        echo "  deploy [1|2|3]          - Full deploy + start + wait"
        echo ""
        echo "Navigation:"
        echo "  nav-settings            - Open Settings (needs FORCE_SETTINGS_UNLOCKED)"
        echo "  nav-card-reader         - Navigate to Card Reader settings"
        echo "  nav-menu-settings       - Navigate to Menu Settings page"
        echo "  nav-menu-editor         - Navigate to Menu Editor (full path)"
        echo "  tap-text <text>         - Tap UI element by its text content"
        echo "  setup-card-reader       - Full card reader setup (Link → Activate → Check Connection)"
        ;;
esac
