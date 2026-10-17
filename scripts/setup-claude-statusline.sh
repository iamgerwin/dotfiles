#!/usr/bin/env bash
# Claude Code Status Line Setup Script
# Links config/claude/statusline-command.sh into ~/.claude and points the
# statusLine entry of ~/.claude/settings.json at it. Other settings are kept.

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

if [[ "$OSTYPE" != "darwin"* ]] && [[ "$OSTYPE" != "linux-gnu"* ]]; then
    print_error "This script is intended for macOS and Linux only"
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$DOTFILES_DIR/config/claude/statusline-command.sh"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
TARGET="$CLAUDE_DIR/statusline-command.sh"
SETTINGS="$CLAUDE_DIR/settings.json"
COMMAND="bash $TARGET"

print_header "Claude Code Status Line Setup"
echo

if ! command -v jq &> /dev/null; then
    print_error "jq not found. Install it first (brew install jq / sudo apt install jq)."
    exit 1
fi

if [[ ! -f "$SOURCE" ]]; then
    print_error "Status line script not found at $SOURCE"
    exit 1
fi

mkdir -p "$CLAUDE_DIR"

# Link the script, backing up any regular file already in place
if [[ -L "$TARGET" ]] && [[ "$(readlink "$TARGET")" == "$SOURCE" ]]; then
    print_success "Status line script already linked"
else
    if [[ -e "$TARGET" ]] && [[ ! -L "$TARGET" ]]; then
        backup="$TARGET.backup.$(date +%Y%m%d%H%M%S)"
        mv "$TARGET" "$backup"
        print_info "Existing script backed up to $backup"
    fi
    ln -sfn "$SOURCE" "$TARGET"
    print_success "Linked $TARGET -> $SOURCE"
fi

# Set statusLine in settings.json without touching other keys
if [[ ! -s "$SETTINGS" ]]; then
    echo '{}' > "$SETTINGS"
fi

if ! jq empty "$SETTINGS" &> /dev/null; then
    print_error "$SETTINGS is not valid JSON; fix it and re-run"
    exit 1
fi

current=$(jq -r '.statusLine.command // empty' "$SETTINGS")
if [[ "$current" == "$COMMAND" ]]; then
    print_success "settings.json already uses this status line"
else
    cp "$SETTINGS" "$SETTINGS.backup.$(date +%Y%m%d%H%M%S)"
    tmp=$(mktemp)
    jq --arg cmd "$COMMAND" '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$tmp"
    # Write in place so a symlinked settings.json and its permissions survive
    cat "$tmp" > "$SETTINGS"
    rm -f "$tmp"
    print_success "statusLine set in $SETTINGS (previous file backed up)"
fi

echo
print_info "Restart Claude Code to load the status line. Glyphs need a Nerd Font."
