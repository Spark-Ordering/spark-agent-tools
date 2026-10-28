#!/bin/bash
# Drive Carlos's Jelly Star phone over wireless adb.
# Usage: phone.sh <command> [args...]
#
# Commands:
#   pair <ip:port> <code>   - One-time pairing to this Mac (every command auto-reconnects after)
#   connect                 - (Re)connect via mDNS (done automatically by every command)
#   awake                   - 30 min screen timeout + stay on (survives until reboot)
#   wake                    - Wake the screen
#   shot                    - Screenshot to /tmp/phone.png
#   ui                      - List on-screen elements: center x,y | text | desc | id
#   tap <x> <y>             - Tap coordinates
#   tap-text <text>         - Tap the first element whose text/desc contains <text>
#   swipe <x1> <y1> <x2> <y2> [ms]
#   text <string>           - Type text
#   key <back|home|enter|del|recent|wake|keycode>
#   open <package>          - Launch an app
#   sms [n]                 - Newest n SMS across all threads (default 30)
#   sms-with <number> [n]   - Newest n SMS with a number (digits matched loosely)
#   contacts <query>        - Contact names/numbers matching query
#   shell <cmd...>          - Raw adb shell on the phone

set -euo pipefail

# Own adb server: 5037 is sometimes an ssh tunnel to a remote rig host
export ANDROID_ADB_SERVER_PORT=5038

cmd="${1:-}"
shift || true

connect() {
  local addr
  addr=$(adb mdns services | awk '/JELLYS/ && /_adb-tls-connect/ {print $3; exit}')
  if [ -z "$addr" ]; then
    echo "Phone not advertising. Check Wireless debugging is on (same Wi-Fi)." >&2
    exit 1
  fi
  adb connect "$addr" >&2
}

# Wireless debugging changes port on reboot / Wi-Fi drop, so reconnect via mDNS on demand
serial() {
  local s
  s=$(adb devices -l | awk '/model:Jelly_Star/ && / device / {print $1; exit}')
  if [ -z "$s" ]; then
    connect
    s=$(adb devices -l | awk '/model:Jelly_Star/ && / device / {print $1; exit}')
  fi
  if [ -z "$s" ]; then
    echo "Jelly Star not connected (paired to this Mac?)" >&2
    exit 1
  fi
  echo "$s"
}

a() { adb -s "$(serial)" "$@"; }

case "$cmd" in
  connect)
    connect
    ;;
  pair)
    adb pair "$1" "$2"
    sleep 3
    connect
    ;;
  awake)
    a shell settings put system screen_off_timeout 1800000
    a shell svc power stayon true
    echo "timeout=30min stayon=true"
    ;;
  wake)
    a shell input keyevent KEYCODE_WAKEUP
    ;;
  shot)
    a exec-out screencap -p > /tmp/phone.png
    echo /tmp/phone.png
    ;;
  ui)
    a shell uiautomator dump /sdcard/phone-ui.xml > /dev/null
    a exec-out cat /sdcard/phone-ui.xml | python3 -I -c '
import sys, re, xml.etree.ElementTree as ET
for n in ET.parse(sys.stdin).iter("node"):
    t, d, r = n.get("text", ""), n.get("content-desc", ""), n.get("resource-id", "")
    if not (t or d): continue
    x1, y1, x2, y2 = map(int, re.findall(r"\d+", n.get("bounds")))
    rid = r.split(chr(47))[-1]
    print(f"{(x1+x2)//2},{(y1+y2)//2} | {t} | {d} | {rid}")
'
    ;;
  msgs)
    # Google Messages: one line per visible bubble ("X said ... time"), then scroll up if asked
    a shell uiautomator dump /sdcard/phone-ui.xml > /dev/null
    a exec-out cat /sdcard/phone-ui.xml | python3 -I -c '
import sys, xml.etree.ElementTree as ET
for n in ET.parse(sys.stdin).iter("node"):
    if n.get("resource-id", "").endswith("message_text"):
        print(" ".join(n.get("content-desc", "").split()))
'
    if [ "${1:-}" = "up" ]; then
      a shell input swipe 240 250 240 750 400
    fi
    ;;
  newest)
    # Newest bubble in the thread with <number>; opens it, then backs out if another app was in front
    prev=$(a shell dumpsys window | grep -m1 mCurrentFocus)
    a shell cmd statusbar collapse
    a shell am start -a android.intent.action.SENDTO -d "sms:$1" > /dev/null
    sleep 2
    "$0" msgs | head -1
    case "$prev" in
      *com.google.android.apps.messaging*) ;;
      *) a shell input keyevent 4 ;;
    esac
    ;;
  thread)
    # Scroll up through the open thread <screens> times; prints bubbles oldest-first, deduped
    for _ in $(seq "${1:-10}"); do "$0" msgs up; sleep 1; done | awk '!seen[$0]++' | tail -r
    ;;
  tap)
    a shell input tap "$1" "$2"
    ;;
  tap-text)
    xy=$("$0" ui | awk -F' \\| ' -v q="$1" 'index(tolower($2 " " $3), tolower(q)) {print $1; exit}')
    if [ -z "$xy" ]; then
      echo "No element matching: $1" >&2
      exit 1
    fi
    a shell input tap "${xy%,*}" "${xy#*,}"
    echo "tapped $xy"
    ;;
  swipe)
    a shell input swipe "$1" "$2" "$3" "$4" "${5:-300}"
    ;;
  text)
    # input text needs spaces as %s and shell metachars escaped
    escaped=$(printf '%s' "$1" | sed -e 's/[\\"'"'"'`$&|;<>()*?~!#]/\\&/g' -e 's/ /%s/g')
    a shell input text "$escaped"
    ;;
  key)
    case "$1" in
      back) k=4 ;; home) k=3 ;; enter) k=66 ;; del) k=67 ;; recent) k=187 ;; wake) k=224 ;;
      *) k="$1" ;;
    esac
    a shell input keyevent "$k"
    ;;
  open)
    a shell monkey -p "$1" -c android.intent.category.LAUNCHER 1 > /dev/null
    ;;
  sms)
    a shell content query --uri content://sms --projection date:type:address:body \
      --sort "\"date DESC\"" | head -n "${1:-30}"
    ;;
  sms-with)
    digits=$(printf '%s' "$1" | tr -cd '0-9' | tail -c 10)
    a shell content query --uri content://sms --projection date:type:address:body \
      --where "\"address LIKE '%$digits'\"" --sort "\"date DESC\"" | head -n "${2:-30}"
    ;;
  contacts)
    a shell content query --uri content://com.android.contacts/data/phones \
      --projection display_name:data1 | grep -i -- "$1"
    ;;
  shell)
    a shell "$@"
    ;;
  *)
    sed -n '2,24p' "$0"
    exit 1
    ;;
esac
