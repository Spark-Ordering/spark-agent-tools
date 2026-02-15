#!/bin/bash
# mac.sh — Mac computer use tool for Clawdbot
# Uses accessibility APIs + cliclick for reliable desktop automation
#
# Usage:
#   mac.sh shot [output_path]          — take screenshot
#   mac.sh click <x> <y>              — click at logical coords
#   mac.sh doubleclick <x> <y>        — double-click
#   mac.sh rightclick <x> <y>         — right-click
#   mac.sh type <text>                — type text
#   mac.sh key <key>                  — press key (return, escape, tab, delete, space)
#   mac.sh hotkey <mod> <key>         — press hotkey (cmd+w, cmd+q, etc.)
#   mac.sh frontmost                  — print frontmost app name
#   mac.sh list-windows               — list all visible windows with positions
#   mac.sh find-buttons <app>         — list buttons in app's frontmost window (click-ready coords)
#   mac.sh find-elements <app>        — list all UI elements in app's frontmost window
#   mac.sh close [app]                — close frontmost window (of app, or current)
#   mac.sh minimize [app]             — minimize frontmost window
#   mac.sh unminimize <app>           — unminimize most recent window
#   mac.sh maximize [app]             — full-screen toggle
#   mac.sh move <left|right|center>   — move frontmost window (uses resize script)
#   mac.sh focus <app>                — activate/focus app
#   mac.sh quit <app>                 — quit app
#   mac.sh mouse                      — print current mouse position

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CMD="${1:-help}"
shift 2>/dev/null || true

case "$CMD" in

shot)
    OUT="${1:-/tmp/screen.png}"
    /usr/sbin/screencapture -x "$OUT" 2>/dev/null
    echo "$OUT"
    ;;

click)
    X="$1"; Y="$2"
    [ -z "$X" ] || [ -z "$Y" ] && { echo "Usage: mac.sh click <x> <y>"; exit 1; }
    cliclick c:"$X","$Y" 2>/dev/null
    echo "Clicked ($X, $Y)"
    ;;

doubleclick)
    X="$1"; Y="$2"
    [ -z "$X" ] || [ -z "$Y" ] && { echo "Usage: mac.sh doubleclick <x> <y>"; exit 1; }
    cliclick dc:"$X","$Y" 2>/dev/null
    echo "Double-clicked ($X, $Y)"
    ;;

rightclick)
    X="$1"; Y="$2"
    [ -z "$X" ] || [ -z "$Y" ] && { echo "Usage: mac.sh rightclick <x> <y>"; exit 1; }
    cliclick rc:"$X","$Y" 2>/dev/null
    echo "Right-clicked ($X, $Y)"
    ;;

type)
    TEXT="$*"
    [ -z "$TEXT" ] && { echo "Usage: mac.sh type <text>"; exit 1; }
    osascript -e "tell application \"System Events\" to keystroke \"$TEXT\"" 2>/dev/null
    echo "Typed: $TEXT"
    ;;

key)
    KEY="$1"
    [ -z "$KEY" ] && { echo "Usage: mac.sh key <return|escape|tab|delete|space|up|down|left|right>"; exit 1; }
    case "$KEY" in
        return)  CODE=36 ;;
        escape)  CODE=53 ;;
        tab)     CODE=48 ;;
        delete)  CODE=51 ;;
        space)   CODE=49 ;;
        up)      CODE=126 ;;
        down)    CODE=125 ;;
        left)    CODE=123 ;;
        right)   CODE=124 ;;
        *)       echo "Unknown key: $KEY"; exit 1 ;;
    esac
    osascript -e "tell application \"System Events\" to key code $CODE" 2>/dev/null
    echo "Pressed: $KEY"
    ;;

hotkey)
    MOD="$1"; KEY="$2"
    [ -z "$MOD" ] || [ -z "$KEY" ] && { echo "Usage: mac.sh hotkey <cmd|opt|ctrl|shift> <key>"; exit 1; }
    case "$MOD" in
        cmd)    MOD_STR="command down" ;;
        opt)    MOD_STR="option down" ;;
        ctrl)   MOD_STR="control down" ;;
        shift)  MOD_STR="shift down" ;;
        *)      echo "Unknown modifier: $MOD (use cmd|opt|ctrl|shift)"; exit 1 ;;
    esac
    osascript -e "tell application \"System Events\" to keystroke \"$KEY\" using $MOD_STR" 2>/dev/null
    echo "Pressed: $MOD+$KEY"
    ;;

frontmost)
    osascript -e 'tell application "System Events" to return name of first application process whose frontmost is true' 2>/dev/null
    ;;

list-windows)
    osascript -e '
    tell application "System Events"
        set output to ""
        set procs to every application process whose visible is true
        repeat with p in procs
            set pName to name of p
            try
                set wins to every window of p
                repeat with w in wins
                    set wName to name of w
                    set wPos to position of w
                    set wSize to size of w
                    set output to output & pName & " | " & wName & " | pos=" & (item 1 of wPos) & "," & (item 2 of wPos) & " size=" & (item 1 of wSize) & "x" & (item 2 of wSize) & linefeed
                end repeat
            end try
        end repeat
        return output
    end tell' 2>/dev/null
    ;;

find-buttons)
    APP="$1"
    [ -z "$APP" ] && { echo "Usage: mac.sh find-buttons <app>"; exit 1; }
    osascript -e "
    tell application \"System Events\"
        tell process \"$APP\"
            set output to \"\"
            try
                set btns to every button of window 1
                repeat with b in btns
                    set bPos to position of b
                    set bSize to size of b
                    set bDesc to description of b
                    -- Return center coords (position is top-left)
                    set cx to (item 1 of bPos) + ((item 1 of bSize) / 2) as integer
                    set cy to (item 2 of bPos) + ((item 2 of bSize) / 2) as integer
                    set output to output & bDesc & \": click \" & cx & \" \" & cy & \" (pos=\" & (item 1 of bPos) & \",\" & (item 2 of bPos) & \" size=\" & (item 1 of bSize) & \"x\" & (item 2 of bSize) & \")\" & linefeed
                end repeat
            end try
            return output
        end tell
    end tell" 2>/dev/null
    ;;

find-elements)
    APP="$1"
    [ -z "$APP" ] && { echo "Usage: mac.sh find-elements <app>"; exit 1; }
    osascript -e "
    tell application \"System Events\"
        tell process \"$APP\"
            set output to \"\"
            try
                set elems to entire contents of window 1
                repeat with e in elems
                    try
                        set eRole to role of e
                        set eDesc to description of e
                        set ePos to position of e
                        set eSize to size of e
                        set cx to (item 1 of ePos) + ((item 1 of eSize) / 2) as integer
                        set cy to (item 2 of ePos) + ((item 2 of eSize) / 2) as integer
                        if eDesc is not \"\" then
                            set output to output & eRole & \" \\\"\" & eDesc & \"\\\" center=\" & cx & \",\" & cy & linefeed
                        end if
                    end try
                end repeat
            end try
            return output
        end tell
    end tell" 2>/dev/null
    ;;

close)
    APP="${1:-}"
    if [ -z "$APP" ]; then
        APP=$(osascript -e 'tell application "System Events" to return name of first application process whose frontmost is true' 2>/dev/null)
    fi
    osascript -e "
    tell application \"System Events\"
        tell process \"$APP\"
            try
                set bPos to position of button 1 of window 1
                set bSize to size of button 1 of window 1
            end try
        end tell
    end tell
    tell application \"$APP\"
        try
            close window 1
        on error
            tell application \"System Events\" to tell process \"$APP\" to click button 1 of window 1
        end try
    end tell" 2>/dev/null
    echo "Closed: $APP"
    ;;

minimize)
    APP="${1:-}"
    if [ -z "$APP" ]; then
        APP=$(osascript -e 'tell application "System Events" to return name of first application process whose frontmost is true' 2>/dev/null)
    fi
    osascript -e "tell application \"$APP\" to set miniaturized of window 1 to true" 2>/dev/null
    echo "Minimized: $APP"
    ;;

unminimize)
    APP="$1"
    [ -z "$APP" ] && { echo "Usage: mac.sh unminimize <app>"; exit 1; }
    osascript -e "
    tell application \"$APP\"
        try
            set miniaturized of window 1 to false
        end try
        activate
    end tell" 2>/dev/null
    echo "Unminimized: $APP"
    ;;

maximize)
    APP="${1:-}"
    if [ -z "$APP" ]; then
        APP=$(osascript -e 'tell application "System Events" to return name of first application process whose frontmost is true' 2>/dev/null)
    fi
    osascript -e "
    tell application \"System Events\"
        tell process \"$APP\"
            click button 2 of window 1
        end tell
    end tell" 2>/dev/null
    echo "Toggled fullscreen: $APP"
    ;;

move)
    POSITION="$1"
    [ -z "$POSITION" ] && { echo "Usage: mac.sh move <left|right|center|topleft|topright|bottomleft|bottomright>"; exit 1; }
    case "$POSITION" in
        left)
            osascript -e '
            tell application "System Events"
                set fp to first application process whose frontmost is true
                tell fp
                    set position of window 1 to {0, 25}
                    set size of window 1 to {855, 1082}
                end tell
            end tell' 2>/dev/null
            ;;
        right)
            osascript -e '
            tell application "System Events"
                set fp to first application process whose frontmost is true
                tell fp
                    set position of window 1 to {855, 25}
                    set size of window 1 to {855, 1082}
                end tell
            end tell' 2>/dev/null
            ;;
        center)
            osascript -e '
            tell application "System Events"
                set fp to first application process whose frontmost is true
                tell fp
                    set position of window 1 to {255, 100}
                    set size of window 1 to {1200, 900}
                end tell
            end tell' 2>/dev/null
            ;;
        *)
            echo "Unknown position: $POSITION (use left|right|center)"
            exit 1
            ;;
    esac
    echo "Moved window: $POSITION"
    ;;

focus)
    APP="$1"
    [ -z "$APP" ] && { echo "Usage: mac.sh focus <app>"; exit 1; }
    osascript -e "tell application \"$APP\" to activate" 2>/dev/null
    echo "Focused: $APP"
    ;;

quit)
    APP="$1"
    [ -z "$APP" ] && { echo "Usage: mac.sh quit <app>"; exit 1; }
    osascript -e "tell application \"$APP\" to quit" 2>/dev/null
    echo "Quit: $APP"
    ;;

mouse)
    cliclick p:. 2>/dev/null
    ;;

help|*)
    echo "mac.sh — Mac computer use tool"
    echo ""
    echo "Commands:"
    echo "  shot [path]              Screenshot (default: /tmp/screen.png)"
    echo "  click <x> <y>           Click at logical coords"
    echo "  doubleclick <x> <y>     Double-click"
    echo "  rightclick <x> <y>      Right-click"
    echo "  type <text>             Type text"
    echo "  key <key>               Press key (return|escape|tab|delete|space|up|down|left|right)"
    echo "  hotkey <mod> <key>      Hotkey (cmd|opt|ctrl|shift + key)"
    echo "  frontmost               Print frontmost app"
    echo "  list-windows            List all visible windows"
    echo "  find-buttons <app>      List buttons with click-ready center coords"
    echo "  find-elements <app>     List UI elements with center coords"
    echo "  close [app]             Close frontmost window"
    echo "  minimize [app]          Minimize window"
    echo "  unminimize <app>        Unminimize window"
    echo "  maximize [app]          Toggle fullscreen"
    echo "  move <left|right|center> Position window"
    echo "  focus <app>             Activate app"
    echo "  quit <app>              Quit app"
    echo "  mouse                   Print mouse position"
    ;;
esac
