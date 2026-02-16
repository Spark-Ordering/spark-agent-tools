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
#   emu.sh tap-nth icon Edit 0     - Tap 0th element with Edit in content-desc
#   emu.sh tap-nth class ImageView 2 - Tap 2nd ImageView

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

# Commands that don't require a device
case "$1" in
    eiu|run-eiu|list|devices|help|"")
        # These commands can run without a device
        ;;
    *)
        if [ -z "$DEVICE" ]; then
            echo "Error: No device found"
            exit 1
        fi
        ;;
esac

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
        echo "ERROR: Direct coordinate tapping is disabled."
        echo ""
        echo "Use one of these ID-based commands instead:"
        echo "  emu.sh tap-id <accessibility-label>   - Tap element by content-desc"
        echo "  emu.sh tap-text <visible-text>        - Tap element by visible text"
        echo "  emu.sh tap-nth <type> <pattern> <n>   - Tap nth matching element"
        echo ""
        echo "For text input fields:"
        echo "  emu.sh clear-field                    - Clear focused text field (cf)"
        echo "  emu.sh replace-text <string>          - Clear field and type new text (rt)"
        echo ""
        echo "Run 'emu.sh dump' first to see available element IDs."
        exit 1
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

    clear-field|cf)
        # Select all (Ctrl+A) then delete
        $ADB shell input keyevent KEYCODE_MOVE_END
        # Delete 50 chars (should be enough for most fields)
        for i in {1..50}; do $ADB shell input keyevent KEYCODE_DEL; done
        echo "Field cleared"
        ;;

    replace-text|rt)
        if [ -z "$2" ]; then
            echo "Usage: emu.sh replace-text <string>"
            exit 1
        fi
        # Clear field first
        $ADB shell input keyevent KEYCODE_MOVE_END
        for i in {1..50}; do $ADB shell input keyevent KEYCODE_DEL; done
        # Type new text
        escaped=$(echo "$2" | sed 's/ /%s/g')
        $ADB shell input text "$escaped"
        echo "Replaced with: $2"
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
        # Find Settings by accessibilityLabel (desc attribute)
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        SETTINGS_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep 'desc=".*Settings"' | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        if [ -n "$SETTINGS_BOUNDS" ]; then
            read x1 y1 x2 y2 <<< "$SETTINGS_BOUNDS"
            cx=$(( (x1 + x2) / 2 ))
            cy=$(( (y1 + y2) / 2 ))
            echo "Tapping Settings at $cx, $cy"
            $ADB shell input tap "$cx" "$cy"
            sleep 2
            echo "Settings opened."
        else
            echo "Settings not found. Is FORCE_SETTINGS_UNLOCKED=true set?"
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
        # Find "Menu Settings" by accessibilityLabel
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        MS_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep 'desc="Menu Settings"' | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        if [ -n "$MS_BOUNDS" ]; then
            read x1 y1 x2 y2 <<< "$MS_BOUNDS"
            cx=$(( (x1 + x2) / 2 ))
            cy=$(( (y1 + y2) / 2 ))
            echo "Tapping Menu Settings at $cx, $cy"
            $ADB shell input tap "$cx" "$cy"
            sleep 2
            echo "Menu Settings opened."
        else
            echo "Menu Settings not found."
        fi
        ;;

    nav-menu|nav-home)
        # Navigate to Menu Home (the main POS ordering screen)
        echo "Opening hamburger menu..."
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        echo "UI hierchary dumped to: /sdcard/ui.xml"
        # Find hamburger menu icon (usually at top-left, content-desc contains "menu" or "navigation")
        MENU_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i 'content-desc="[^"]*menu[^"]*"' | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        if [ -z "$MENU_BOUNDS" ]; then
            # Try looking for hamburger icon by class
            MENU_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i 'content-desc=".*navigation.*"' | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        fi
        if [ -n "$MENU_BOUNDS" ]; then
            read x1 y1 x2 y2 <<< "$MENU_BOUNDS"
            cx=$(( (x1 + x2) / 2 ))
            cy=$(( (y1 + y2) / 2 ))
            $ADB shell input tap "$cx" "$cy"
        else
            # Fallback to known coordinate for hamburger
            $ADB shell input tap 56 64
        fi
        sleep 1
        # Find "Menu" option in the drawer
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        # Try content-desc="Menu Home" first, then text="Menu Home"
        MENU_NAV_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep 'content-desc="Menu Home"' | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        if [ -z "$MENU_NAV_BOUNDS" ]; then
            MENU_NAV_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep 'text="Menu Home"' | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        fi
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        if [ -n "$MENU_NAV_BOUNDS" ]; then
            read x1 y1 x2 y2 <<< "$MENU_NAV_BOUNDS"
            cx=$(( (x1 + x2) / 2 ))
            cy=$(( (y1 + y2) / 2 ))
            echo "Tapping Menu at $cx, $cy"
            $ADB shell input tap "$cx" "$cy"
            sleep 1
            echo "Menu home opened."
        else
            echo "Menu option not found in drawer. Try 'emu.sh dump-all' to see available elements."
        fi
        ;;

    nav-menu-editor)
        # Navigate to Menu Editor (Settings → Menu Settings → Edit Menu)
        "$0" nav-menu-settings
        sleep 1
        # Find "Edit Menu" by accessibilityLabel
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        EM_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep 'desc="Edit Menu"' | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        if [ -n "$EM_BOUNDS" ]; then
            read x1 y1 x2 y2 <<< "$EM_BOUNDS"
            cx=$(( (x1 + x2) / 2 ))
            cy=$(( (y1 + y2) / 2 ))
            echo "Tapping Edit Menu at $cx, $cy"
            $ADB shell input tap "$cx" "$cy"
            sleep 2
            echo "Menu Editor opened."
        else
            echo "Edit Menu button not found."
        fi
        ;;

    login)
        # Login with test credentials (Restaurant ID: 23, Password: password)
        # Uses accessibilityLabel (content-desc) for reliable element targeting
        # Note: React Native Paper components use accessibilityLabel, not testID
        RESTAURANT_ID="${2:-23}"
        PASSWORD="${3:-password}"

        echo "Logging in with Restaurant ID: $RESTAURANT_ID"

        # Helper to find element by testID (content-desc) and tap it
        tap_testid() {
            local testid="$1"
            $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
            $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
            local bounds=$(cat /tmp/ui.xml | tr '>' '\n' | grep "content-desc=\"$testid\"" | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
            if [ -n "$bounds" ]; then
                read x1 y1 x2 y2 <<< "$bounds"
                local cx=$(( (x1 + x2) / 2 ))
                local cy=$(( (y1 + y2) / 2 ))
                $ADB shell input tap "$cx" "$cy"
                return 0
            fi
            return 1
        }

        # Tap Restaurant ID field (by accessibilityLabel)
        if tap_testid "login-restaurant-id"; then
            sleep 0.5
            $ADB shell input text "$RESTAURANT_ID"
            sleep 0.5
            # Dismiss keyboard before tapping next field
            $ADB shell input keyevent 4
            sleep 0.5
        else
            echo "Restaurant ID field not found (accessibilityLabel: login-restaurant-id)"
            exit 1
        fi

        # Tap Password field (by accessibilityLabel)
        if tap_testid "login-password"; then
            sleep 0.5
            $ADB shell input text "$PASSWORD"
            sleep 0.5
            # Dismiss keyboard
            $ADB shell input keyevent 4
            sleep 0.5
        else
            echo "Password field not found (accessibilityLabel: login-password)"
            exit 1
        fi

        # Tap Login button (by testID)
        if tap_testid "login-button"; then
            echo "Login button tapped. Waiting for app to load..."
            sleep 5
            echo "Login complete. Use 'emu.sh shot' to verify."
        else
            echo "Login button not found (accessibilityLabel: login-button)"
            exit 1
        fi

        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        ;;

    tap-id)
        # Tap on any UI element by its accessibilityLabel (content-desc)
        # Note: For React Native Paper components, use accessibilityLabel prop, not testID
        # Use -p flag for partial matching
        PARTIAL_MATCH=false
        if [ "$2" = "-p" ]; then
            PARTIAL_MATCH=true
            shift
        fi
        if [ -z "$2" ]; then
            echo "Usage: emu.sh tap-id [-p] <accessibilityLabel>"
            echo "  -p  Enable partial matching (contains)"
            echo "Example: emu.sh tap-id 'login-button'"
            echo "Example: emu.sh tap-id -p 'Crab'  # matches 'Crab Rangoon...'"
            exit 1
        fi
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        if [ "$PARTIAL_MATCH" = true ]; then
            TID_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i "content-desc=\"[^\"]*$2[^\"]*\"" | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        else
            TID_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep "content-desc=\"$2\"" | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        fi
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        if [ -n "$TID_BOUNDS" ]; then
            read x1 y1 x2 y2 <<< "$TID_BOUNDS"
            cx=$(( (x1 + x2) / 2 ))
            cy=$(( (y1 + y2) / 2 ))
            echo "Tapping testID='$2' at $cx, $cy"
            $ADB shell input tap "$cx" "$cy"
        else
            echo "Element with testID='$2' not found. Try 'emu.sh dump-all' to see available elements."
            exit 1
        fi
        ;;

    tap-text)
        # Tap on any UI element by its text content
        # Use -p flag for partial matching
        PARTIAL_MATCH=false
        if [ "$2" = "-p" ]; then
            PARTIAL_MATCH=true
            shift
        fi
        if [ -z "$2" ]; then
            echo "Usage: emu.sh tap-text [-p] <text>"
            echo "  -p  Enable partial matching (contains)"
            echo "Example: emu.sh tap-text 'Settings'"
            echo "Example: emu.sh tap-text -p 'Crab'  # matches 'Crab Rangoon...'"
            exit 1
        fi
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        if [ "$PARTIAL_MATCH" = true ]; then
            TT_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i "text=\"[^\"]*$2[^\"]*\"" | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        else
            TT_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep "text=\"$2\"" | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        fi
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

    tap-text-nth)
        # Tap the nth element matching a text pattern
        # Usage: emu.sh tap-text-nth <text> <index>
        # Examples:
        #   emu.sh tap-text-nth "Add Answer" 0   # Tap 1st "Add Answer"
        #   emu.sh tap-text-nth "Add Answer" 1   # Tap 2nd "Add Answer"
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: emu.sh tap-text-nth <text> <index>"
            echo "  index: 0-based index of which matching element to tap"
            echo ""
            echo "Examples:"
            echo "  emu.sh tap-text-nth 'Add Answer' 0   # Tap 1st 'Add Answer'"
            echo "  emu.sh tap-text-nth 'Add Answer' 1   # Tap 2nd 'Add Answer'"
            exit 1
        fi
        TEXT_PATTERN="$2"
        TEXT_INDEX="$3"

        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        echo "UI hierchary dumped to: /sdcard/ui.xml"

        # Find all matching elements and extract bounds
        MATCHES=$(cat /tmp/ui.xml | tr '>' '\n' | grep "text=\"$TEXT_PATTERN\"" | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')

        NUM_MATCHES=$(echo "$MATCHES" | grep -c .)
        if [ "$NUM_MATCHES" -eq 0 ] || [ -z "$MATCHES" ]; then
            echo "No elements found with text='$TEXT_PATTERN'"
            rm -f /tmp/ui.xml
            $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
            exit 1
        fi

        echo "Found $NUM_MATCHES elements with text='$TEXT_PATTERN'"

        # Get the nth match (0-indexed)
        SELECTED=$(echo "$MATCHES" | sed -n "$((TEXT_INDEX + 1))p")

        if [ -z "$SELECTED" ]; then
            echo "Index $TEXT_INDEX out of range. Found $NUM_MATCHES elements (indices 0-$((NUM_MATCHES - 1)))"
            rm -f /tmp/ui.xml
            $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
            exit 1
        fi

        read x1 y1 x2 y2 <<< "$SELECTED"
        cx=$(( (x1 + x2) / 2 ))
        cy=$(( (y1 + y2) / 2 ))
        echo "Tapping #$TEXT_INDEX at $cx, $cy"
        $ADB shell input tap "$cx" "$cy"

        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        ;;

    tap-nth)
        # Tap the nth element matching a content-desc or class pattern
        # Usage: emu.sh tap-nth <type> <pattern> <index>
        #   type: "desc" for content-desc, "class" for class name, "icon" for content-desc icons
        # Examples:
        #   emu.sh tap-nth icon Edit 0      # Tap 0th icon with content-desc containing "Edit"
        #   emu.sh tap-nth desc pencil 1    # Tap 1st element with content-desc containing "pencil"
        #   emu.sh tap-nth class ImageView 2 # Tap 2nd element of class ImageView
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            echo "Usage: emu.sh tap-nth <type> <pattern> <index>"
            echo "  type: desc (content-desc), class (class name), icon (same as desc)"
            echo ""
            echo "Examples:"
            echo "  emu.sh tap-nth icon Edit 0       # Tap 0th icon with Edit in content-desc"
            echo "  emu.sh tap-nth desc pencil 1     # Tap 1st element with pencil in content-desc"
            echo "  emu.sh tap-nth class ImageView 2 # Tap 2nd ImageView"
            exit 1
        fi
        TYPE="$2"
        PATTERN="$3"
        INDEX="$4"

        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null

        case "$TYPE" in
            desc|icon)
                # Find elements with content-desc containing pattern (case-insensitive)
                MATCHES=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i "content-desc=\"[^\"]*${PATTERN}[^\"]*\"" | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1,\2,\3,\4/')
                ;;
            class)
                # Find elements with class containing pattern
                MATCHES=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i "class=\"[^\"]*${PATTERN}[^\"]*\"" | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1,\2,\3,\4/')
                ;;
            *)
                echo "Unknown type: $TYPE. Use desc, icon, or class."
                rm -f /tmp/ui.xml
                $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
                exit 1
                ;;
        esac

        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null

        # Count matches
        MATCH_COUNT=$(echo "$MATCHES" | grep -c . 2>/dev/null || echo 0)

        if [ "$MATCH_COUNT" -eq 0 ]; then
            echo "No elements found matching $TYPE='$PATTERN'"
            echo "Try 'emu.sh dump-all' to see all elements with their attributes."
            exit 1
        fi

        # Get the nth match (0-indexed)
        SELECTED=$(echo "$MATCHES" | sed -n "$((INDEX + 1))p")

        if [ -z "$SELECTED" ]; then
            echo "Index $INDEX out of range. Found $MATCH_COUNT elements matching $TYPE='$PATTERN'"
            exit 1
        fi

        # Parse bounds and tap center
        x1=$(echo "$SELECTED" | cut -d, -f1)
        y1=$(echo "$SELECTED" | cut -d, -f2)
        x2=$(echo "$SELECTED" | cut -d, -f3)
        y2=$(echo "$SELECTED" | cut -d, -f4)
        cx=$(( (x1 + x2) / 2 ))
        cy=$(( (y1 + y2) / 2 ))

        echo "Found $MATCH_COUNT elements matching $TYPE='$PATTERN'"
        echo "Tapping #$INDEX at $cx, $cy"
        $ADB shell input tap "$cx" "$cy"
        ;;

    dump-all)
        # Dump UI hierarchy with full element details
        $ADB shell uiautomator dump /sdcard/ui.xml
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        echo "All elements with content-desc or text:"
        cat /tmp/ui.xml | tr '>' '\n' | grep -E '(content-desc="[^"]+"|text="[^"]+")' | \
            sed 's/.*class="\([^"]*\)".*content-desc="\([^"]*\)".*bounds="\([^"]*\)".*/  class=\1 desc="\2" bounds=\3/' | \
            sed 's/.*class="\([^"]*\)".*text="\([^"]*\)".*bounds="\([^"]*\)".*/  class=\1 text="\2" bounds=\3/' | \
            grep -v "^  $" | head -50
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        ;;

    dump-texts)
        # Get all unique text values in the UI
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        echo "All text values in UI:"
        grep -o 'text="[^"]*"' /tmp/ui.xml | sort -u | sed 's/text="//; s/"$//'
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        ;;

    dump-descs)
        # Get all unique content-desc values in the UI
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        echo "All content-desc values in UI:"
        grep -o 'content-desc="[^"]*"' /tmp/ui.xml | sort -u | sed 's/content-desc="//; s/"$//' | grep -v "^$"
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
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

    eiu|run-eiu)
        # Don't run this automatically - it takes 2-3 minutes and looks stuck
        echo "To rebuild with clean state, run in a terminal:"
        echo ""
        echo "  /Users/carlos/Code/spark-agent-tools/run-eiu.sh"
        echo ""
        echo "This takes ~2-3 minutes (clears caches, starts emulator, builds app)."
        ;;

    dismiss-logbox|dlb)
        # Dismiss React Native LogBox yellow warning bar
        # The X button is at the right side of the warning bar
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        $ADB pull /sdcard/ui.xml /tmp/ui.xml 2>/dev/null
        # Look for the warning bar text
        LOGBOX_BOUNDS=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i 'Open debugger to view warnings' | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/')
        rm -f /tmp/ui.xml
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
        if [ -n "$LOGBOX_BOUNDS" ]; then
            read x1 y1 x2 y2 <<< "$LOGBOX_BOUNDS"
            # The X button is at the far right of the bar, vertically centered
            cx=$(( x2 - 40 ))  # ~40px from right edge
            cy=$(( (y1 + y2) / 2 ))
            echo "LogBox found. Tapping X at $cx, $cy"
            $ADB shell input tap "$cx" "$cy"
        else
            echo "No LogBox warning bar found"
        fi
        ;;

    clear-db|cdb)
        # Clear PowerSync database to force fresh sync from server
        PKG="com.starter.pad"
        echo "Stopping app..."
        $ADB shell am force-stop "$PKG" 2>/dev/null || true
        sleep 1
        echo "Clearing PowerSync database..."
        $ADB shell run-as "$PKG" rm -f databases/sparkpos-powersync-v1.db 2>/dev/null || true
        $ADB shell run-as "$PKG" rm -f databases/sparkpos-powersync-v1.db-shm 2>/dev/null || true
        $ADB shell run-as "$PKG" rm -f databases/sparkpos-powersync-v1.db-wal 2>/dev/null || true
        # Verify deletion
        REMAINING=$($ADB shell run-as "$PKG" ls databases/ 2>/dev/null | grep powersync || true)
        if [ -z "$REMAINING" ]; then
            echo "PowerSync database cleared successfully"
        else
            echo "Warning: Some files may remain: $REMAINING"
        fi
        echo "Restart the app to sync fresh data from server"
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

    scroll-down)
        # Scroll down at optional x,y coordinates (default: screen center)
        CX="${2:-1280}"
        CY="${3:-800}"
        START_Y=$((CY + 200))
        END_Y=$((CY - 200))
        echo "Scrolling down at ($CX, $CY)"
        $ADB shell input swipe "$CX" "$START_Y" "$CX" "$END_Y" 300
        ;;

    scroll-up)
        # Scroll up at optional x,y coordinates (default: screen center)
        CX="${2:-1280}"
        CY="${3:-800}"
        START_Y=$((CY - 200))
        END_Y=$((CY + 200))
        echo "Scrolling up at ($CX, $CY)"
        $ADB shell input swipe "$CX" "$START_Y" "$CX" "$END_Y" 300
        ;;

    scroll-left)
        # Scroll left at optional x,y coordinates (default: screen center)
        CX="${2:-1280}"
        CY="${3:-800}"
        START_X=$((CX + 200))
        END_X=$((CX - 200))
        echo "Scrolling left at ($CX, $CY)"
        $ADB shell input swipe "$START_X" "$CY" "$END_X" "$CY" 300
        ;;

    scroll-right)
        # Scroll right at optional x,y coordinates (default: screen center)
        CX="${2:-1280}"
        CY="${3:-800}"
        START_X=$((CX - 200))
        END_X=$((CX + 200))
        echo "Scrolling right at ($CX, $CY)"
        $ADB shell input swipe "$START_X" "$CY" "$END_X" "$CY" 300
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
        echo "  tap-id <testID>         - Tap element by testID (content-desc)"
        echo "  tap-element <s>.<e>     - Tap element by name from UI map"
        echo "  tap-nth <type> <pat> <n> - Tap nth element by desc/class (e.g., 'icon Edit 0')"
        echo "  swipe <x1> <y1> <x2> <y2> - Swipe gesture"
        echo "  text <string>           - Type text"
        echo "  key <keycode>           - Press key (back/home/enter/del)"
        echo "  size                    - Get screen dimensions"
        echo "  list                    - List devices"
        echo "  wait                    - Wait for emulator"
        echo "  device                  - Show current device"
        echo "  dump                    - Dump UI hierarchy, show clickable elements"
        echo "  dump-all                - Dump all elements with content-desc/text"
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
        echo "  nav-menu                - Navigate to Menu home (POS ordering screen)"
        echo "  nav-settings            - Open Settings (needs FORCE_SETTINGS_UNLOCKED)"
        echo "  nav-card-reader         - Navigate to Card Reader settings"
        echo "  nav-menu-settings       - Navigate to Menu Settings page"
        echo "  nav-menu-editor         - Navigate to Menu Editor (full path)"
        echo "  login [id] [pw]         - Login (default: 23/password)"
        echo "  tap-text <text>         - Tap UI element by its text content"
        echo "  tap-text-nth <text> <n> - Tap nth element with text (0-indexed)"
        echo "  setup-card-reader       - Full card reader setup (Link → Activate → Check Connection)"
        echo "  dismiss-logbox          - Dismiss React Native yellow warning bar"
        echo "  clear-db                - Clear PowerSync database (force fresh sync)"
        echo ""
        echo "Scrolling:"
        echo "  scroll-down [x] [y]     - Scroll down at center or specified coordinates"
        echo "  scroll-up [x] [y]       - Scroll up at center or specified coordinates"
        echo "  scroll-left [x] [y]     - Scroll left at center or specified coordinates"
        echo "  scroll-right [x] [y]    - Scroll right at center or specified coordinates"
        ;;
esac
