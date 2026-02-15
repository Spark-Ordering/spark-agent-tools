#!/bin/bash

# query-safeguards.sh - Shared validation logic for database query scripts
# Prevents DELETE statements and limits UPDATE to single-row operations
# Can be bypassed with ALLOW_DELETE=1 environment variable

# Check if query is a DELETE statement (case-insensitive)
is_delete_query() {
    local query="$1"
    echo "$query" | grep -iq '^\s*DELETE\s'
}

# Check if query is an UPDATE statement (case-insensitive)
is_update_query() {
    local query="$1"
    echo "$query" | grep -iq '^\s*UPDATE\s'
}

# Extract table name from UPDATE query
# UPDATE table_name SET ... -> table_name
extract_update_table() {
    local query="$1"
    # Convert to lowercase and extract second word (table name after UPDATE)
    echo "$query" | tr '[:upper:]' '[:lower:]' | awk '{for(i=1;i<=NF;i++) if($i=="update") {print $(i+1); exit}}' | head -1
}

# Extract WHERE clause from query (everything after WHERE keyword)
extract_where_clause() {
    local query="$1"
    if echo "$query" | grep -iq 'WHERE'; then
        # Use perl for reliable case-insensitive extraction
        echo "$query" | perl -pe 's/.*\bWHERE\s+//i' | head -1
    fi
}

# Run count query for PostgreSQL
run_postgres_count() {
    local table="$1"
    local where_clause="$2"
    local db_url="$3"

    local count_query="SELECT COUNT(*) FROM $table"
    if [ -n "$where_clause" ]; then
        count_query="$count_query WHERE $where_clause"
    fi

    psql "$db_url" -t -c "$count_query" 2>/dev/null | tr -d ' '
}

# Run count query for MySQL
run_mysql_count() {
    local table="$1"
    local where_clause="$2"
    local host="$3"
    local user="$4"
    local pass="$5"
    local dbname="$6"

    local count_query="SELECT COUNT(*) FROM $table"
    if [ -n "$where_clause" ]; then
        count_query="$count_query WHERE $where_clause"
    fi

    mysql -h "$host" -u "$user" -p"$pass" "$dbname" -N -e "$count_query" 2>/dev/null | tr -d ' '
}

# Main validation function
# Usage:
#   validate_query "SQL" "postgres" "$DATABASE_URL"
#   validate_query "SQL" "mysql" "$HOST" "$USER" "$PASS" "$DBNAME"
#
# Set ALLOW_DELETE=1 to bypass DELETE protection (for explicit delete operations)
validate_query() {
    local query="$1"
    local db_type="$2"
    shift 2

    # Block DELETE statements unless explicitly allowed
    if is_delete_query "$query"; then
        if [ "$ALLOW_DELETE" = "1" ]; then
            # Extract table and WHERE for safety message
            local where_clause=$(extract_where_clause "$query")
            if [ -z "$where_clause" ]; then
                echo "Error: DELETE without WHERE clause is not allowed." >&2
                exit 1
            fi
            echo "# Warning: Executing DELETE statement" >&2
        else
            echo "Error: DELETE statements are blocked for safety." >&2
            echo "Use --delete flag to explicitly allow DELETE operations." >&2
            exit 1
        fi
    fi

    # Check UPDATE statements
    if is_update_query "$query"; then
        local table=$(extract_update_table "$query")
        local where_clause=$(extract_where_clause "$query")

        if [ -z "$table" ]; then
            echo "Error: Could not parse table name from UPDATE query." >&2
            exit 1
        fi

        # Run count query based on database type
        local count
        if [ "$db_type" = "postgres" ]; then
            local db_url="$1"
            count=$(run_postgres_count "$table" "$where_clause" "$db_url")
        elif [ "$db_type" = "mysql" ]; then
            local host="$1"
            local user="$2"
            local pass="$3"
            local dbname="$4"
            count=$(run_mysql_count "$table" "$where_clause" "$host" "$user" "$pass" "$dbname")
        else
            echo "Error: Unknown database type: $db_type" >&2
            exit 1
        fi

        # Validate count
        if [ -z "$count" ]; then
            echo "Error: Could not determine row count for UPDATE." >&2
            exit 1
        fi

        if [ "$count" -gt 1 ]; then
            echo "Error: UPDATE would affect $count rows. Maximum allowed: 1." >&2
            echo "Query: SELECT COUNT(*) FROM $table WHERE $where_clause" >&2
            exit 1
        fi
    fi

    # Query is safe to execute
    return 0
}
