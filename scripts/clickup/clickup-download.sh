#!/bin/bash

# ClickUp Download Utility - Enterprise Edition
# Advanced file downloader with retry logic, sanitization, and safety features
# Usage: ./clickup-download.sh [OPTIONS] URL FILENAME

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

# ⚙️ Load configuration from .env if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# 🧰 Default configuration
readonly DEFAULT_MAX_RETRIES="${CLICKUP_DOWNLOAD_RETRIES:-3}"
readonly DEFAULT_TIMEOUT="${CLICKUP_DOWNLOAD_TIMEOUT:-30}"
readonly DEFAULT_USER_AGENT="${CLICKUP_USER_AGENT:-ClickUp-Downloader/2.0}"
readonly DEFAULT_RETRY_DELAY="${CLICKUP_RETRY_DELAY:-1}"
readonly DEFAULT_MAX_FILESIZE="${CLICKUP_MAX_FILESIZE:-5368709120}" # 5GB default

# Runtime configuration
MAX_RETRIES=$DEFAULT_MAX_RETRIES
TIMEOUT=$DEFAULT_TIMEOUT
USER_AGENT=$DEFAULT_USER_AGENT
VERBOSE=false
QUIET_MODE=""
CONTINUE_DOWNLOAD=""
CHECK_SIZE=true
FOLLOW_REDIRECTS=true

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
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${MAGENTA}🔍 Debug: $1${NC}" >&2
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
    filename="${filename//../_}"  # Prevent directory traversal

    # Remove leading/trailing spaces and dots
    filename="${filename#"${filename%%[![:space:]]*}"}"
    filename="${filename%"${filename##*[![:space:]]}"}"
    filename="${filename#.}"

    # Limit filename length to 255 characters
    if [[ ${#filename} -gt 255 ]]; then
        local extension="${filename##*.}"
        local name="${filename%.*}"
        if [[ "$extension" != "$filename" ]] && [[ ${#extension} -le 10 ]]; then
            # Preserve extension if it exists and is reasonable
            name="${name:0:$((244 - ${#extension}))}"
            filename="${name}.${extension}"
        else
            filename="${filename:0:255}"
        fi
    fi

    # Default if empty
    [[ -z "$filename" ]] && filename="unnamed_file_$(date +%s)"

    echo "$filename"
}

# Calculate exponential backoff delay
calculate_backoff() {
    local attempt=$1
    local base_delay=${2:-$DEFAULT_RETRY_DELAY}
    local max_delay=60
    local delay=$((base_delay * (2 ** (attempt - 1))))
    [[ $delay -gt $max_delay ]] && delay=$max_delay
    echo $delay
}

# Parse Retry-After header from response
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

# Get file size (cross-platform)
get_file_size() {
    if [[ -f "$1" ]]; then
        case "$(uname -s)" in
            Darwin)
                stat -f%z "$1" 2>/dev/null || echo "0"
                ;;
            Linux)
                stat -c%s "$1" 2>/dev/null || echo "0"
                ;;
            *)
                echo "0"
                ;;
        esac
    else
        echo "0"
    fi
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    if [[ "$bytes" -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ "$bytes" -lt 1048576 ]]; then
        echo "$((bytes / 1024))KB"
    elif [[ "$bytes" -lt 1073741824 ]]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# Validate URL
validate_url() {
    local url=$1

    # Check URL format
    if ! [[ "$url" =~ ^https?:// ]]; then
        error_exit "Invalid URL format. URL must start with http:// or https://"
    fi

    # Check for suspicious patterns (basic security check)
    if [[ "$url" =~ (file://|ftp://|sftp://|gopher://) ]]; then
        error_exit "Unsupported protocol. Only HTTP/HTTPS allowed"
    fi

    # Check for local/private IP addresses (optional security)
    if [[ "$url" =~ (127\.0\.0\.1|localhost|0\.0\.0\.0|192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.) ]]; then
        warn_msg "Warning: Downloading from local/private network"
    fi
}

# 🌐 HTTP wrapper with advanced features
download_with_retry() {
    local url=$1
    local output_file=$2
    local attempt=0
    local success=false

    # Create temp file for headers
    local headers_file
    headers_file=$(mktemp)
    trap "rm -f '$headers_file'" RETURN

    while [[ $attempt -lt $MAX_RETRIES ]] && [[ "$success" == "false" ]]; do
        ((attempt++))

        if [[ $attempt -gt 1 ]]; then
            local backoff_delay
            backoff_delay=$(calculate_backoff "$attempt")
            warn_msg "Retry attempt $attempt/$MAX_RETRIES (waiting ${backoff_delay}s)..."
            sleep "$backoff_delay"
        fi

        debug_log "Attempt $attempt/$MAX_RETRIES for $url"

        # Build curl command
        local curl_cmd=(
            curl
            --location-trusted
            --max-time "$TIMEOUT"
            --user-agent "$USER_AGENT"
            --output "$output_file"
            --dump-header "$headers_file"
            --write-out "%{http_code}"
        )

        # Add continue flag if set
        [[ -n "$CONTINUE_DOWNLOAD" ]] && curl_cmd+=(--continue-at -)

        # Add quiet mode or progress bar
        if [[ -n "$QUIET_MODE" ]]; then
            curl_cmd+=(--silent)
        else
            curl_cmd+=(--progress-bar)
        fi

        # Add follow redirects
        [[ "$FOLLOW_REDIRECTS" == "true" ]] && curl_cmd+=(--location)

        # Add verbose flag if enabled
        [[ "$VERBOSE" == "true" ]] && curl_cmd+=(--verbose)

        # Add size limit if checking
        [[ "$CHECK_SIZE" == "true" ]] && curl_cmd+=(--max-filesize "$DEFAULT_MAX_FILESIZE")

        # Add URL
        curl_cmd+=("$url")

        # Execute download
        debug_log "Executing: ${curl_cmd[*]}"

        local http_code
        if http_code=$("${curl_cmd[@]}" 2>&1); then
            debug_log "HTTP Status: $http_code"

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
                    if [[ $attempt -lt $MAX_RETRIES ]]; then
                        warn_msg "Server error ($http_code). Will retry..."
                    else
                        error_exit "Server error ($http_code) after $MAX_RETRIES attempts"
                    fi
                    ;;
                4*) # Client error - don't retry
                    error_exit "Client error (HTTP $http_code). Check URL and permissions"
                    ;;
                *)
                    if [[ $attempt -lt $MAX_RETRIES ]]; then
                        warn_msg "Unexpected status ($http_code). Will retry..."
                    else
                        error_exit "Failed with HTTP $http_code after $MAX_RETRIES attempts"
                    fi
                    ;;
            esac
        else
            local exit_code=$?
            debug_log "curl exit code: $exit_code"

            case $exit_code in
                6)
                    error_exit "Could not resolve host"
                    ;;
                7)
                    error_exit "Failed to connect to host"
                    ;;
                28)
                    warn_msg "Operation timed out"
                    ;;
                35)
                    warn_msg "SSL connection error"
                    ;;
                63)
                    error_exit "File size exceeds maximum allowed ($(format_bytes $DEFAULT_MAX_FILESIZE))"
                    ;;
                *)
                    warn_msg "Download error (code: $exit_code)"
                    ;;
            esac

            if [[ $attempt -ge $MAX_RETRIES ]]; then
                error_exit "Download failed after $MAX_RETRIES attempts"
            fi
        fi
    done

    return $([ "$success" = true ] && echo 0 || echo 1)
}

# Show usage information
show_usage() {
    cat << EOF
${CYAN}ClickUp Download Utility - Enterprise Edition${NC}
Version: 2.0.0

${YELLOW}Usage:${NC} $0 [OPTIONS] URL FILENAME

${YELLOW}Description:${NC}
  Advanced file downloader with retry logic, safety features, and progress indication.

${YELLOW}Arguments:${NC}
  URL         Source URL to download from (HTTP/HTTPS only)
  FILENAME    Target filename/path for downloaded file

${YELLOW}Options:${NC}
  -r, --retries NUM     Maximum retry attempts (default: $DEFAULT_MAX_RETRIES)
  -t, --timeout SEC     Timeout in seconds (default: $DEFAULT_TIMEOUT)
  -v, --verbose         Enable verbose output for debugging
  -q, --quiet           Quiet mode (suppress progress bar)
  -c, --continue        Resume partial downloads
  -n, --no-follow       Don't follow redirects
  -s, --skip-size       Skip file size limit check
  -h, --help            Show this help message

${YELLOW}Environment Variables:${NC}
  CLICKUP_DOWNLOAD_RETRIES   Max retry attempts
  CLICKUP_DOWNLOAD_TIMEOUT   Request timeout
  CLICKUP_USER_AGENT         Custom User-Agent
  CLICKUP_RETRY_DELAY        Base retry delay
  CLICKUP_MAX_FILESIZE       Max file size limit

${YELLOW}Examples:${NC}
  # Basic download
  $0 https://example.com/file.pdf report.pdf

  # Download with custom retries and timeout
  $0 -r 5 -t 60 https://example.com/large.zip archive.zip

  # Resume interrupted download
  $0 --continue https://example.com/video.mp4 video.mp4

  # Quiet mode (no progress bar)
  $0 -q https://example.com/data.json data.json

  # Verbose debugging
  $0 -v https://example.com/file.txt debug.txt

${YELLOW}Advanced Features:${NC}
  • Automatic retry with exponential backoff
  • Respects Retry-After headers for rate limiting
  • Filename sanitization for security
  • File size limit protection
  • Cross-platform compatibility
  • Comprehensive error handling

EOF
    exit 0
}

# Parse command line arguments
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--retries)
            MAX_RETRIES="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            QUIET_MODE="--silent"
            shift
            ;;
        -c|--continue)
            CONTINUE_DOWNLOAD="--continue-at -"
            shift
            ;;
        -n|--no-follow)
            FOLLOW_REDIRECTS=false
            shift
            ;;
        -s|--skip-size)
            CHECK_SIZE=false
            shift
            ;;
        -h|--help)
            show_usage
            ;;
        -*|--*)
            error_exit "Unknown option: $1\nUse -h or --help for usage"
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Restore positional parameters
set -- "${POSITIONAL_ARGS[@]:-}"

# Validate arguments
if [[ $# -ne 2 ]]; then
    error_exit "Incorrect number of arguments\nUsage: $0 [OPTIONS] URL FILENAME\nUse -h for help"
fi

URL=$1
FILENAME=$2

# Validate and sanitize inputs
validate_url "$URL"

# Sanitize filename
SAFE_FILENAME=$(sanitize_filename "$FILENAME")
if [[ "$FILENAME" != "$SAFE_FILENAME" ]]; then
    warn_msg "Filename sanitized: '$FILENAME' → '$SAFE_FILENAME'"
    FILENAME="$SAFE_FILENAME"
fi

# Create directory if needed
DIR=$(dirname "$FILENAME")
if [[ "$DIR" != "." ]] && [[ "$DIR" != "/" ]]; then
    debug_log "Creating directory: $DIR"
    mkdir -p "$DIR" || error_exit "Cannot create directory: $DIR"
fi

# Main execution
info_msg "Starting download..."
[[ "$VERBOSE" == "true" ]] && debug_log "URL: $URL"
[[ "$VERBOSE" == "true" ]] && debug_log "Target: $FILENAME"

# Check if file exists for resume
if [[ -n "$CONTINUE_DOWNLOAD" ]] && [[ -f "$FILENAME" ]]; then
    existing_size=$(get_file_size "$FILENAME")
    info_msg "Resuming download. Current size: $(format_bytes "$existing_size")"
fi

# Perform download with retry logic
if download_with_retry "$URL" "$FILENAME"; then
    # Verify file was created
    if [[ -f "$FILENAME" ]]; then
        final_size=$(get_file_size "$FILENAME")

        # Check if file is not empty
        if [[ "$final_size" -gt 0 ]]; then
            success_msg "Downloaded successfully!"
            info_msg "File: $FILENAME"
            info_msg "Size: $(format_bytes "$final_size")"

            # Show file info if verbose
            if [[ "$VERBOSE" == "true" ]]; then
                debug_log "File details:"
                ls -lh "$FILENAME"
            fi

            exit 0
        else
            error_exit "Downloaded file is empty"
        fi
    else
        error_exit "File was not created"
    fi
else
    # Clean up partial download if not continuing
    if [[ -z "$CONTINUE_DOWNLOAD" ]] && [[ -f "$FILENAME" ]]; then
        warn_msg "Removing partial download"
        rm -f "$FILENAME"
    fi

    error_exit "Download failed"
fi