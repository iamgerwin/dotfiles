#!/usr/bin/env bash
# gh-stack Setup Script
# Installs the gh-stack GitHub CLI extension (https://github.com/github/gh-stack)
# and the corresponding agent skill for Claude Code, Codex, and OpenCode.

set -e  # Exit on error

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

if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed. Run: brew install gh"
    exit 1
fi

print_header "gh-stack Setup"
echo

# Install the gh-stack extension
if gh extension list | grep -q "github/gh-stack"; then
    print_success "gh-stack extension is already installed"
else
    print_info "Installing gh-stack extension..."
    gh extension install github/gh-stack
    print_success "gh-stack extension installed"
fi

echo

# Install the gh-stack skill for each installed assistant CLI (user scope)
for agent in claude-code codex opencode; do
    print_info "Installing gh-stack skill for ${agent} (user scope)..."
    if gh skill install github/gh-stack --agent "$agent" --scope user --force; then
        print_success "gh-stack skill installed for ${agent}"
    else
        print_error "Failed to install gh-stack skill for ${agent}"
    fi
done

echo
print_header "Setup Complete"
echo
print_info "Verify with:"
echo "  gh extension list"
echo "  gh skill list"
echo "  gh stack --help"
echo
print_success "gh-stack setup complete!"
