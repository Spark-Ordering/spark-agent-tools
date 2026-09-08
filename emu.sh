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

# Default package - use dev variant since that's what we run 99% of the time
DEFAULT_PKG="com.starter.paddev"

# Scroll defaults
SCROLL_DISTANCE=300    # screenshot pixels
SCROLL_DURATION=500    # milliseconds
SWIPE_DURATION=300     # milliseconds (for raw swipe command)

# Find the emulator device (prefer emulator over physical device)
# Honors ANDROID_SERIAL env var if set — needed when multiple emulators are running
# (e.g. ENG-2124 paired-tablet testing with WORKER_1 + WORKER_2).
get_device() {
    if [ -n "${ANDROID_SERIAL:-}" ]; then
        echo "$ANDROID_SERIAL"
        return
    fi
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
            # Resize to max 2000px to avoid Claude API "many-image" limit
            sips --resampleHeightWidthMax 2000 /tmp/screen.png --out /tmp/screen.png >/dev/null 2>&1
            echo "/tmp/screen.png"
        else
            echo "Error: Screenshot timed out (15s). Emulator may be slow or unresponsive."
            exit 1
        fi
        ;;

    record-start|rec-start|rs)
        # Start screen recording on the emulator in the background.
        # Writes the PID of the local nohup wrapper to /tmp/emu-record.pid.
        # adb screenrecord enforces a max duration; we set 180s (its hard cap).
        # Use record-stop to pull the file early.
        if [ -f /tmp/emu-record.pid ] && kill -0 "$(cat /tmp/emu-record.pid)" 2>/dev/null; then
            echo "Error: A recording is already in progress (pid $(cat /tmp/emu-record.pid)). Run 'emu.sh record-stop' first."
            exit 1
        fi
        $ADB shell rm -f /sdcard/emu-record.mp4 >/dev/null 2>&1
        # Capture host clock at the moment recording starts. record-trim-from
        # reads this to compute the offset of a maestro.log timestamp into
        # the video. Stored as fractional epoch seconds.
        date +%s.%N > /tmp/emu-record-host-start.txt
        nohup $ADB shell screenrecord --time-limit 180 /sdcard/emu-record.mp4 >/tmp/emu-record.log 2>&1 &
        echo $! > /tmp/emu-record.pid
        echo "Recording started (pid $(cat /tmp/emu-record.pid)). Run 'emu.sh record-stop' to finalize."
        ;;

    record-stop|rec-stop|re)
        # Stop the in-progress recording, pull the file, print the path.
        if [ ! -f /tmp/emu-record.pid ]; then
            echo "Error: No recording in progress (no /tmp/emu-record.pid)."
            exit 1
        fi
        REC_PID=$(cat /tmp/emu-record.pid)
        # Kill the local nohup wrapper; the on-device screenrecord process
        # gets SIGINT-equivalent via adb when the shell session ends, which
        # cleanly flushes the .mp4 (raw kill -9 truncates the file).
        kill -INT "$REC_PID" 2>/dev/null
        # Also kill the on-device screenrecord process so the file finalizes.
        $ADB shell "pkill -INT screenrecord" >/dev/null 2>&1
        # screenrecord needs ~2s to finalize the file after SIGINT.
        sleep 3
        rm -f /tmp/emu-record.pid
        $ADB pull /sdcard/emu-record.mp4 /tmp/emu-record.mp4 >/dev/null 2>&1
        if [ ! -f /tmp/emu-record.mp4 ] || [ ! -s /tmp/emu-record.mp4 ]; then
            echo "Error: Failed to pull /sdcard/emu-record.mp4 (file missing or empty)."
            exit 1
        fi
        $ADB shell rm -f /sdcard/emu-record.mp4 >/dev/null 2>&1
        echo "/tmp/emu-record.mp4"
        ;;

    record-trim-from|rec-trim-from|rtf)
        # Trim a screen recording to start at the moment a maestro.log line first
        # appears. Reads the recording's host start time from
        # /tmp/emu-record-host-start.txt (written by record-start), greps the
        # latest ~/.maestro/tests/*/maestro.log for the first line matching
        # <pattern>, parses its HH:MM:SS.mmm timestamp, subtracts to get the
        # offset into the recording, and ffmpeg-trims there.
        #
        # Usage:
        #   emu.sh record-trim-from "<pattern>" [input.mp4] [output.mp4]
        # Examples:
        #   emu.sh record-trim-from "Enter PIN"
        #   emu.sh record-trim-from "login.yaml... COMPLETED"
        #   emu.sh record-trim-from "order-type-DINE_IN"
        PATTERN="$2"
        TF_INPUT="${3:-/tmp/emu-record.mp4}"
        TF_OUTPUT="${4:-/tmp/emu-record-trimmed.mp4}"
        if [ -z "$PATTERN" ]; then
            echo "Usage: emu.sh record-trim-from \"<log-pattern>\" [input.mp4] [output.mp4]"
            exit 1
        fi
        if [ ! -f /tmp/emu-record-host-start.txt ]; then
            echo "Error: /tmp/emu-record-host-start.txt not found. Recording must be started via 'emu.sh record-start' (which writes the host clock)."
            exit 1
        fi
        if [ ! -f "$TF_INPUT" ]; then
            echo "Error: input file not found: $TF_INPUT"
            exit 1
        fi
        if ! command -v ffmpeg >/dev/null 2>&1; then
            echo "Error: ffmpeg not found on PATH (brew install ffmpeg)"
            exit 1
        fi
        REC_START=$(cat /tmp/emu-record-host-start.txt)

        LATEST_LOG=$(ls -t ~/.maestro/tests/*/maestro.log 2>/dev/null | head -1)
        if [ -z "$LATEST_LOG" ]; then
            echo "Error: no maestro.log found under ~/.maestro/tests/"
            exit 1
        fi

        LOG_LINE=$(grep -m 1 "$PATTERN" "$LATEST_LOG")
        if [ -z "$LOG_LINE" ]; then
            echo "Error: pattern '$PATTERN' not found in $LATEST_LOG"
            exit 1
        fi
        # maestro.log line prefix is HH:MM:SS.mmm (e.g., 14:48:42.123)
        LOG_TIME_STR=$(echo "$LOG_LINE" | grep -oE '^[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+' | head -1)
        if [ -z "$LOG_TIME_STR" ]; then
            echo "Error: could not parse HH:MM:SS.mmm timestamp from log line:"
            echo "  $LOG_LINE"
            exit 1
        fi

        # Convert log HH:MM:SS to today's epoch on macOS (BSD date).
        TODAY=$(date "+%Y-%m-%d")
        LOG_HMS="${LOG_TIME_STR%.*}"
        LOG_FRAC="${LOG_TIME_STR#*.}"
        LOG_EPOCH_INT=$(date -j -f "%Y-%m-%d %H:%M:%S" "$TODAY $LOG_HMS" "+%s" 2>/dev/null)
        if [ -z "$LOG_EPOCH_INT" ]; then
            echo "Error: could not convert log timestamp '$LOG_TIME_STR' to epoch"
            exit 1
        fi
        LOG_EPOCH="${LOG_EPOCH_INT}.${LOG_FRAC}"

        OFFSET=$(echo "$LOG_EPOCH - $REC_START" | bc -l)
        # Strip any leading "." (bc returns ".5" for 0.5 etc.)
        case "$OFFSET" in
          .*) OFFSET="0$OFFSET" ;;
          -.*) OFFSET="-0${OFFSET#-}" ;;
        esac
        if [ "$(echo "$OFFSET < 0" | bc -l)" = "1" ]; then
            echo "Error: log line is before recording start (offset=${OFFSET}s). Was recording started after the test?"
            echo "  recording start: $REC_START"
            echo "  log line time:   $LOG_EPOCH"
            echo "  log line:        $LOG_LINE"
            exit 1
        fi

        echo "Matched log line (truncated):" >&2
        echo "  $(echo "$LOG_LINE" | cut -c1-120)" >&2
        echo "Trim offset: ${OFFSET}s" >&2

        ffmpeg -y -i "$TF_INPUT" -ss "$OFFSET" \
            -vf "scale=1080:-2" -c:v libx264 -preset slow -crf 28 -an \
            "$TF_OUTPUT" >/dev/null 2>&1
        if [ ! -s "$TF_OUTPUT" ]; then
            echo "Error: ffmpeg failed to produce $TF_OUTPUT"
            exit 1
        fi
        echo "$TF_OUTPUT"
        ;;

    record-trim|rec-trim|rt)
        # Trim leading seconds off a screen recording (skips app splash / launch
        # animation so the demo starts at the first interactive screen).
        # Defaults: input=/tmp/emu-record.mp4, output=/tmp/emu-record-trimmed.mp4, seconds=5.
        # Re-encodes (CRF 28, scale 1080:-2, no audio) so the output is small enough
        # for GitHub user-attachments (10MB cap) and the cut starts on a keyframe
        # (-ss before -i would cut on the nearest preceding keyframe and miss the
        # right starting point).
        REC_TRIM_INPUT="${2:-/tmp/emu-record.mp4}"
        REC_TRIM_OUTPUT="${3:-/tmp/emu-record-trimmed.mp4}"
        REC_TRIM_SECONDS="${4:-5}"
        if [ ! -f "$REC_TRIM_INPUT" ]; then
            echo "Error: input file not found: $REC_TRIM_INPUT"
            echo "Usage: emu.sh record-trim [input.mp4] [output.mp4] [seconds]"
            exit 1
        fi
        if ! command -v ffmpeg >/dev/null 2>&1; then
            echo "Error: ffmpeg not found on PATH (brew install ffmpeg)"
            exit 1
        fi
        # -ss AFTER -i = frame-accurate seek (slower decode pass, but precise to
        # the second). screenrecord uses long GOP intervals, so input-side -ss
        # would snap forward to the next keyframe and overshoot by 5-10s.
        ffmpeg -y -i "$REC_TRIM_INPUT" -ss "$REC_TRIM_SECONDS" \
            -vf "scale=1080:-2" -c:v libx264 -preset slow -crf 28 -an \
            "$REC_TRIM_OUTPUT" >/dev/null 2>&1
        if [ ! -f "$REC_TRIM_OUTPUT" ] || [ ! -s "$REC_TRIM_OUTPUT" ]; then
            echo "Error: ffmpeg failed to produce $REC_TRIM_OUTPUT"
            exit 1
        fi
        echo "$REC_TRIM_OUTPUT"
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
        duration="${6:-$SWIPE_DURATION}"
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
        # Select all text (Ctrl+A) then delete, then type new text
        $ADB shell input keyevent KEYCODE_CTRL_A
        sleep 0.1
        $ADB shell input keyevent KEYCODE_DEL
        sleep 0.1
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
        # Use --e2e flag to launch in E2E mode (mock Finix, etc.)
        shift  # remove "start"/"launch"
        E2E_ARGS=""
        PKG="$DEFAULT_PKG"
        for arg in "$@"; do
            if [ "$arg" = "--e2e" ]; then
                E2E_ARGS="--ez e2e_mode true"
                echo "E2E mode enabled"
            elif [[ "$arg" != --* ]]; then
                PKG="$arg"
            fi
        done
        ACT="com.starter.pad.MainActivity"
        echo "Starting $PKG..."
        $ADB shell am force-stop "$PKG" 2>/dev/null
        sleep 1
        $ADB shell am start -n "$PKG/$ACT" $E2E_ARGS
        echo "Waiting for app to load (up to 45s)..."
        for i in $(seq 1 9); do
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
            echo "  ...waiting (${i}0s / 45s)"
        done
        echo "App started. Use 'emu.sh shot' to check screen."
        ;;

    start-e2e)
        # Start SparkPos in E2E mode with a ready token
        # Usage: emu.sh start-e2e [token] [pkg]
        shift
        TOKEN="${1:-$(date +%s | tail -c 7)}"
        PKG="${2:-$DEFAULT_PKG}"
        ACT="com.starter.pad.MainActivity"
        echo "Starting $PKG in E2E mode (token: $TOKEN)..."
        $ADB shell am force-stop "$PKG" 2>/dev/null
        sleep 1
        $ADB shell am start -n "$PKG/$ACT" --ez e2e_mode true --es e2e_ready_token "$TOKEN"
        echo "Waiting for app to load..."
        for i in $(seq 1 9); do
            sleep 5
            if $ADB shell pidof "$PKG" >/dev/null 2>&1; then
                echo "App running (${i}0s). Token: $TOKEN"
                break
            fi
            echo "  ...waiting (${i}0s / 45s)"
        done
        echo "Use 'emu.sh dump-all' to check if token is visible."
        ;;

    stop|kill)
        PKG="${2:-$DEFAULT_PKG}"
        $ADB shell am force-stop "$PKG"
        echo "Stopped $PKG"
        ;;

    restart)
        PKG="${2:-$DEFAULT_PKG}"
        "$0" stop "$PKG"
        sleep 2
        "$0" start "$PKG"
        ;;

    alive|running)
        # Check if app is running (exit 0 = yes, exit 1 = no)
        PKG="${2:-$DEFAULT_PKG}"
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

    kill-metro)
        # Kill Metro bundler process
        METRO_PID=$(lsof -ti :8081 2>/dev/null | head -1)
        if [ -n "$METRO_PID" ]; then
            kill $METRO_PID
            echo "Killed Metro (PID $METRO_PID)"
        else
            echo "Metro not running"
        fi
        ;;

    watchman-clear)
        # Clear watchman cache to force file re-indexing
        watchman watch-del-all 2>/dev/null
        echo "Watchman cache cleared"
        ;;

    metro-restart|metro-reset)
        # Kill Metro and restart with cache reset
        # This forces Metro to re-bundle JavaScript with latest code
        METRO_PID=$(lsof -ti :8081 2>/dev/null | head -1)
        if [ -n "$METRO_PID" ]; then
            kill -9 $METRO_PID 2>/dev/null
            echo "Killed Metro (PID $METRO_PID)"
            sleep 2
        else
            echo "Metro was not running"
        fi

        # Start Metro in background with cache reset
        cd $HOME/Code/SparkPos
        echo "Starting Metro with cache reset..."
        npx react-native start --reset-cache &
        METRO_NEW_PID=$!

        # Wait for Metro to be ready (up to 30 seconds)
        for i in {1..30}; do
            sleep 1
            STATUS=$(curl -s --connect-timeout 2 http://localhost:8081/status 2>/dev/null)
            if [ "$STATUS" = "packager-status:running" ]; then
                echo "Metro started (PID $METRO_NEW_PID)"
                exit 0
            fi
            echo -n "."
        done
        echo ""
        echo "Warning: Metro may still be starting..."
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

    nav-order-list)
        # Navigate to Order List from home screen
        echo "Opening hamburger menu..."
        $ADB shell input tap 56 64
        sleep 2
        echo "Tapping Order List..."
        "$0" tap-text "Order List"
        sleep 2
        echo "Order List opened. Use 'emu.sh shot' to verify."
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
        # Login with test credentials (Restaurant ID: 23, Password: password, PIN: 5942)
        # Handles three states: login screen, PIN screen, or already on home
        # Uses "$0" tap-text/tap-id for all element interaction
        RESTAURANT_ID="${2:-23}"
        PASSWORD="${3:-password}"
        PIN="${4:-5942}"

        # Kill Maestro agent if running — it holds UiAutomation and blocks uiautomator dump
        $ADB shell am force-stop dev.mobile.maestro 2>/dev/null
        # Detect current screen via file-based dump
        $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
        SCREEN_TEXT=$($ADB shell cat /sdcard/ui.xml 2>/dev/null || echo "")
        $ADB shell rm -f /sdcard/ui.xml 2>/dev/null

        if echo "$SCREEN_TEXT" | grep -q 'text="Enter PIN"'; then
            # On PIN screen
            echo "PIN screen detected. Entering PIN: $PIN"
            for digit in $(echo "$PIN" | grep -o .); do
                "$0" tap-text "$digit"
                sleep 0.5
            done
            sleep 5
            echo "PIN entered."

        elif echo "$SCREEN_TEXT" | grep -q 'login-restaurant-id'; then
            # On login screen
            echo "Logging in with Restaurant ID: $RESTAURANT_ID"
            "$0" tap-id "login-restaurant-id"
            sleep 0.5
            $ADB shell input text "$RESTAURANT_ID"
            sleep 0.5
            $ADB shell input keyevent 4
            sleep 0.5

            "$0" tap-id "login-password"
            sleep 0.5
            $ADB shell input text "$PASSWORD"
            sleep 0.5
            $ADB shell input keyevent 4
            sleep 0.5

            "$0" tap-id "login-button"
            echo "Login button tapped. Waiting..."
            sleep 8

            # Check if PIN screen appeared after login
            $ADB shell uiautomator dump /sdcard/ui.xml 2>/dev/null
            SCREEN_TEXT2=$($ADB shell cat /sdcard/ui.xml 2>/dev/null || echo "")
            $ADB shell rm -f /sdcard/ui.xml 2>/dev/null
            if echo "$SCREEN_TEXT2" | grep -q 'text="Enter PIN"'; then
                echo "PIN screen appeared. Entering PIN: $PIN"
                for digit in $(echo "$PIN" | grep -o .); do
                    "$0" tap-text "$digit"
                    sleep 0.5
                done
                sleep 5
                echo "PIN entered."
            fi
        else
            echo "Already on home screen or unknown screen. Use 'emu.sh shot' to check."
        fi

        echo "Login complete. Use 'emu.sh shot' to verify."
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
        # Tap the nth element matching a content-desc, text, or class pattern
        # Usage: emu.sh tap-nth <type> <pattern> <index>
        #   type: "desc" for content-desc, "text" for visible text, "class" for class name, "icon" for content-desc icons
        # Examples:
        #   emu.sh tap-nth icon Edit 0      # Tap 0th icon with content-desc containing "Edit"
        #   emu.sh tap-nth desc pencil 1    # Tap 1st element with content-desc containing "pencil"
        #   emu.sh tap-nth text "Add Item" 0 # Tap 0th element with text containing "Add Item"
        #   emu.sh tap-nth class ImageView 2 # Tap 2nd element of class ImageView
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            echo "Usage: emu.sh tap-nth <type> <pattern> <index>"
            echo "  type: desc (content-desc), text (visible text), class (class name), icon (same as desc)"
            echo ""
            echo "Examples:"
            echo "  emu.sh tap-nth icon Edit 0       # Tap 0th icon with Edit in content-desc"
            echo "  emu.sh tap-nth desc pencil 1     # Tap 1st element with pencil in content-desc"
            echo "  emu.sh tap-nth text 'Add Item' 0 # Tap 0th element with 'Add Item' in text"
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
            text)
                # Find elements with text containing pattern (case-insensitive)
                MATCHES=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i "text=\"[^\"]*${PATTERN}[^\"]*\"" | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1,\2,\3,\4/')
                ;;
            class)
                # Find elements with class containing pattern
                MATCHES=$(cat /tmp/ui.xml | tr '>' '\n' | grep -i "class=\"[^\"]*${PATTERN}[^\"]*\"" | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1,\2,\3,\4/')
                ;;
            *)
                echo "Unknown type: $TYPE. Use desc, icon, text, or class."
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
        # Keep the full raw hierarchy on disk as a backup — the printout above is
        # capped at 50 lines and drops empty desc/text, so inspect this file when
        # something you expect (e.g. a specific content-desc) is missing above.
        echo ""
        echo "Full raw hierarchy saved to: /tmp/ui.xml"
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
        echo "  $HOME/Code/spark-agent-tools/run-eiu.sh"
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
        PKG="$DEFAULT_PKG"
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

    mark)
        # Draw red dots on screenshot to visualize tap/swipe coordinates
        # Coordinates are in SCREENSHOT space (max 2000px)
        # Usage: emu.sh mark <x1> <y1> [x2 y2 ...] [--swipe]
        #   --swipe: draw a line between first and second point
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: emu.sh mark <x1> <y1> [x2 y2 ...] [--swipe]"
            echo "  Draws red dots on /tmp/screen.png at given coordinates"
            echo "  Coordinates are in screenshot space (max 2000px)"
            echo "  --swipe: also draw an arrow between first two points"
            echo "  Output: /tmp/screen_marked.png"
            exit 1
        fi
        if [ ! -f /tmp/screen.png ]; then
            echo "Error: /tmp/screen.png not found. Run 'emu.sh shot' first."
            exit 1
        fi
        # Collect points and check for --swipe flag
        DRAW_SWIPE=false
        POINTS=()
        shift  # remove 'mark'
        while [ $# -gt 0 ]; do
            if [ "$1" = "--swipe" ]; then
                DRAW_SWIPE=true
                shift
            else
                POINTS+=("$1")
                shift
            fi
        done
        # Build magick draw commands
        DRAW_ARGS=""
        i=0
        while [ $i -lt ${#POINTS[@]} ]; do
            x="${POINTS[$i]}"
            y="${POINTS[$((i+1))]}"
            if [ -n "$x" ] && [ -n "$y" ]; then
                DRAW_ARGS="$DRAW_ARGS -fill red -stroke white -strokewidth 2 -draw \"circle $x,$y $((x+12)),$y\""
                DRAW_ARGS="$DRAW_ARGS -fill white -pointsize 16 -stroke none -draw \"text $((x+16)),$((y+5)) '($x,$y)'\""
            fi
            i=$((i + 2))
        done
        # Draw swipe arrow between first two points
        if $DRAW_SWIPE && [ ${#POINTS[@]} -ge 4 ]; then
            x1="${POINTS[0]}"
            y1="${POINTS[1]}"
            x2="${POINTS[2]}"
            y2="${POINTS[3]}"
            DRAW_ARGS="$DRAW_ARGS -stroke red -strokewidth 3 -draw \"line $x1,$y1 $x2,$y2\""
            # Arrowhead
            DRAW_ARGS="$DRAW_ARGS -fill red -stroke red -strokewidth 2 -draw \"circle $x2,$y2 $((x2+8)),$y2\""
        fi
        eval magick /tmp/screen.png $DRAW_ARGS /tmp/screen_marked.png
        echo "/tmp/screen_marked.png"
        ;;

    to-device)
        # Convert screenshot coordinates to device coordinates
        # Screenshot is max 2000px, device is 2560x1600
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: emu.sh to-device <screenshot_x> <screenshot_y>"
            exit 1
        fi
        # Get actual screenshot dimensions
        if [ ! -f /tmp/screen.png ]; then
            echo "Error: /tmp/screen.png not found. Run 'emu.sh shot' first."
            exit 1
        fi
        SHOT_W=$(sips -g pixelWidth /tmp/screen.png 2>/dev/null | tail -1 | awk '{print $2}')
        SHOT_H=$(sips -g pixelHeight /tmp/screen.png 2>/dev/null | tail -1 | awk '{print $2}')
        DEV_SIZE=$($ADB shell wm size 2>/dev/null | grep -o '[0-9]*x[0-9]*')
        DEV_W=$(echo "$DEV_SIZE" | cut -dx -f1)
        DEV_H=$(echo "$DEV_SIZE" | cut -dx -f2)
        # Scale
        DX=$(python3 -c "print(int($2 * $DEV_W / $SHOT_W))")
        DY=$(python3 -c "print(int($3 * $DEV_H / $SHOT_H))")
        echo "$DX $DY"
        ;;

    scroll-down)
        # Scroll down at optional x,y coordinates (default: screen center)
        CX="${2:-1280}"
        CY="${3:-800}"
        START_Y=$((CY + 200))
        END_Y=$((CY - 200))
        echo "Scrolling down at ($CX, $CY)"
        $ADB shell input swipe "$CX" "$START_Y" "$CX" "$END_Y" "$SCROLL_DURATION"
        ;;

    scroll-up)
        # Scroll up at optional x,y coordinates (default: screen center)
        CX="${2:-1280}"
        CY="${3:-800}"
        START_Y=$((CY - 200))
        END_Y=$((CY + 200))
        echo "Scrolling up at ($CX, $CY)"
        $ADB shell input swipe "$CX" "$START_Y" "$CX" "$END_Y" "$SCROLL_DURATION"
        ;;

    scroll-left)
        # Scroll left at optional x,y coordinates (default: screen center)
        CX="${2:-1280}"
        CY="${3:-800}"
        START_X=$((CX + 200))
        END_X=$((CX - 200))
        echo "Scrolling left at ($CX, $CY)"
        $ADB shell input swipe "$START_X" "$CY" "$END_X" "$CY" "$SCROLL_DURATION"
        ;;

    scroll-right)
        # Scroll right at optional x,y coordinates (default: screen center)
        CX="${2:-1280}"
        CY="${3:-800}"
        START_X=$((CX - 200))
        END_X=$((CX + 200))
        echo "Scrolling right at ($CX, $CY)"
        $ADB shell input swipe "$START_X" "$CY" "$END_X" "$CY" "$SCROLL_DURATION"
        ;;

    sd)
        # Scroll down using SCREENSHOT coordinates (auto-scales to device pixels)
        # Usage: emu.sh sd <screenshot_x> <screenshot_y> [distance]
        # distance = scroll distance in screenshot pixels (default: SCROLL_DISTANCE)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: emu.sh sd <screenshot_x> <screenshot_y> [distance]"
            echo "  Scroll down at screenshot coordinates (auto-scales to device pixels)"
            echo "  distance: scroll distance in screenshot pixels (default: $SCROLL_DISTANCE)"
            exit 1
        fi
        if [ ! -f /tmp/screen.png ]; then
            echo "Error: /tmp/screen.png not found. Run 'emu.sh shot' first."
            exit 1
        fi
        SHOT_W=$(sips -g pixelWidth /tmp/screen.png 2>/dev/null | tail -1 | awk '{print $2}')
        SHOT_H=$(sips -g pixelHeight /tmp/screen.png 2>/dev/null | tail -1 | awk '{print $2}')
        DEV_SIZE=$($ADB shell wm size 2>/dev/null | grep -o '[0-9]*x[0-9]*')
        DEV_W=$(echo "$DEV_SIZE" | cut -dx -f1)
        DEV_H=$(echo "$DEV_SIZE" | cut -dx -f2)
        DIST="${4:-$SCROLL_DISTANCE}"
        # Convert screenshot coords to device coords
        DX=$(python3 -c "print(int($2 * $DEV_W / $SHOT_W))")
        DY=$(python3 -c "print(int($3 * $DEV_H / $SHOT_H))")
        DD=$(python3 -c "print(int($DIST * $DEV_H / $SHOT_H))")
        START_Y=$((DY + DD / 2))
        END_Y=$((DY - DD / 2))
        echo "Scroll down: screenshot ($2,$3) → device ($DX,$DY), distance=$DD"
        $ADB shell input swipe "$DX" "$START_Y" "$DX" "$END_Y" "$SCROLL_DURATION"
        ;;

    su)
        # Scroll up using SCREENSHOT coordinates (auto-scales to device pixels)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: emu.sh su <screenshot_x> <screenshot_y> [distance]"
            echo "  Scroll up at screenshot coordinates (auto-scales to device pixels)"
            exit 1
        fi
        if [ ! -f /tmp/screen.png ]; then
            echo "Error: /tmp/screen.png not found. Run 'emu.sh shot' first."
            exit 1
        fi
        SHOT_W=$(sips -g pixelWidth /tmp/screen.png 2>/dev/null | tail -1 | awk '{print $2}')
        SHOT_H=$(sips -g pixelHeight /tmp/screen.png 2>/dev/null | tail -1 | awk '{print $2}')
        DEV_SIZE=$($ADB shell wm size 2>/dev/null | grep -o '[0-9]*x[0-9]*')
        DEV_W=$(echo "$DEV_SIZE" | cut -dx -f1)
        DEV_H=$(echo "$DEV_SIZE" | cut -dx -f2)
        DIST="${4:-$SCROLL_DISTANCE}"
        DX=$(python3 -c "print(int($2 * $DEV_W / $SHOT_W))")
        DY=$(python3 -c "print(int($3 * $DEV_H / $SHOT_H))")
        DD=$(python3 -c "print(int($DIST * $DEV_H / $SHOT_H))")
        START_Y=$((DY - DD / 2))
        END_Y=$((DY + DD / 2))
        echo "Scroll up: screenshot ($2,$3) → device ($DX,$DY), distance=$DD"
        $ADB shell input swipe "$DX" "$START_Y" "$DX" "$END_Y" "$SCROLL_DURATION"
        ;;

    *)
        echo "Android Emulator Control Script"
        echo ""
        echo "Usage: emu.sh <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  shot                    - Take screenshot (/tmp/screen.png)"
        echo "  wait-shot [tries] [delay] - Screenshot with retry (default 3 tries, 5s delay)"
        echo "  record-start            - Start screen recording on emulator (max 180s)"
        echo "  record-stop             - Stop recording and pull mp4 to /tmp/emu-record.mp4"
        echo "  record-trim [in] [out] [secs]  - Trim leading seconds (default 5s) off a recording.
                              Re-encodes for GitHub user-attachments size cap.
                              Defaults: in=/tmp/emu-record.mp4, out=/tmp/emu-record-trimmed.mp4"
        echo "  record-trim-from \"<pattern>\" [in] [out]  - Trim a recording to start at the moment
                              the latest maestro.log first matches <pattern>.
                              Recording must have been started via record-start."
        echo "  tap <x> <y>             - Tap at coordinates"
        echo "  tap-id <testID>         - Tap element by testID (content-desc)"
        echo "  tap-element <s>.<e>     - Tap element by name from UI map"
        echo "  tap-nth <type> <pat> <n> - Tap nth element by desc/text/class (e.g., 'text Crab 0')"
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
        echo "  start [pkg]             - Start app and wait for load (up to 45s)"
        echo "  stop [pkg]              - Force stop app"
        echo "  restart [pkg]           - Stop + start"
        echo "  alive [pkg]             - Check if app is running"
        echo "  metro-status            - Check if Metro bundler is alive"
        echo "  kill-metro              - Kill Metro bundler process"
        echo "  metro-restart           - Kill Metro and restart with cache reset"
        echo "  watchman-clear          - Clear watchman cache for file re-indexing"
        echo "  deploy [1|2|3]          - Full deploy + start + wait"
        echo ""
        echo "Navigation:"
        echo "  nav-menu                - Navigate to Menu home (POS ordering screen)"
        echo "  nav-settings            - Open Settings (needs FORCE_SETTINGS_UNLOCKED)"
        echo "  nav-card-reader         - Navigate to Card Reader settings"
        echo "  nav-menu-settings       - Navigate to Menu Settings page"
        echo "  nav-menu-editor         - Navigate to Menu Editor (full path)"
        echo "  nav-order-list          - Navigate to Order List"
        echo "  login [id] [pw] [pin]   - Login + PIN (default: 23/password/5942)"
        echo "  tap-text <text>         - Tap UI element by its text content"
        echo "  tap-text-nth <text> <n> - Tap nth element with text (0-indexed)"
        echo "  setup-card-reader       - Full card reader setup (Link → Activate → Check Connection)"
        echo "  dismiss-logbox          - Dismiss React Native yellow warning bar"
        echo "  clear-db                - Clear PowerSync database (force fresh sync)"
        echo ""
        echo "Scrolling:"
        echo "  scroll-down [x] [y]     - Scroll down (device coordinates)"
        echo "  scroll-up [x] [y]       - Scroll up (device coordinates)"
        echo "  scroll-left [x] [y]     - Scroll left (device coordinates)"
        echo "  scroll-right [x] [y]    - Scroll right (device coordinates)"
        echo "  sd <x> <y> [dist]       - Scroll down (screenshot coordinates, auto-scales)"
        echo "  su <x> <y> [dist]       - Scroll up (screenshot coordinates, auto-scales)"
        echo ""
        echo "Debug:"
        echo "  mark <x1> <y1> [x2 y2..] [--swipe] - Draw red dots on screenshot"
        echo "  to-device <x> <y>       - Convert screenshot coords to device coords"
        ;;
esac
