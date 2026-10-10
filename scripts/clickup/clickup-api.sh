#!/bin/bash

# ClickUp API Script - Enterprise Edition
# Advanced task management with robust error handling and retry logic
# Usage: ./clickup-api.sh [command] [args]

# 🧯 Strict mode for safety
set -Eeuo pipefail
IFS=$'\n\t'

# Trap errors for cleanup
trap 'echo "Error on line $LINENO"' ERR

# 🎨 Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# ⚙️ Configuration - Load from .env or environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# 🔐 API Configuration (no hardcoded keys!)
readonly API_TOKEN="${CLICKUP_TOKEN:-${CLICKUP_API_KEY:-}}"
readonly BASE_URL="${CLICKUP_BASE_URL:-https://api.clickup.com/api/v2}"
readonly ATTACHMENTS_DIR="${CLICKUP_ATTACHMENTS_DIR:-./clickup_attachments}"
readonly USER_AGENT="${CLICKUP_USER_AGENT:-ClickUp-API-Client/2.0}"

# 🧰 Default values
readonly DEFAULT_TIMEOUT="${CLICKUP_TIMEOUT:-30}"
readonly DEFAULT_MAX_RETRIES="${CLICKUP_MAX_RETRIES:-3}"
readonly DEFAULT_RETRY_DELAY="${CLICKUP_RETRY_DELAY:-1}"
readonly DEFAULT_PRIORITY="${CLICKUP_DEFAULT_PRIORITY:-3}"
readonly DEFAULT_STATUS="${CLICKUP_DEFAULT_STATUS:-Open}"
readonly DEFAULT_PAGE_SIZE="${CLICKUP_PAGE_SIZE:-100}"

# Debugging
readonly DEBUG="${CLICKUP_DEBUG:-false}"

# Error handling
error_exit() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
    exit "${2:-1}"
}

# Success message
success_msg() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Warning message
warn_msg() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Info message
info_msg() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Debug logging
debug_log() {
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "${MAGENTA}🔍 Debug: $1${NC}" >&2
    fi
}

# 🔐 Validate API token
check_api_token() {
    if [[ -z "$API_TOKEN" ]]; then
        error_exit "CLICKUP_TOKEN or CLICKUP_API_KEY environment variable not set.\nPlease set it in your environment or .env file.\nGet your token from: https://app.clickup.com/settings/apps"
    fi
}

# 🧼 Sanitize filename for safe downloads
sanitize_filename() {
    local filename="$1"
    # Remove or replace problematic characters
    filename="${filename//\//_}"
    filename="${filename//\\/_}"
    filename="${filename//\:/_}"
    filename="${filename//\*/_}"
    filename="${filename//\?/_}"
    filename="${filename//\"/_}"
    filename="${filename//\</_}"
    filename="${filename//\>/_}"
    filename="${filename//\|/_}"
    # Remove leading/trailing spaces and dots
    filename="${filename#"${filename%%[![:space:]]*}"}"
    filename="${filename%"${filename##*[![:space:]]}"}"
    filename="${filename#.}"
    # Default if empty
    [[ -z "$filename" ]] && filename="unnamed_file"
    echo "$filename"
}

# Calculate exponential backoff delay
calculate_backoff() {
    local attempt=$1
    local base_delay=${2:-$DEFAULT_RETRY_DELAY}
    echo $((base_delay * (2 ** (attempt - 1))))
}

# Parse Retry-After header
parse_retry_after() {
    local headers_file=$1
    local retry_after

    retry_after=$(grep -i "^Retry-After:" "$headers_file" 2>/dev/null | sed 's/^[^:]*: *//' | tr -d '\r')

    if [[ -n "$retry_after" ]]; then
        # Check if it's a delay in seconds or an HTTP date
        if [[ "$retry_after" =~ ^[0-9]+$ ]]; then
            echo "$retry_after"
        else
            # For HTTP date, default to base delay
            echo "$DEFAULT_RETRY_DELAY"
        fi
    else
        echo "0"
    fi
}

# 🌐 HTTP wrapper with retry logic
make_request() {
    local method=$1
    local endpoint=$2
    local data=${3:-}
    local page=${4:-}

    check_api_token

    local url="${BASE_URL}${endpoint}"

    # Add pagination parameters if provided
    if [[ -n "$page" ]]; then
        if [[ "$url" == *"?"* ]]; then
            url="${url}&page=${page}"
        else
            url="${url}?page=${page}"
        fi
    fi

    local attempt=0
    local max_retries=$DEFAULT_MAX_RETRIES
    local success=false
    local response_body=""
    local http_code=""

    # Create temp files for headers and body
    local headers_file
    headers_file=$(mktemp)
    local body_file
    body_file=$(mktemp)

    # Cleanup temp files on exit
    trap "rm -f '$headers_file' '$body_file'" RETURN

    while [[ $attempt -lt $max_retries ]] && [[ "$success" == "false" ]]; do
        ((attempt++))

        debug_log "Attempt $attempt/$max_retries for $method $url"

        # Build curl command
        local curl_cmd=(
            curl
            -s
            -w "\n%{http_code}"
            -X "$method"
            -H "Authorization: ${API_TOKEN}"
            -H "Content-Type: application/json"
            -H "User-Agent: ${USER_AGENT}"
            --max-time "$DEFAULT_TIMEOUT"
            -D "$headers_file"
            -o "$body_file"
        )

        # Add data if provided
        if [[ -n "$data" ]]; then
            curl_cmd+=(-d "$data")
        fi

        # Add URL
        curl_cmd+=("$url")

        # Execute request
        if http_code=$("${curl_cmd[@]}" 2>/dev/null | tail -n1); then
            debug_log "HTTP Status: $http_code"

            # Read response body
            response_body=$(cat "$body_file")

            # Check status code
            case "$http_code" in
                2*) # Success
                    success=true
                    ;;
                429) # Rate limited
                    local retry_after
                    retry_after=$(parse_retry_after "$headers_file")
                    if [[ "$retry_after" -gt 0 ]]; then
                        warn_msg "Rate limited. Waiting ${retry_after}s (Retry-After header)..."
                        sleep "$retry_after"
                    else
                        local backoff_delay
                        backoff_delay=$(calculate_backoff "$attempt")
                        warn_msg "Rate limited. Waiting ${backoff_delay}s..."
                        sleep "$backoff_delay"
                    fi
                    ;;
                5*) # Server error - retry with backoff
                    if [[ $attempt -lt $max_retries ]]; then
                        local backoff_delay
                        backoff_delay=$(calculate_backoff "$attempt")
                        warn_msg "Server error ($http_code). Retrying in ${backoff_delay}s..."
                        sleep "$backoff_delay"
                    fi
                    ;;
                4*) # Client error - don't retry
                    local error_msg
                    error_msg=$(echo "$response_body" | jq -r '.err // .error // .message // "Unknown error"' 2>/dev/null || echo "HTTP $http_code error")

                    if [[ "$DEBUG" == "true" ]]; then
                        echo -e "${RED}Request failed:${NC}" >&2
                        echo -e "${RED}Status: $http_code${NC}" >&2
                        echo -e "${RED}Headers:${NC}" >&2
                        cat "$headers_file" >&2
                        echo -e "${RED}Body:${NC}" >&2
                        echo "$response_body" | jq '.' 2>/dev/null || echo "$response_body" >&2
                    fi

                    error_exit "API request failed: $error_msg (HTTP $http_code)"
                    ;;
                *)
                    error_exit "Unexpected HTTP status: $http_code"
                    ;;
            esac
        else
            warn_msg "Request failed (network error). Attempt $attempt/$max_retries"
            if [[ $attempt -lt $max_retries ]]; then
                local backoff_delay
                backoff_delay=$(calculate_backoff "$attempt")
                sleep "$backoff_delay"
            fi
        fi
    done

    if [[ "$success" == "false" ]]; then
        error_exit "Request failed after $max_retries attempts"
    fi

    echo "$response_body"
}

# 📄 Pagination helper for fetch-tasks
fetch_all_pages() {
    local endpoint=$1
    local all_tasks="[]"
    local page=0
    local has_more=true

    info_msg "Fetching all tasks (this may take a moment for large lists)..."

    while [[ "$has_more" == "true" ]]; do
        debug_log "Fetching page $page"

        local response
        response=$(make_request "GET" "$endpoint" "" "$page")

        # Extract tasks from response
        local tasks
        tasks=$(echo "$response" | jq '.tasks // []')

        # Check if we got any tasks
        local task_count
        task_count=$(echo "$tasks" | jq '. | length')

        if [[ "$task_count" -gt 0 ]]; then
            # Append to all_tasks
            all_tasks=$(echo "$all_tasks" "$tasks" | jq -s 'add')
            debug_log "Added $task_count tasks from page $page"

            # Check if there might be more pages
            if [[ "$task_count" -lt "$DEFAULT_PAGE_SIZE" ]]; then
                has_more=false
            else
                ((page++))
            fi
        else
            has_more=false
        fi
    done

    # Return unified response
    echo "{\"tasks\": $all_tasks}"
}

# Helper function to validate JSON
validate_json() {
    echo "$1" | jq empty 2>/dev/null || error_exit "Invalid JSON provided"
}

# Show usage information
show_usage() {
    cat << EOF
${CYAN}ClickUp API Script - Enterprise Edition${NC}
Version: 2.2.0

${YELLOW}Usage:${NC} $0 [command] [args]

${YELLOW}Configuration:${NC}
  Set CLICKUP_TOKEN or CLICKUP_API_KEY environment variable
  Optional: Create .env file with configuration

${YELLOW}Environment Variables:${NC}
  CLICKUP_TOKEN           - API token (required)
  CLICKUP_ATTACHMENTS_DIR - Download directory (default: ./clickup_attachments)
  CLICKUP_TIMEOUT        - Request timeout in seconds (default: 30)
  CLICKUP_MAX_RETRIES    - Max retry attempts (default: 3)
  CLICKUP_DEFAULT_STATUS - Default task status (default: Open)
  CLICKUP_DEFAULT_PRIORITY - Default priority (default: 3)
  CLICKUP_DEBUG          - Enable debug output (default: false)

${YELLOW}Organization Commands:${NC}
  get-teams                           - List all teams
  get-spaces TEAM_ID                  - List spaces in team
  get-lists-in-space SPACE_ID         - List all lists in space
  get-folders SPACE_ID                - List folders in space
  get-lists-in-folder FOLDER_ID       - List lists in folder

${YELLOW}Task Commands:${NC}
  get-task TASK_ID                    - Get task details
  create-task LIST_ID NAME [DESC]     - Create task with defaults
  update-task TASK_ID NAME [DESC]     - Update task
  update-status TASK_ID STATUS        - Update status
  batch-update-status STATUS ID1 ID2  - Batch status update
  fetch-tasks LIST_ID                 - Get all tasks (with pagination)
  search-tasks TEAM_ID QUERY          - Search tasks
  get-subtasks TASK_ID                - Get task subtasks

${YELLOW}Team & Assignment:${NC}
  get-team-members TEAM_ID            - List team members
  assign-user TASK_ID USER_ID         - Assign user to task
  unassign-user TASK_ID USER_ID       - Unassign user from task

${YELLOW}Tags:${NC}
  list-space-tags SPACE_ID            - List tags in space
  create-space-tag SPACE_ID NAME [FG] [BG] - Create space tag
  delete-space-tag SPACE_ID NAME      - Delete space tag
  add-task-tag TASK_ID TAG            - Add tag to task
  remove-task-tag TASK_ID TAG         - Remove tag from task

${YELLOW}Custom Fields:${NC}
  list-custom-fields LIST_ID          - List custom fields
  set-custom-field TASK_ID FIELD_ID VALUE - Set custom field value
  get-task-custom-fields TASK_ID      - Get task custom fields

${YELLOW}Comments & Attachments:${NC}
  get-comments TASK_ID                - Get comments with replies
  add-comment TASK_ID TEXT            - Add comment
  resolve-comment COMMENT_ID          - Mark comment as resolved
  unresolve-comment COMMENT_ID        - Mark comment as unresolved
  assign-comment COMMENT_ID USER_ID   - Assign comment to user
  unassign-comment COMMENT_ID         - Unassign comment from user
  get-attachments TASK_ID             - List attachments
  download-attachment TASK_ID ATT_ID  - Download attachment
  auto-download-images TASK_ID        - Download all images

${YELLOW}Examples:${NC}
  # Create high-priority bug
  $0 create-task LIST_ID "Fix login" "SSO broken"

  # Batch update multiple tasks
  $0 batch-update-status "complete" task1 task2 task3

  # Fetch all tasks with pagination
  $0 fetch-tasks LIST_ID

${YELLOW}Advanced Features:${NC}
  • Automatic retry with exponential backoff
  • Respects Retry-After headers
  • Pagination support for large datasets
  • Safe filename sanitization
  • Debug mode for troubleshooting

For more help: $0 --help
EOF
}

# Main command processing
case "${1:-}" in
    "get-task")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required. Usage: $0 get-task TASK_ID"
        response=$(make_request "GET" "/task/$2?include_subtasks=true&include_task_comments=true")
        echo "$response" | jq '.'
        ;;

    "get-comments")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required. Usage: $0 get-comments TASK_ID"

        comments_data=$(make_request "GET" "/task/$2/comment")

        if [[ "$(echo "$comments_data" | jq '.comments | length')" -gt 0 ]]; then
            echo "$comments_data" | jq -c '.comments[]' | while read -r comment; do
                comment_id=$(echo "$comment" | jq -r '.id')
                reply_count=$(echo "$comment" | jq -r '.reply_count // 0')

                echo "$comment"

                if [[ "$reply_count" -gt 0 ]]; then
                    replies_data=$(make_request "GET" "/task/$2/comment/$comment_id")
                    echo "$replies_data" | jq -c '.replies[]? // empty' 2>/dev/null
                fi
            done | jq -s '{comments: .}'
        else
            echo '{"comments": []}'
        fi
        ;;

    "add-comment")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required. Usage: $0 add-comment TASK_ID TEXT"
        [[ -z "${3:-}" ]] && error_exit "Comment text required"

        data=$(jq -n --arg text "$3" '{comment_text: $text}')
        response=$(make_request "POST" "/task/$2/comment" "$data")
        echo "$response" | jq '.'
        success_msg "Comment added successfully"
        ;;

    "resolve-comment")
        [[ -z "${2:-}" ]] && error_exit "COMMENT_ID required. Usage: $0 resolve-comment COMMENT_ID"

        data=$(jq -n '{resolved: true}')
        response=$(make_request "PUT" "/comment/$2" "$data")
        echo "$response" | jq '.'
        success_msg "Comment marked as resolved"
        ;;

    "unresolve-comment")
        [[ -z "${2:-}" ]] && error_exit "COMMENT_ID required. Usage: $0 unresolve-comment COMMENT_ID"

        data=$(jq -n '{resolved: false}')
        response=$(make_request "PUT" "/comment/$2" "$data")
        echo "$response" | jq '.'
        success_msg "Comment marked as unresolved"
        ;;

    "assign-comment")
        [[ -z "${2:-}" ]] && error_exit "COMMENT_ID required. Usage: $0 assign-comment COMMENT_ID USER_ID"
        [[ -z "${3:-}" ]] && error_exit "USER_ID required"

        data=$(jq -n --arg user "$3" '{assignee: ($user | tonumber)}')
        response=$(make_request "PUT" "/comment/$2" "$data")
        echo "$response" | jq '.'
        success_msg "Comment assigned to user $3"
        ;;

    "unassign-comment")
        [[ -z "${2:-}" ]] && error_exit "COMMENT_ID required. Usage: $0 unassign-comment COMMENT_ID"

        data=$(jq -n '{assignee: null}')
        response=$(make_request "PUT" "/comment/$2" "$data")
        echo "$response" | jq '.'
        success_msg "Comment unassigned"
        ;;

    "get-attachments")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required"

        task_data=$(make_request "GET" "/task/$2")
        attachments=$(echo "$task_data" | jq '.attachments')

        if [[ "$(echo "$attachments" | jq '. | length')" -eq 0 ]]; then
            info_msg "No attachments found for task $2"
        else
            echo "$attachments" | jq '.'
        fi
        ;;

    "download-attachment")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required"
        [[ -z "${3:-}" ]] && error_exit "ATTACHMENT_ID required"

        mkdir -p "$ATTACHMENTS_DIR"

        task_data=$(make_request "GET" "/task/$2")
        attachment=$(echo "$task_data" | jq -r ".attachments[] | select(.id == \"$3\")")

        if [[ -z "$attachment" ]] || [[ "$attachment" == "null" ]]; then
            error_exit "Attachment $3 not found in task $2"
        fi

        url=$(echo "$attachment" | jq -r '.url')
        filename=$(echo "$attachment" | jq -r '.title')
        safe_filename=$(sanitize_filename "$filename")
        output_path="$ATTACHMENTS_DIR/$safe_filename"

        info_msg "Downloading: $filename"
        if curl -L -s -o "$output_path" "$url"; then
            success_msg "Downloaded to: $output_path"
        else
            error_exit "Download failed"
        fi
        ;;

    "auto-download-images")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required"

        mkdir -p "$ATTACHMENTS_DIR"
        task_data=$(make_request "GET" "/task/$2")

        image_count=$(echo "$task_data" | jq '[.attachments[] | select(.type == "image" or .title | test("\\.(jpg|jpeg|png|gif|webp|bmp|svg)$"; "i"))] | length')

        if [[ "$image_count" -eq 0 ]]; then
            info_msg "No image attachments found"
            exit 0
        fi

        info_msg "Found $image_count image(s) to download"

        echo "$task_data" | jq -r '.attachments[] | select(.type == "image" or .title | test("\\.(jpg|jpeg|png|gif|webp|bmp|svg)$"; "i")) | "\(.id)|\(.url)|\(.title)"' | while IFS='|' read -r id url title; do
            if [[ -n "$id" ]]; then
                safe_filename=$(sanitize_filename "$title")
                output_path="$ATTACHMENTS_DIR/$safe_filename"
                echo -n "  Downloading $title... "
                if curl -L -s -o "$output_path" "$url"; then
                    echo -e "${GREEN}✓${NC}"
                else
                    echo -e "${RED}✗${NC}"
                fi
            fi
        done

        success_msg "Downloads complete. Files in: $ATTACHMENTS_DIR"
        ;;

    "update-status")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required"
        [[ -z "${3:-}" ]] && error_exit "STATUS required"

        data=$(jq -n --arg status "$3" '{status: $status}')
        response=$(make_request "PUT" "/task/$2" "$data")
        echo "$response" | jq '.'
        success_msg "Status updated to: $3"
        ;;

    "create-task")
        [[ -z "${2:-}" ]] && error_exit "LIST_ID required"
        [[ -z "${3:-}" ]] && error_exit "Task name required"

        name=$3
        description=${4:-""}
        priority=${5:-$DEFAULT_PRIORITY}
        tags=${6:-""}
        status=${7:-$DEFAULT_STATUS}

        tags_json="[]"
        if [[ -n "$tags" ]]; then
            tags_json=$(echo "$tags" | jq -R 'split(",") | map(ltrimstr(" ") | rtrimstr(" ")) | map({name: .})')
        fi

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

        response=$(make_request "POST" "/list/$2/task" "$data")
        task_id=$(echo "$response" | jq -r '.id')
        echo "$response" | jq '.'
        success_msg "Task created. ID: $task_id"
        ;;

    "update-task")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required"
        [[ -z "${3:-}" ]] && error_exit "Task name required"

        task_id=$2
        new_name=$3
        new_description=${4:-}

        if [[ -n "$new_description" ]]; then
            data=$(jq -n \
                --arg name "$new_name" \
                --arg description "$new_description" \
                '{name: $name, description: $description}')
        else
            data=$(jq -n --arg name "$new_name" '{name: $name}')
        fi

        response=$(make_request "PUT" "/task/$task_id" "$data")
        echo "$response" | jq '.'
        success_msg "Task updated"
        ;;

    "batch-update-status")
        [[ -z "${2:-}" ]] && error_exit "STATUS required"

        status=$2
        shift 2

        [[ $# -eq 0 ]] && error_exit "At least one TASK_ID required"

        info_msg "Updating ${#} task(s) to status: $status"

        success_count=0
        fail_count=0

        for task_id in "$@"; do
            echo -n "  $task_id: "
            data=$(jq -n --arg status "$status" '{status: $status}')
            if make_request "PUT" "/task/$task_id" "$data" > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC}"
                ((success_count++))
            else
                echo -e "${RED}✗${NC}"
                ((fail_count++))
            fi
        done

        success_msg "Complete: $success_count succeeded, $fail_count failed"
        ;;

    "fetch-tasks")
        [[ -z "${2:-}" ]] && error_exit "LIST_ID required"

        list_id=$2
        include_archived=${3:-false}
        include_subtasks=${4:-true}

        endpoint="/list/${list_id}/task?archived=${include_archived}&subtasks=${include_subtasks}&include_closed=true&page_size=${DEFAULT_PAGE_SIZE}"

        # Fetch all pages and return unified result
        fetch_all_pages "$endpoint" | jq '.'
        ;;

    "search-tasks")
        [[ -z "${2:-}" ]] && error_exit "TEAM_ID required"
        [[ -z "${3:-}" ]] && error_exit "Search query required"

        team_id=$2
        query=$3

        encoded_query=$(echo "$query" | jq -sRr @uri)
        endpoint="/team/${team_id}/task?name=${encoded_query}&include_closed=true&page_size=${DEFAULT_PAGE_SIZE}"

        fetch_all_pages "$endpoint" | jq '.'
        ;;

    "get-list")
        [[ -z "${2:-}" ]] && error_exit "LIST_ID required"
        response=$(make_request "GET" "/list/$2")
        echo "$response" | jq '.'
        ;;

    "get-subtasks")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required"

        task_data=$(make_request "GET" "/task/$2?include_subtasks=true")
        subtasks=$(echo "$task_data" | jq '.subtasks')

        if [[ "$(echo "$subtasks" | jq '. | length')" -eq 0 ]]; then
            info_msg "No subtasks found"
        else
            echo "$subtasks" | jq '.'
        fi
        ;;

    # Organization Commands
    "get-teams")
        response=$(make_request "GET" "/team")
        echo "$response" | jq '.'
        ;;

    "get-spaces")
        [[ -z "${2:-}" ]] && error_exit "TEAM_ID required"
        response=$(make_request "GET" "/team/$2/space?archived=false")
        echo "$response" | jq '.'
        ;;

    "get-lists-in-space")
        [[ -z "${2:-}" ]] && error_exit "SPACE_ID required"
        response=$(make_request "GET" "/space/$2/list?archived=false")
        echo "$response" | jq '.'
        ;;

    "get-folders")
        [[ -z "${2:-}" ]] && error_exit "SPACE_ID required"
        response=$(make_request "GET" "/space/$2/folder?archived=false")
        echo "$response" | jq '.'
        ;;

    "get-lists-in-folder")
        [[ -z "${2:-}" ]] && error_exit "FOLDER_ID required"
        response=$(make_request "GET" "/folder/$2/list?archived=false")
        echo "$response" | jq '.'
        ;;

    # Team Member Commands
    "get-team-members")
        [[ -z "${2:-}" ]] && error_exit "TEAM_ID required"
        response=$(make_request "GET" "/team/$2")
        echo "$response" | jq '.'
        ;;

    "assign-user")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required"
        [[ -z "${3:-}" ]] && error_exit "USER_ID required"

        data=$(jq -n --arg user "$3" '{assignees: {add: [$user | tonumber]}}')
        response=$(make_request "PUT" "/task/$2" "$data")
        echo "$response" | jq '.'
        success_msg "User assigned to task"
        ;;

    "unassign-user")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required"
        [[ -z "${3:-}" ]] && error_exit "USER_ID required"

        data=$(jq -n --arg user "$3" '{assignees: {rem: [$user | tonumber]}}')
        response=$(make_request "PUT" "/task/$2" "$data")
        echo "$response" | jq '.'
        success_msg "User unassigned from task"
        ;;

    # Tag Commands
    "list-space-tags")
        [[ -z "${2:-}" ]] && error_exit "SPACE_ID required"
        response=$(make_request "GET" "/space/$2/tag")
        echo "$response" | jq '.'
        ;;

    "create-space-tag")
        [[ -z "${2:-}" ]] && error_exit "SPACE_ID required"
        [[ -z "${3:-}" ]] && error_exit "TAG_NAME required"

        tag_name=$3
        fg_color=${4:-"#0A84FF"}
        bg_color=${5:-"#FFFFFF"}

        data=$(jq -n \
            --arg name "$tag_name" \
            --arg fg "$fg_color" \
            --arg bg "$bg_color" \
            '{
                tag: {
                    name: $name,
                    tag_fg: $fg,
                    tag_bg: $bg
                }
            }')

        response=$(make_request "POST" "/space/$2/tag" "$data")
        echo "$response" | jq '.'
        success_msg "Tag created: $tag_name"
        ;;

    "delete-space-tag")
        [[ -z "${2:-}" ]] && error_exit "SPACE_ID required"
        [[ -z "${3:-}" ]] && error_exit "TAG_NAME required"

        data=$(jq -n --arg name "$3" '{tag: {name: $name}}')
        response=$(make_request "DELETE" "/space/$2/tag" "$data")
        echo "$response" | jq '.'
        success_msg "Tag deleted: $3"
        ;;

    "add-task-tag")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required"
        [[ -z "${3:-}" ]] && error_exit "TAG_NAME required"

        # Get current tags
        task_data=$(make_request "GET" "/task/$2")
        current_tags=$(echo "$task_data" | jq '[.tags[].name]')

        # Add new tag if not already present
        if echo "$current_tags" | jq -e ". | index(\"$3\")" > /dev/null 2>&1; then
            warn_msg "Tag '$3' already exists on task"
        else
            new_tags=$(echo "$current_tags" | jq ". + [\"$3\"]")
            data=$(jq -n --argjson tags "$new_tags" '{tags: $tags}')
            response=$(make_request "PUT" "/task/$2" "$data")
            echo "$response" | jq '.'
            success_msg "Tag added: $3"
        fi
        ;;

    "remove-task-tag")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required"
        [[ -z "${3:-}" ]] && error_exit "TAG_NAME required"

        # Get current tags
        task_data=$(make_request "GET" "/task/$2")
        current_tags=$(echo "$task_data" | jq '[.tags[].name]')

        # Remove tag if present
        if echo "$current_tags" | jq -e ". | index(\"$3\")" > /dev/null 2>&1; then
            new_tags=$(echo "$current_tags" | jq "del(.[] | select(. == \"$3\"))")
            data=$(jq -n --argjson tags "$new_tags" '{tags: $tags}')
            response=$(make_request "PUT" "/task/$2" "$data")
            echo "$response" | jq '.'
            success_msg "Tag removed: $3"
        else
            warn_msg "Tag '$3' not found on task"
        fi
        ;;

    # Custom Field Commands
    "list-custom-fields")
        [[ -z "${2:-}" ]] && error_exit "LIST_ID required"
        response=$(make_request "GET" "/list/$2/field")
        echo "$response" | jq '.'
        ;;

    "set-custom-field")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required"
        [[ -z "${3:-}" ]] && error_exit "FIELD_ID required"
        [[ -z "${4:-}" ]] && error_exit "FIELD_VALUE required"

        # Build custom field update
        data=$(jq -n \
            --arg field_id "$3" \
            --arg value "$4" \
            '{
                custom_fields: [{
                    id: $field_id,
                    value: $value
                }]
            }')

        response=$(make_request "PUT" "/task/$2/field/$3" "{\"value\": \"$4\"}")
        echo "$response" | jq '.'
        success_msg "Custom field updated"
        ;;

    "get-task-custom-fields")
        [[ -z "${2:-}" ]] && error_exit "TASK_ID required"

        task_data=$(make_request "GET" "/task/$2")
        custom_fields=$(echo "$task_data" | jq '.custom_fields')

        if [[ "$(echo "$custom_fields" | jq '. | length')" -eq 0 ]]; then
            info_msg "No custom fields found"
        else
            echo "$custom_fields" | jq '.'
        fi
        ;;

    "--help"|"-h"|"")
        show_usage
        ;;

    *)
        error_exit "Unknown command: $1\nRun '$0 --help' for usage"
        ;;
esac