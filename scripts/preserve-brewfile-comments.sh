#!/usr/bin/env bash
#
# Preserve Brewfile Comments Script
# This script merges brew bundle dump output with existing comments
# Usage: ./preserve-brewfile-comments.sh

set -euo pipefail

BREWFILE="$HOME/dotfiles/Brewfile"
BREWFILE_COMMENTED="$HOME/dotfiles/Brewfile.lock.commented"
BREWFILE_TEMP="$HOME/dotfiles/Brewfile.tmp"

# Function to extract comment for a package
get_comment() {
    local line="$1"
    local pattern="$2"

    # Escape special regex characters in the pattern
    escaped_pattern=$(echo "$pattern" | sed 's/[[\.*^$()+?{|]/\\&/g')

    # Look for the line in the commented file and extract its comment
    comment=$(grep -F "$pattern" "$BREWFILE_COMMENTED" 2>/dev/null | sed -n 's/.*#\(.*\)$/\#\1/p' | head -1)

    if [[ -n "$comment" ]]; then
        echo "$line $comment"
    else
        echo "$line"
    fi
}

# Function to merge comments with brew bundle dump output
merge_with_comments() {
    local current_section=""

    while IFS= read -r line; do
        # Skip empty lines
        if [[ -z "$line" ]]; then
            echo ""
            continue
        fi

        # Check for section headers from commented file
        if [[ "$line" =~ ^tap ]]; then
            if [[ "$current_section" != "taps" ]]; then
                echo "# Taps"
                current_section="taps"
            fi
        elif [[ "$line" =~ ^brew ]]; then
            if [[ "$current_section" != "brew" ]]; then
                echo ""
                echo "# Command Line Tools & Development"
                current_section="brew"
            fi
        elif [[ "$line" =~ ^cask && "$line" =~ font- ]]; then
            if [[ "$current_section" != "fonts" ]]; then
                echo ""
                echo "# Fonts"
                current_section="fonts"
            fi
        elif [[ "$line" =~ ^cask ]]; then
            if [[ "$current_section" != "cask" ]]; then
                echo ""
                echo "# macOS Applications"
                current_section="cask"
            fi
        elif [[ "$line" =~ ^vscode ]]; then
            if [[ "$current_section" != "vscode" ]]; then
                echo ""
                echo "# VS Code Extensions"
                current_section="vscode"
            fi
        elif [[ "$line" =~ ^mas ]]; then
            if [[ "$current_section" != "mas" ]]; then
                echo ""
                echo "# Mac App Store Applications"
                current_section="mas"
            fi
        fi

        # Extract the package identifier for matching
        if echo "$line" | grep -qE '^(tap|brew|cask|vscode|mas)[[:space:]]+"[^"]+"'; then
            package_id=$(echo "$line" | sed -n 's/^[^"]*"\([^"]*\)".*/\1/p')
            # Get the line with its comment if it exists
            get_comment "$line" "$package_id"
        else
            echo "$line"
        fi
    done
}

# Main execution
main() {
    # Check if commented file exists
    if [[ ! -f "$BREWFILE_COMMENTED" ]]; then
        echo "Warning: No commented Brewfile found at $BREWFILE_COMMENTED"
        echo "Creating initial commented file from current Brewfile..."
        cp "$BREWFILE" "$BREWFILE_COMMENTED"
    fi

    # Generate fresh brew bundle dump
    echo "Generating fresh Brewfile from installed packages..."
    # Use timeout to prevent hanging and redirect stderr to prevent interactive prompts
    timeout 10 brew bundle dump --force --file="$BREWFILE_TEMP" --no-upgrade 2>/dev/null || {
        echo "Error: Failed to generate Brewfile (timed out or error occurred)"
        rm -f "$BREWFILE_TEMP"
        exit 1
    }

    # Merge with comments
    echo "Merging with existing comments..."
    merge_with_comments < "$BREWFILE_TEMP" > "$BREWFILE"

    # Clean up
    rm -f "$BREWFILE_TEMP"

    echo "✓ Brewfile updated with preserved comments"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi