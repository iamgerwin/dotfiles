#!/bin/bash

# ClickUp API Script
# Provides comprehensive task management via ClickUp API
# Usage: ./clickup-api.sh [command] [args]

set -euo pipefail

# Configuration - Load from environment or use defaults
API_KEY="${CLICKUP_API_KEY:-}"
BASE_URL="https://api.clickup.com/api/v2"
ATTACHMENTS_DIR="${CLICKUP_ATTACHMENTS_DIR:-./clickup_attachments}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Error handling
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Validate API key
check_api_key() {
    if [ -z "$API_KEY" ]; then
        error_exit "CLICKUP_API_KEY environment variable not set. Please set it in your environment or .env file."
    fi
}

# Function to make API calls with error handling
make_request() {
    local method=$1
    local endpoint=$2
    local data=${3:-}

    check_api_key

    local curl_cmd=(curl -s -w "\n%{http_code}" -X "$method")
    curl_cmd+=("${BASE_URL}${endpoint}")
    curl_cmd+=(-H "Authorization: ${API_KEY}")
    curl_cmd+=(-H "Content-Type: application/json")

    if [ -n "$data" ]; then
        curl_cmd+=(-d "$data")
    fi

    # Execute request and capture response with status
    local response
    response=$("${curl_cmd[@]}" 2>/dev/null)

    local http_code
    http_code=$(echo "$response" | tail -n1)
    local body
    body=$(echo "$response" | sed '$d')

    # Check for API errors
    if [ "$http_code" -ge 400 ]; then
        local error_msg
        error_msg=$(echo "$body" | jq -r '.err // .error // .message // "Unknown error"' 2>/dev/null || echo "HTTP $http_code error")
        error_exit "API request failed: $error_msg (HTTP $http_code)"
    fi

    echo "$body"
}

# Function to validate JSON
validate_json() {
    echo "$1" | jq empty 2>/dev/null || error_exit "Invalid JSON provided"
}

# Commands
case "${1:-}" in
    "get-task")
        # Usage: ./clickup-api.sh get-task TASK_ID
        [ -z "${2:-}" ] && error_exit "TASK_ID required. Usage: $0 get-task TASK_ID"
        make_request "GET" "/task/$2?include_subtasks=true&include_task_comments=true" | jq '.'
        ;;

    "get-comments")
        # Usage: ./clickup-api.sh get-comments TASK_ID
        [ -z "${2:-}" ] && error_exit "TASK_ID required. Usage: $0 get-comments TASK_ID"

        # Get top-level comments
        comments_data=$(make_request "GET" "/task/$2/comment")

        # Process comments and their replies
        if [ "$(echo "$comments_data" | jq '.comments | length')" -gt 0 ]; then
            echo "$comments_data" | jq -c '.comments[]' | while read -r comment; do
                comment_id=$(echo "$comment" | jq -r '.id')
                reply_count=$(echo "$comment" | jq -r '.reply_count // 0')

                echo "$comment"

                # Fetch replies if they exist
                if [ "$reply_count" -gt 0 ]; then
                    replies_data=$(make_request "GET" "/task/$2/comment/$comment_id")
                    echo "$replies_data" | jq -c '.replies[]? // empty' 2>/dev/null
                fi
            done | jq -s '{comments: .}'
        else
            echo '{"comments": []}'
        fi
        ;;

    "add-comment")
        # Usage: ./clickup-api.sh add-comment TASK_ID "comment text"
        [ -z "${2:-}" ] && error_exit "TASK_ID required. Usage: $0 add-comment TASK_ID \"comment text\""
        [ -z "${3:-}" ] && error_exit "Comment text required. Usage: $0 add-comment TASK_ID \"comment text\""

        data=$(jq -n --arg text "$3" '{comment_text: $text}')
        make_request "POST" "/task/$2/comment" "$data" | jq '.'
        echo -e "${GREEN}Comment added successfully${NC}"
        ;;

    "get-attachments")
        # Usage: ./clickup-api.sh get-attachments TASK_ID
        [ -z "${2:-}" ] && error_exit "TASK_ID required. Usage: $0 get-attachments TASK_ID"

        task_data=$(make_request "GET" "/task/$2")
        attachments=$(echo "$task_data" | jq '.attachments')

        if [ "$(echo "$attachments" | jq '. | length')" -eq 0 ]; then
            echo "No attachments found for task $2"
        else
            echo "$attachments" | jq '.'
        fi
        ;;

    "download-attachment")
        # Usage: ./clickup-api.sh download-attachment TASK_ID ATTACHMENT_ID
        [ -z "${2:-}" ] && error_exit "TASK_ID required. Usage: $0 download-attachment TASK_ID ATTACHMENT_ID"
        [ -z "${3:-}" ] && error_exit "ATTACHMENT_ID required. Usage: $0 download-attachment TASK_ID ATTACHMENT_ID"

        mkdir -p "$ATTACHMENTS_DIR"

        task_data=$(make_request "GET" "/task/$2")
        attachment=$(echo "$task_data" | jq -r ".attachments[] | select(.id == \"$3\")")

        if [ -z "$attachment" ] || [ "$attachment" = "null" ]; then
            error_exit "Attachment with ID $3 not found in task $2"
        fi

        url=$(echo "$attachment" | jq -r '.url')
        filename=$(echo "$attachment" | jq -r '.title')
        output_path="$ATTACHMENTS_DIR/$filename"

        echo "Downloading $filename..."
        curl -s -L "$url" -o "$output_path" || error_exit "Failed to download attachment"
        echo -e "${GREEN}Downloaded to $output_path${NC}"
        ;;

    "auto-download-images")
        # Usage: ./clickup-api.sh auto-download-images TASK_ID
        [ -z "${2:-}" ] && error_exit "TASK_ID required. Usage: $0 auto-download-images TASK_ID"

        mkdir -p "$ATTACHMENTS_DIR"
        task_data=$(make_request "GET" "/task/$2")

        # Check for image attachments
        image_count=$(echo "$task_data" | jq '[.attachments[] | select(.type == "image" or .title | test("\\.(jpg|jpeg|png|gif|webp|bmp|svg)$"; "i"))] | length')

        if [ "$image_count" -eq 0 ]; then
            echo "No image attachments found for task $2"
            exit 0
        fi

        echo "Found $image_count image(s) to download..."

        # Download each image
        echo "$task_data" | jq -r '.attachments[] | select(.type == "image" or .title | test("\\.(jpg|jpeg|png|gif|webp|bmp|svg)$"; "i")) | "\(.id)|\(.url)|\(.title)"' | while IFS='|' read -r id url title; do
            if [ -n "$id" ]; then
                output_path="$ATTACHMENTS_DIR/$title"
                echo "Downloading $title..."
                curl -s -L "$url" -o "$output_path" || echo -e "${YELLOW}Warning: Failed to download $title${NC}"
                [ -f "$output_path" ] && echo -e "${GREEN}  → Saved to $output_path${NC}"
            fi
        done

        echo -e "${GREEN}Download complete. Files saved to $ATTACHMENTS_DIR${NC}"
        ;;

    "get-subtasks")
        # Usage: ./clickup-api.sh get-subtasks TASK_ID
        [ -z "${2:-}" ] && error_exit "TASK_ID required. Usage: $0 get-subtasks TASK_ID"

        task_data=$(make_request "GET" "/task/$2?include_subtasks=true")
        subtasks=$(echo "$task_data" | jq '.subtasks')

        if [ "$(echo "$subtasks" | jq '. | length')" -eq 0 ]; then
            echo "No subtasks found for task $2"
        else
            echo "$subtasks" | jq '.'
        fi
        ;;

    "update-status")
        # Usage: ./clickup-api.sh update-status TASK_ID "status name"
        [ -z "${2:-}" ] && error_exit "TASK_ID required. Usage: $0 update-status TASK_ID \"status name\""
        [ -z "${3:-}" ] && error_exit "Status required. Usage: $0 update-status TASK_ID \"status name\""

        data=$(jq -n --arg status "$3" '{status: $status}')
        make_request "PUT" "/task/$2" "$data" | jq '.'
        echo -e "${GREEN}Status updated to: $3${NC}"
        ;;

    "create-task")
        # Usage: ./clickup-api.sh create-task LIST_ID "Task Name" "Description" [priority] [tags] [status]
        [ -z "${2:-}" ] && error_exit "LIST_ID required. Usage: $0 create-task LIST_ID \"Task Name\" \"Description\" [priority] [tags] [status]"
        [ -z "${3:-}" ] && error_exit "Task name required. Usage: $0 create-task LIST_ID \"Task Name\" \"Description\" [priority] [tags] [status]"

        list_id=$2
        name=$3
        description=${4:-""}
        priority=${5:-3}
        tags=${6:-""}
        status=${7:-"Open"}

        # Build tags array
        tags_json="[]"
        if [ -n "$tags" ]; then
            tags_json=$(echo "$tags" | jq -R 'split(",") | map(ltrimstr(" ") | rtrimstr(" ")) | map({name: .})')
        fi

        # Create task data
        data=$(jq -n \
            --arg name "$name" \
            --arg description "$description" \
            --arg priority "$priority" \
            --argjson tags "$tags_json" \
            --arg status "$status" \
            '{
                name: $name,
                description: $description,
                priority: ($priority | tonumber),
                tags: $tags,
                status: $status
            }')

        response=$(make_request "POST" "/list/$list_id/task" "$data")
        task_id=$(echo "$response" | jq -r '.id')
        echo "$response" | jq '.'
        echo -e "${GREEN}Task created successfully. ID: $task_id${NC}"
        ;;

    "update-task")
        # Usage: ./clickup-api.sh update-task TASK_ID "New Name" ["New Description"]
        [ -z "${2:-}" ] && error_exit "TASK_ID required. Usage: $0 update-task TASK_ID \"New Name\" [\"New Description\"]"
        [ -z "${3:-}" ] && error_exit "Task name required. Usage: $0 update-task TASK_ID \"New Name\" [\"New Description\"]"

        task_id=$2
        new_name=$3
        new_description=${4:-}

        if [ -n "$new_description" ]; then
            data=$(jq -n \
                --arg name "$new_name" \
                --arg description "$new_description" \
                '{name: $name, description: $description}')
        else
            data=$(jq -n --arg name "$new_name" '{name: $name}')
        fi

        make_request "PUT" "/task/$task_id" "$data" | jq '.'
        echo -e "${GREEN}Task updated successfully${NC}"
        ;;

    "update-task-fields")
        # Usage: ./clickup-api.sh update-task-fields TASK_ID field1=value1 field2=value2 ...
        [ -z "${2:-}" ] && error_exit "TASK_ID required. Usage: $0 update-task-fields TASK_ID field=value [field2=value2 ...]"

        task_id=$2
        shift 2

        # Build JSON from field=value pairs
        json_obj="{}"
        for arg in "$@"; do
            if [[ "$arg" =~ ^([^=]+)=(.*)$ ]]; then
                field="${BASH_REMATCH[1]}"
                value="${BASH_REMATCH[2]}"

                case "$field" in
                    priority|time_estimate)
                        json_obj=$(echo "$json_obj" | jq --arg field "$field" --arg value "$value" '. + {($field): ($value | tonumber)}')
                        ;;
                    archived)
                        json_obj=$(echo "$json_obj" | jq --arg field "$field" --arg value "$value" '. + {($field): ($value | test("true|1"; "i"))}')
                        ;;
                    *)
                        json_obj=$(echo "$json_obj" | jq --arg field "$field" --arg value "$value" '. + {($field): $value}')
                        ;;
                esac
            fi
        done

        if [ "$json_obj" = "{}" ]; then
            error_exit "No valid field=value pairs provided"
        fi

        make_request "PUT" "/task/$task_id" "$json_obj" | jq '.'
        echo -e "${GREEN}Task fields updated successfully${NC}"
        ;;

    "get-list")
        # Usage: ./clickup-api.sh get-list LIST_ID
        [ -z "${2:-}" ] && error_exit "LIST_ID required. Usage: $0 get-list LIST_ID"
        make_request "GET" "/list/$2" | jq '.'
        ;;

    "fetch-tasks")
        # Usage: ./clickup-api.sh fetch-tasks LIST_ID [archived] [subtasks]
        [ -z "${2:-}" ] && error_exit "LIST_ID required. Usage: $0 fetch-tasks LIST_ID [include_archived] [include_subtasks]"

        list_id=$2
        include_archived=${3:-false}
        include_subtasks=${4:-true}

        query_params="?archived=${include_archived}&subtasks=${include_subtasks}&include_closed=true"
        make_request "GET" "/list/${list_id}/task${query_params}" | jq '.'
        ;;

    "create-task-with-fields")
        # Usage: ./clickup-api.sh create-task-with-fields LIST_ID "Name" "Desc" FIELD_ID VALUE [priority] [tags]
        [ -z "${2:-}" ] && error_exit "LIST_ID required"
        [ -z "${3:-}" ] && error_exit "Task name required"
        [ -z "${5:-}" ] && error_exit "Custom field ID required"
        [ -z "${6:-}" ] && error_exit "Custom field value required"

        list_id=$2
        name=$3
        description=${4:-""}
        custom_field_id=$5
        custom_field_value=$6
        priority=${7:-3}
        tags=${8:-""}

        # Build tags array
        tags_json="[]"
        if [ -n "$tags" ]; then
            tags_json=$(echo "$tags" | jq -R 'split(",") | map(ltrimstr(" ") | rtrimstr(" ")) | map({name: .})')
        fi

        # Create task with custom fields
        data=$(jq -n \
            --arg name "$name" \
            --arg description "$description" \
            --arg priority "$priority" \
            --argjson tags "$tags_json" \
            --arg custom_field_id "$custom_field_id" \
            --arg custom_field_value "$custom_field_value" \
            '{
                name: $name,
                description: $description,
                priority: ($priority | tonumber),
                tags: $tags,
                status: "to do",
                custom_fields: [{
                    id: $custom_field_id,
                    value: $custom_field_value
                }]
            }')

        response=$(make_request "POST" "/list/$list_id/task" "$data")
        task_id=$(echo "$response" | jq -r '.id')
        echo "$response" | jq '.'
        echo -e "${GREEN}Task created with custom fields. ID: $task_id${NC}"
        ;;

    "batch-update-status")
        # Usage: ./clickup-api.sh batch-update-status "status" TASK_ID1 TASK_ID2 ...
        [ -z "${2:-}" ] && error_exit "Status required. Usage: $0 batch-update-status \"status\" TASK_ID1 TASK_ID2 ..."
        [ -z "${3:-}" ] && error_exit "At least one TASK_ID required"

        status=$2
        shift 2

        echo "Updating ${#@} task(s) to status: $status"
        for task_id in "$@"; do
            echo -n "Updating $task_id... "
            data=$(jq -n --arg status "$status" '{status: $status}')
            if make_request "PUT" "/task/$task_id" "$data" > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC}"
            fi
        done
        ;;

    "search-tasks")
        # Usage: ./clickup-api.sh search-tasks TEAM_ID "search query"
        [ -z "${2:-}" ] && error_exit "TEAM_ID required. Usage: $0 search-tasks TEAM_ID \"search query\""
        [ -z "${3:-}" ] && error_exit "Search query required"

        team_id=$2
        query=$3

        # URL encode the query
        encoded_query=$(echo "$query" | jq -sRr @uri)
        make_request "GET" "/team/${team_id}/task?name=${encoded_query}&include_closed=true" | jq '.'
        ;;

    *)
        echo "ClickUp API Script"
        echo "Version: 2.0.0"
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Configuration:"
        echo "  Set CLICKUP_API_KEY environment variable with your ClickUp API key"
        echo "  Set CLICKUP_ATTACHMENTS_DIR to customize download directory (default: ./clickup_attachments)"
        echo ""
        echo "Task Management Commands:"
        echo "  get-task TASK_ID                          - Get task details with subtasks and comments"
        echo "  create-task LIST_ID NAME DESC [pri] [tags] [status] - Create a new task"
        echo "  update-task TASK_ID NAME [DESC]           - Update task name and description"
        echo "  update-task-fields TASK_ID field=value... - Update multiple task fields"
        echo "  update-status TASK_ID STATUS              - Update task status"
        echo "  batch-update-status STATUS ID1 ID2...     - Update multiple tasks status"
        echo "  search-tasks TEAM_ID \"query\"              - Search tasks by name"
        echo ""
        echo "Comments & Attachments:"
        echo "  get-comments TASK_ID                      - Get all comments including replies"
        echo "  add-comment TASK_ID \"text\"                - Add a comment to a task"
        echo "  get-attachments TASK_ID                   - List all attachments"
        echo "  download-attachment TASK_ID ATTACH_ID     - Download specific attachment"
        echo "  auto-download-images TASK_ID              - Download all image attachments"
        echo ""
        echo "Organization:"
        echo "  get-list LIST_ID                          - Get list details"
        echo "  fetch-tasks LIST_ID [archived] [subtasks] - Get all tasks from a list"
        echo "  get-subtasks TASK_ID                      - Get subtasks for a task"
        echo ""
        echo "Advanced:"
        echo "  create-task-with-fields LIST_ID NAME DESC FIELD_ID VALUE [pri] [tags] - Create with custom fields"
        echo ""
        echo "Options:"
        echo "  Priority: 1=urgent, 2=high, 3=normal (default), 4=low"
        echo "  Tags: comma-separated list (e.g., \"bug,urgent\")"
        echo "  Fields: name, description, status, priority, due_date, archived, etc."
        echo ""
        echo "Examples:"
        echo "  $0 create-task 123456 \"Fix login bug\" \"Users can't login\" 2 \"bug,auth\""
        echo "  $0 update-task-fields abc123 status=\"in progress\" priority=1"
        echo "  $0 batch-update-status \"complete\" task1 task2 task3"
        echo ""
        exit 0
        ;;
esac