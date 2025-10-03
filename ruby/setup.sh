#!/usr/bin/env bash

# Ruby and Rails Setup Script
# Installs Ruby via rbenv and sets up Rails development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUBY_VERSION=$(cat "$SCRIPT_DIR/.ruby-version")

echo -e "${GREEN}=== Ruby and Rails Setup ===${NC}"
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Error: Homebrew is not installed${NC}"
    echo "Please install Homebrew first: https://brew.sh"
    exit 1
fi

echo -e "${YELLOW}Installing dependencies via Homebrew...${NC}"
cd "$SCRIPT_DIR/.." && brew bundle --file=Brewfile

# Initialize rbenv if not already in PATH
if ! command -v rbenv &> /dev/null; then
    echo -e "${RED}Error: rbenv not found in PATH${NC}"
    echo "Please restart your shell or run: eval \"\$(rbenv init - zsh)\""
    exit 1
fi

# Check if rbenv is initialized
if ! rbenv version &> /dev/null; then
    echo -e "${YELLOW}Initializing rbenv...${NC}"
    eval "$(rbenv init - zsh)"
fi

echo ""
echo -e "${YELLOW}Installing Ruby ${RUBY_VERSION}...${NC}"

# Check if Ruby version is already installed
if rbenv versions | grep -q "$RUBY_VERSION"; then
    echo -e "${GREEN}Ruby ${RUBY_VERSION} is already installed${NC}"
else
    # Install Ruby with optimizations
    RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3) --with-readline-dir=$(brew --prefix readline) --with-libyaml-dir=$(brew --prefix libyaml)" \
    rbenv install "$RUBY_VERSION"
    echo -e "${GREEN}Ruby ${RUBY_VERSION} installed successfully${NC}"
fi

# Set global Ruby version
echo -e "${YELLOW}Setting global Ruby version to ${RUBY_VERSION}...${NC}"
rbenv global "$RUBY_VERSION"
rbenv rehash

# Verify Ruby installation
CURRENT_RUBY=$(ruby -v)
echo -e "${GREEN}Active Ruby version: ${CURRENT_RUBY}${NC}"

# Copy .gemrc to home directory
echo ""
echo -e "${YELLOW}Configuring gem settings...${NC}"
if [ -f "$HOME/.gemrc" ]; then
    echo -e "${YELLOW}Backing up existing .gemrc to .gemrc.backup${NC}"
    cp "$HOME/.gemrc" "$HOME/.gemrc.backup"
fi
cp "$SCRIPT_DIR/.gemrc" "$HOME/.gemrc"
echo -e "${GREEN}.gemrc configuration applied${NC}"

# Update RubyGems
echo ""
echo -e "${YELLOW}Updating RubyGems...${NC}"
gem update --system
rbenv rehash

# Install Bundler
echo ""
echo -e "${YELLOW}Installing Bundler...${NC}"
gem install bundler
rbenv rehash

# Install Rails
echo ""
echo -e "${YELLOW}Installing Rails (latest stable version)...${NC}"
gem install rails
rbenv rehash

# Verify installations
BUNDLER_VERSION=$(bundle -v)
RAILS_VERSION=$(rails -v)

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo -e "Ruby:    ${GREEN}$(ruby -v)${NC}"
echo -e "Gem:     ${GREEN}$(gem -v)${NC}"
echo -e "Bundler: ${GREEN}${BUNDLER_VERSION}${NC}"
echo -e "Rails:   ${GREEN}${RAILS_VERSION}${NC}"
echo ""
echo -e "${YELLOW}To verify rbenv is working correctly:${NC}"
echo -e "  which ruby    # Should show: $HOME/.rbenv/shims/ruby"
echo -e "  which rails   # Should show: $HOME/.rbenv/shims/rails"
echo ""
echo -e "${YELLOW}To create a new Rails application:${NC}"
echo -e "  rails new myapp"
echo -e "  cd myapp"
echo -e "  bundle install"
echo -e "  rails server"
echo ""
echo -e "${GREEN}Setup complete! Happy coding!${NC}"
