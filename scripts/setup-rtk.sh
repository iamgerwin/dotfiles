#!/usr/bin/env bash
# rtk-ai Setup Script
# Installs rtk (https://github.com/rtk-ai/rtk) globally and wires it into
# Claude Code, Codex CLI, and OpenCode via `rtk init`.

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

print_header "rtk-ai Setup"
echo

# Install rtk globally via Homebrew if missing
if command -v rtk &> /dev/null; then
    print_success "rtk is already installed ($(rtk --version))"
else
    print_info "Installing rtk via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install rtk
        print_success "rtk installed"
    else
        print_error "Homebrew not found. Install Homebrew first, then re-run this script."
        exit 1
    fi
fi

echo

# Wire rtk into each installed assistant CLI
if command -v claude &> /dev/null; then
    print_header "Claude Code"
    rtk init -g --auto-patch
    print_success "rtk hook installed for Claude Code (global)"
    echo
else
    print_info "Claude Code not installed, skipping (run: brew install --cask claude-code)"
fi

if command -v codex &> /dev/null; then
    print_header "Codex CLI"
    rtk init --codex -g
    print_success "rtk AGENTS.md/RTK.md installed for Codex (global)"
    echo
else
    print_info "Codex CLI not installed, skipping (run: brew install --cask codex)"
fi

if command -v opencode &> /dev/null; then
    print_header "OpenCode"
    rtk init --opencode -g --auto-patch
    print_success "rtk plugin installed for OpenCode (global)"
    echo
else
    print_info "OpenCode not installed, skipping (run: brew install opencode)"
fi

print_header "Setup Complete"
echo
print_info "Verify with:"
echo "  rtk --version"
echo "  rtk gain"
echo "  which rtk"
echo
print_success "rtk-ai setup complete!"
