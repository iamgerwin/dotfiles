#!/usr/bin/env bash
# Homebrew Installation Script for macOS
# This script safely installs Homebrew and sets up the environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is intended for macOS only"
    exit 1
fi

print_info "Starting Homebrew installation..."

# Check if Homebrew is already installed
if command -v brew &> /dev/null; then
    print_success "Homebrew is already installed"
    print_info "Version: $(brew --version | head -n 1)"
    
    # Ask if user wants to update
    read -p "Do you want to update Homebrew? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Updating Homebrew..."
        brew update
        print_success "Homebrew updated successfully"
    fi
else
    # Install Xcode Command Line Tools if needed
    if ! xcode-select -p &> /dev/null; then
        print_info "Installing Xcode Command Line Tools..."
        xcode-select --install
        
        # Wait for installation to complete
        until xcode-select -p &> /dev/null; do
            sleep 5
        done
        print_success "Xcode Command Line Tools installed"
    fi
    
    # Install Homebrew
    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Determine brew path based on architecture
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon
        BREW_PATH="/opt/homebrew/bin/brew"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        # Intel Mac
        BREW_PATH="/usr/local/bin/brew"
    else
        print_error "Could not find Homebrew installation"
        exit 1
    fi
    
    print_success "Homebrew installed successfully"
    
    # Add Homebrew to PATH for current session
    eval "$($BREW_PATH shellenv)"
    
    # Add Homebrew to shell profile
    print_info "Configuring shell environment..."
    
    # Determine shell config file
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_CONFIG="$HOME/.zprofile"
    else
        SHELL_CONFIG="$HOME/.bash_profile"
    fi
    
    # Add Homebrew to PATH in shell config
    if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$SHELL_CONFIG" 2>/dev/null && \
       ! grep -q 'eval "$(/usr/local/bin/brew shellenv)"' "$SHELL_CONFIG" 2>/dev/null; then
        echo '' >> "$SHELL_CONFIG"
        echo '# Homebrew' >> "$SHELL_CONFIG"
        echo "eval \"\$($BREW_PATH shellenv)\"" >> "$SHELL_CONFIG"
        print_success "Added Homebrew to $SHELL_CONFIG"
    fi
fi

# Verify installation
if command -v brew &> /dev/null; then
    print_success "Homebrew is ready to use"
    
    # Run brew doctor to check for issues
    print_info "Running brew doctor to check system..."
    if brew doctor 2>&1 | grep -q "Your system is ready to brew"; then
        print_success "Your system is ready to brew!"
    else
        print_info "Some warnings were found. Run 'brew doctor' to see details."
    fi
    
    # Display useful information
    echo
    print_info "Homebrew has been successfully installed!"
    echo "  Version: $(brew --version | head -n 1)"
    echo "  Prefix: $(brew --prefix)"
    echo
    print_info "Next steps:"
    echo "  1. Run 'brew bundle install' to install packages from Brewfile"
    echo "  2. Run 'brew install gemini-cli' to install Google Gemini CLI"
    echo "  3. Run 'brew help' to see available commands"
    echo "  4. Run 'brew doctor' if you encounter any issues"
else
    print_error "Homebrew installation failed"
    exit 1
fi