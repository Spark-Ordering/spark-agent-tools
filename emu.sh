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
        $ADB exec-out screencap -p > /tmp/screen.png
        echo "/tmp/screen.png"
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
        echo "Waiting for emulator..."
        adb wait-for-device
        echo "Emulator ready: $(get_device)"
        ;;

    device)
        echo "$DEVICE"
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
        ;;
esac
