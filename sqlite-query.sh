#!/bin/bash
# Query SparkPos SQLite database on Android device
# Usage: sqlite-query.sh [--write] [--fresh] "SQL QUERY"
#
# Options:
#   --write  Execute write operation and push DB back to device
#            For PowerSync tables, use ps_data__* to bypass triggers
#   --fresh  Force fresh pull (always pull, ignore cached copy)
#
# Examples:
#   sqlite-query.sh "SELECT * FROM menu_items LIMIT 5"
#   sqlite-query.sh --write "DELETE FROM ps_data__draft_menu_versions"
#   sqlite-query.sh --fresh "SELECT COUNT(*) FROM draft_menu_versions"

PACKAGE="com.starter.paddev"
DB_PATH="/data/data/$PACKAGE/databases/sparkpos-powersync-v1.db"
TMP_DB="/tmp/sparkpos-device.db"

WRITE_MODE=false
FRESH_MODE=false
QUERY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --write)
            WRITE_MODE=true
            shift
            ;;
        --fresh)
            FRESH_MODE=true
            shift
            ;;
        *)
            QUERY="$1"
            shift
            ;;
    esac
done

if [ -z "$QUERY" ]; then
    echo "Usage: sqlite-query.sh [--write] [--fresh] \"SQL QUERY\""
    echo ""
    echo "Options:"
    echo "  --write  Execute write operation and push DB back to device"
    echo "           For PowerSync tables, use ps_data__* to bypass triggers"
    echo "  --fresh  Force fresh pull from device (ignore cached DB)"
    echo ""
    echo "Examples:"
    echo "  sqlite-query.sh \"SELECT * FROM menu_items LIMIT 5\""
    echo "  sqlite-query.sh --write \"DELETE FROM ps_data__draft_menu_versions\""
    echo "  sqlite-query.sh --fresh \"SELECT COUNT(*) FROM draft_menu_versions\""
    exit 1
fi

# Pull the database (always fresh if --fresh or --write, otherwise use cache if recent)
SHOULD_PULL=true
if [ "$FRESH_MODE" = false ] && [ "$WRITE_MODE" = false ] && [ -f "$TMP_DB" ]; then
    # Check if cache is less than 5 seconds old
    if [ "$(uname)" = "Darwin" ]; then
        AGE=$(($(date +%s) - $(stat -f %m "$TMP_DB")))
    else
        AGE=$(($(date +%s) - $(stat -c %Y "$TMP_DB")))
    fi
    if [ $AGE -lt 5 ]; then
        SHOULD_PULL=false
    fi
fi

if [ "$SHOULD_PULL" = true ] || [ "$WRITE_MODE" = true ]; then
    adb shell "run-as $PACKAGE cat $DB_PATH" > "$TMP_DB" 2>/dev/null
fi

if [ ! -s "$TMP_DB" ]; then
    echo "Error: Could not pull database from device"
    exit 1
fi

# Run the query
sqlite3 "$TMP_DB" "$QUERY"
RESULT=$?

if [ "$WRITE_MODE" = true ] && [ $RESULT -eq 0 ]; then
    echo ""
    echo "Pushing modified database back to device..."

    # Push to a temp location first (can't push directly to app data)
    adb push "$TMP_DB" /data/local/tmp/sparkpos-modified.db 2>/dev/null

    # Copy into app data using run-as
    adb shell "run-as $PACKAGE cp /data/local/tmp/sparkpos-modified.db $DB_PATH" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "Database updated successfully."
        echo "NOTE: You may need to restart the app to see changes."
    else
        echo "Error: Failed to push database to device"
        exit 1
    fi

    # Cleanup
    adb shell "rm /data/local/tmp/sparkpos-modified.db" 2>/dev/null
fi
