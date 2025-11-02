#!/usr/bin/env bash
# AI CLI Tools Setup Script
# Configures Claude, Gemini, and Codex CLI tools with API keys

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

# Check if running on macOS or Linux
if [[ "$OSTYPE" != "darwin"* ]] && [[ "$OSTYPE" != "linux-gnu"* ]]; then
    print_error "This script is intended for macOS and Linux only"
    exit 1
fi

print_header "AI CLI Tools Setup"
echo

# Configuration file
ZSHRC_PRIVATE="$HOME/.zshrc.private"
DOTFILES_DIR="$HOME/dotfiles"

# Ensure .zshrc.private exists
if [[ ! -f "$ZSHRC_PRIVATE" ]]; then
    touch "$ZSHRC_PRIVATE"
    print_success "Created $ZSHRC_PRIVATE"
fi

# Check which AI CLI tools are installed
print_info "Checking installed AI CLI tools..."
echo

CLAUDE_INSTALLED=false
GEMINI_INSTALLED=false
CODEX_INSTALLED=false

if command -v claude &> /dev/null; then
    CLAUDE_INSTALLED=true
    print_success "Claude Code is installed"
else
    print_info "Claude Code is not installed (run: brew install --cask claude-code)"
fi

if command -v gemini &> /dev/null || command -v gemini-cli &> /dev/null; then
    GEMINI_INSTALLED=true
    print_success "Gemini CLI is installed"
else
    print_info "Gemini CLI is not installed (run: brew install gemini-cli)"
fi

if command -v codex &> /dev/null; then
    CODEX_INSTALLED=true
    print_success "Codex CLI is installed"
else
    print_info "Codex CLI is not installed (run: brew install --cask codex)"
fi

echo

# Function to check if API key is already set
check_api_key() {
    local key_name=$1
    if grep -q "export ${key_name}=" "$ZSHRC_PRIVATE" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Function to add or update API key
add_api_key() {
    local key_name=$1
    local key_value=$2

    # Remove existing key if present
    if check_api_key "$key_name"; then
        sed -i.bak "/export ${key_name}=/d" "$ZSHRC_PRIVATE"
        rm -f "${ZSHRC_PRIVATE}.bak"
    fi

    # Add new key
    echo "export ${key_name}=\"${key_value}\"" >> "$ZSHRC_PRIVATE"
}

# Configure Claude
if [[ "$CLAUDE_INSTALLED" = true ]]; then
    echo
    print_header "Claude Code Configuration"

    if check_api_key "CLAUDE_API_KEY" || check_api_key "ANTHROPIC_API_KEY"; then
        print_info "Claude API key is already configured"
        read -p "Do you want to update it? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping Claude configuration"
        else
            read -sp "Enter your Claude/Anthropic API key: " CLAUDE_KEY
            echo
            if [[ -n "$CLAUDE_KEY" ]]; then
                add_api_key "CLAUDE_API_KEY" "$CLAUDE_KEY"
                add_api_key "ANTHROPIC_API_KEY" "$CLAUDE_KEY"
                print_success "Claude API key configured"
            fi
        fi
    else
        print_info "Claude Code requires authentication via Claude Console"
        print_info "Visit: https://console.anthropic.com/ for billing setup"
        print_info "Or get API key at: https://console.anthropic.com/"
        echo
        read -p "Do you want to configure it now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -sp "Enter your Claude/Anthropic API key: " CLAUDE_KEY
            echo
            if [[ -n "$CLAUDE_KEY" ]]; then
                add_api_key "CLAUDE_API_KEY" "$CLAUDE_KEY"
                add_api_key "ANTHROPIC_API_KEY" "$CLAUDE_KEY"
                print_success "Claude API key configured"
            else
                print_error "No API key provided"
            fi
        fi
    fi
fi

# Configure Gemini
if [[ "$GEMINI_INSTALLED" = true ]]; then
    echo
    print_header "Gemini CLI Configuration"

    if check_api_key "GEMINI_API_KEY"; then
        print_info "Gemini API key is already configured"
        read -p "Do you want to update it? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping Gemini configuration"
        else
            read -sp "Enter your Gemini API key: " GEMINI_KEY
            echo
            if [[ -n "$GEMINI_KEY" ]]; then
                add_api_key "GEMINI_API_KEY" "$GEMINI_KEY"
                print_success "Gemini API key configured"
            fi
        fi
    else
        print_info "Gemini CLI requires an API key from Google AI Studio"
        print_info "Get your key at: https://makersuite.google.com/app/apikey"
        echo
        read -p "Do you want to configure it now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -sp "Enter your Gemini API key: " GEMINI_KEY
            echo
            if [[ -n "$GEMINI_KEY" ]]; then
                add_api_key "GEMINI_API_KEY" "$GEMINI_KEY"
                print_success "Gemini API key configured"
            else
                print_error "No API key provided"
            fi
        fi
    fi
fi

# Configure Codex
if [[ "$CODEX_INSTALLED" = true ]]; then
    echo
    print_header "Codex CLI Configuration"

    if check_api_key "OPENAI_API_KEY"; then
        print_info "OpenAI API key is already configured"
        read -p "Do you want to update it? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping Codex configuration"
        else
            read -sp "Enter your OpenAI API key: " OPENAI_KEY
            echo
            if [[ -n "$OPENAI_KEY" ]]; then
                add_api_key "OPENAI_API_KEY" "$OPENAI_KEY"
                print_success "OpenAI API key configured"
            fi
        fi
    else
        print_info "Codex CLI requires an API key from OpenAI"
        print_info "Get your key at: https://platform.openai.com/api-keys"
        echo
        read -p "Do you want to configure it now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -sp "Enter your OpenAI API key: " OPENAI_KEY
            echo
            if [[ -n "$OPENAI_KEY" ]]; then
                add_api_key "OPENAI_API_KEY" "$OPENAI_KEY"
                print_success "OpenAI API key configured"
            else
                print_error "No API key provided"
            fi
        fi
    fi
fi

# Create symlinks for documentation
echo
print_header "Documentation Setup"

if [[ -d "$DOTFILES_DIR/docs/ai-tools" ]]; then
    print_info "Creating documentation symlinks..."

    cd "$DOTFILES_DIR"

    # Create symlinks if they don't exist or are broken
    for doc in CLAUDE.md GEMINI.md CODEX.md AGENTS.md; do
        if [[ ! -L "$doc" ]] || [[ ! -e "$doc" ]]; then
            ln -sf docs/ai-tools/AI.md "$doc"
            print_success "Created symlink: $doc -> docs/ai-tools/AI.md"
        else
            print_info "Symlink already exists: $doc"
        fi
    done
else
    print_error "Documentation directory not found: $DOTFILES_DIR/docs/ai-tools"
fi

# Summary
echo
print_header "Setup Complete"
echo
print_info "Configuration Summary:"
echo "  • API keys stored in: $ZSHRC_PRIVATE"
echo "  • Documentation: $DOTFILES_DIR/docs/ai-tools/AI.md"
echo
print_info "Next Steps:"
echo "  1. Run 'source ~/.zshrc' to reload your shell configuration"
echo "  2. Read the documentation: cat ~/dotfiles/docs/ai-tools/AI.md"
echo "  3. Test your setup:"

if [[ "$CLAUDE_INSTALLED" = true ]]; then
    echo "     • claude --version (or just run 'claude' for interactive mode)"
fi
if [[ "$GEMINI_INSTALLED" = true ]]; then
    echo "     • gemini --version"
fi
if [[ "$CODEX_INSTALLED" = true ]]; then
    echo "     • codex --version"
fi

echo
print_info "For usage examples and best practices, see:"
echo "  ~/dotfiles/docs/ai-tools/AI.md"
echo

print_success "AI CLI Tools setup complete!"
