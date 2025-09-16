#!/bin/bash

# ClickUp Download Utility
# Enhanced file downloader with progress indication and validation
# Usage: ./clickup-download.sh [URL] [FILENAME] [OPTIONS]

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
MAX_RETRIES=3
TIMEOUT=30
USER_AGENT="ClickUp-Downloader/1.0"
VERBOSE=false

# Help function
show_help() {
    cat << EOF
ClickUp Download Utility
Version: 1.5.0

Usage: $0 [OPTIONS] URL FILENAME

Download files from URLs with retry logic and progress indication.

Arguments:
  URL         Source URL to download from
  FILENAME    Target filename/path for downloaded file

Options:
  -r, --retries NUM    Maximum retry attempts (default: 3)
  -t, --timeout SEC    Timeout in seconds (default: 30)
  -v, --verbose        Enable verbose output
  -q, --quiet          Quiet mode (suppress progress)
  -c, --continue       Resume partial downloads
  -h, --help           Show this help message

Examples:
  # Basic download
  $0 https://example.com/file.pdf /tmp/file.pdf

  # Download with retries and timeout
  $0 -r 5 -t 60 https://example.com/large.zip ~/downloads/large.zip

  # Resume interrupted download
  $0 --continue https://example.com/video.mp4 video.mp4

  # Verbose mode for debugging
  $0 -v https://example.com/data.json data.json

EOF
    exit 0
}

# Parse command line arguments
POSITIONAL_ARGS=()
CONTINUE_DOWNLOAD=""
QUIET_MODE=""

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
            CONTINUE_DOWNLOAD="-C -"
            shift
            ;;
        -h|--help)
            show_help
            ;;
        -*|--*)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            echo "Use -h or --help for usage information" >&2
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Restore positional parameters
set -- "${POSITIONAL_ARGS[@]}"

# Validate arguments
if [ $# -ne 2 ]; then
    echo -e "${RED}Error: Incorrect number of arguments${NC}" >&2
    echo "Usage: $0 [OPTIONS] URL FILENAME" >&2
    echo "Use -h or --help for more information" >&2
    exit 1
fi

URL=$1
FILENAME=$2

# Validate URL format
if ! [[ "$URL" =~ ^https?:// ]]; then
    echo -e "${RED}Error: Invalid URL format. URL must start with http:// or https://${NC}" >&2
    exit 1
fi

# Create directory if it doesn't exist
DIR=$(dirname "$FILENAME")
if [ "$DIR" != "." ] && [ "$DIR" != "/" ]; then
    mkdir -p "$DIR" || {
        echo -e "${RED}Error: Cannot create directory $DIR${NC}" >&2
        exit 1
    }
fi

# Function to check if file exists and get size
get_file_size() {
    if [ -f "$1" ]; then
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

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$((bytes / 1024))KB"
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# Function to perform download with retry logic
download_file() {
    local attempt=1
    local success=false

    while [ $attempt -le "$MAX_RETRIES" ] && [ "$success" = false ]; do
        if [ "$attempt" -gt 1 ]; then
            echo -e "${YELLOW}Retry attempt $attempt of $MAX_RETRIES...${NC}"
            sleep 2
        fi

        # Build curl command
        local curl_cmd=(curl)

        # Add continue flag if set
        [ -n "$CONTINUE_DOWNLOAD" ] && curl_cmd+=($CONTINUE_DOWNLOAD)

        # Add quiet mode or progress bar
        if [ -n "$QUIET_MODE" ]; then
            curl_cmd+=($QUIET_MODE)
        else
            curl_cmd+=(--progress-bar)
        fi

        # Add other options
        curl_cmd+=(
            --location
            --max-time "$TIMEOUT"
            --user-agent "$USER_AGENT"
            --output "$FILENAME"
        )

        # Add verbose flag if enabled
        [ "$VERBOSE" = true ] && curl_cmd+=(--verbose)

        # Add URL
        curl_cmd+=("$URL")

        # Execute download
        if [ "$VERBOSE" = true ]; then
            echo -e "${BLUE}Executing: ${curl_cmd[*]}${NC}"
        fi

        if "${curl_cmd[@]}"; then
            success=true
        else
            local exit_code=$?
            echo -e "${RED}Download failed with exit code: $exit_code${NC}" >&2

            case $exit_code in
                6)
                    echo "Could not resolve host" >&2
                    ;;
                7)
                    echo "Failed to connect to host" >&2
                    ;;
                28)
                    echo "Operation timed out" >&2
                    ;;
                35)
                    echo "SSL connection error" >&2
                    ;;
                *)
                    echo "Unknown error occurred" >&2
                    ;;
            esac

            ((attempt++))
        fi
    done

    return $([ "$success" = true ] && echo 0 || echo 1)
}

# Main execution
echo -e "${BLUE}Starting download...${NC}"
[ "$VERBOSE" = true ] && echo "URL: $URL"
[ "$VERBOSE" = true ] && echo "Target: $FILENAME"

# Check if file exists for resume
if [ -n "$CONTINUE_DOWNLOAD" ] && [ -f "$FILENAME" ]; then
    existing_size=$(get_file_size "$FILENAME")
    echo -e "${YELLOW}Resuming download. Current size: $(format_bytes "$existing_size")${NC}"
fi

# Perform download
if download_file; then
    # Verify file was created
    if [ -f "$FILENAME" ]; then
        final_size=$(get_file_size "$FILENAME")

        # Check if file is not empty
        if [ "$final_size" -gt 0 ]; then
            echo -e "${GREEN}✓ Successfully downloaded to: $FILENAME${NC}"
            echo -e "${GREEN}  Size: $(format_bytes "$final_size")${NC}"

            # Show file info if verbose
            if [ "$VERBOSE" = true ]; then
                echo -e "${BLUE}File info:${NC}"
                ls -lh "$FILENAME"
            fi

            exit 0
        else
            echo -e "${RED}Error: Downloaded file is empty${NC}" >&2
            rm -f "$FILENAME"
            exit 1
        fi
    else
        echo -e "${RED}Error: File was not created${NC}" >&2
        exit 1
    fi
else
    echo -e "${RED}Error: Download failed after $MAX_RETRIES attempts${NC}" >&2

    # Clean up partial download if not continuing
    if [ -z "$CONTINUE_DOWNLOAD" ] && [ -f "$FILENAME" ]; then
        echo -e "${YELLOW}Removing partial download${NC}"
        rm -f "$FILENAME"
    fi

    exit 1
fi