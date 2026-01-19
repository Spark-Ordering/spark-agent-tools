#!/bin/bash

# JIRA Ticket Creation Script
# Usage: jira-create.sh "Summary" "Description" [--no-sprint]
#
# Creates a JIRA ticket in the ENG project and adds it to the current sprint.
#
# Required environment variables (set in ~/.zshrc or similar):
#   JIRA_SITE_URL - e.g., sparkordering.atlassian.net
#   JIRA_EMAIL    - e.g., carlos@sparkordering.com
#   JIRA_API_TOKEN - your Jira API token
#
# Examples:
#   jira-create.sh "Fix login bug" "Users cannot log in when..."
#   jira-create.sh "Add feature X" "Description here" --no-sprint

set -e

# Configuration
BOARD_ID="2"
PROJECT_KEY="ENG"

# Check required environment variables
if [ -z "$JIRA_SITE_URL" ] || [ -z "$JIRA_EMAIL" ] || [ -z "$JIRA_API_TOKEN" ]; then
    echo "Error: Missing required environment variables."
    echo "Please set: JIRA_SITE_URL, JIRA_EMAIL, JIRA_API_TOKEN"
    exit 1
fi

AUTH=$(echo -n "${JIRA_EMAIL}:${JIRA_API_TOKEN}" | base64)

# Parse arguments
SUMMARY="$1"
DESCRIPTION="$2"
ADD_TO_SPRINT=true

if [ "$3" = "--no-sprint" ]; then
    ADD_TO_SPRINT=false
fi

if [ -z "$SUMMARY" ]; then
    echo "Usage: jira-create.sh \"Summary\" \"Description\" [--no-sprint]"
    exit 1
fi

if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION="$SUMMARY"
fi

# Escape special characters for JSON
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\t/\\t/g' | sed ':a;N;$!ba;s/\n/\\n/g'
}

ESCAPED_SUMMARY=$(escape_json "$SUMMARY")
ESCAPED_DESCRIPTION=$(escape_json "$DESCRIPTION")

# Create the ticket
echo "Creating JIRA ticket..."

CREATE_RESPONSE=$(curl -s -X POST \
    -H "Authorization: Basic ${AUTH}" \
    -H "Content-Type: application/json" \
    -d "{
        \"fields\": {
            \"project\": {\"key\": \"${PROJECT_KEY}\"},
            \"summary\": \"${ESCAPED_SUMMARY}\",
            \"description\": {
                \"type\": \"doc\",
                \"version\": 1,
                \"content\": [
                    {
                        \"type\": \"paragraph\",
                        \"content\": [
                            {\"type\": \"text\", \"text\": \"${ESCAPED_DESCRIPTION}\"}
                        ]
                    }
                ]
            },
            \"issuetype\": {\"name\": \"Task\"}
        }
    }" \
    "https://${JIRA_SITE_URL}/rest/api/3/issue")

# Extract the ticket key
TICKET_KEY=$(echo "$CREATE_RESPONSE" | grep -o '"key":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$TICKET_KEY" ]; then
    echo "Error creating ticket:"
    echo "$CREATE_RESPONSE"
    exit 1
fi

echo "Created: ${TICKET_KEY}"
echo "URL: https://${JIRA_SITE_URL}/browse/${TICKET_KEY}"

# Add to current sprint if requested
if [ "$ADD_TO_SPRINT" = true ]; then
    echo "Finding active sprint..."

    SPRINT_RESPONSE=$(curl -s -X GET \
        -H "Authorization: Basic ${AUTH}" \
        "https://${JIRA_SITE_URL}/rest/agile/1.0/board/${BOARD_ID}/sprint?state=active")

    SPRINT_ID=$(echo "$SPRINT_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    SPRINT_NAME=$(echo "$SPRINT_RESPONSE" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)

    if [ -n "$SPRINT_ID" ]; then
        echo "Adding to sprint: ${SPRINT_NAME} (ID: ${SPRINT_ID})..."

        curl -s -X POST \
            -H "Authorization: Basic ${AUTH}" \
            -H "Content-Type: application/json" \
            -d "{\"issues\": [\"${TICKET_KEY}\"]}" \
            "https://${JIRA_SITE_URL}/rest/agile/1.0/sprint/${SPRINT_ID}/issue" > /dev/null

        echo "Added to sprint: ${SPRINT_NAME}"
    else
        echo "Warning: No active sprint found"
    fi
fi

echo ""
echo "Done! Ticket: ${TICKET_KEY}"
