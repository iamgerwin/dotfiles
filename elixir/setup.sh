#!/usr/bin/env bash

# Elixir, Phoenix, and Ash Setup Script
# Installs Erlang and Elixir via asdf and sets up modern functional programming environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read versions from .tool-versions
ERLANG_VERSION=$(grep erlang "$SCRIPT_DIR/.tool-versions" | awk '{print $2}')
ELIXIR_VERSION=$(grep elixir "$SCRIPT_DIR/.tool-versions" | awk '{print $2}')

echo -e "${GREEN}=== Elixir, Phoenix, and Ash Setup ===${NC}"
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Error: Homebrew is not installed${NC}"
    echo "Please install Homebrew first: https://brew.sh"
    exit 1
fi

echo -e "${YELLOW}Installing dependencies via Homebrew...${NC}"
cd "$SCRIPT_DIR/.." && brew bundle --file=Brewfile

# Initialize asdf if not already in PATH
if ! command -v asdf &> /dev/null; then
    echo -e "${YELLOW}Initializing asdf...${NC}"
    if [ -f "$(brew --prefix asdf)/libexec/asdf.sh" ]; then
        source "$(brew --prefix asdf)/libexec/asdf.sh"
    else
        echo -e "${RED}Error: asdf not found${NC}"
        echo "Please restart your shell or add asdf to your PATH"
        exit 1
    fi
fi

# Add asdf plugins
echo ""
echo -e "${YELLOW}Adding asdf plugins...${NC}"

if ! asdf plugin list | grep -q "erlang"; then
    echo -e "${YELLOW}Adding erlang plugin...${NC}"
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
else
    echo -e "${GREEN}Erlang plugin already installed${NC}"
fi

if ! asdf plugin list | grep -q "elixir"; then
    echo -e "${YELLOW}Adding elixir plugin...${NC}"
    asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git
else
    echo -e "${GREEN}Elixir plugin already installed${NC}"
fi

# Install Erlang
echo ""
echo -e "${YELLOW}Installing Erlang ${ERLANG_VERSION}...${NC}"
echo -e "${YELLOW}This may take 15-30 minutes as Erlang is compiled from source${NC}"

if asdf list erlang | grep -q "$ERLANG_VERSION"; then
    echo -e "${GREEN}Erlang ${ERLANG_VERSION} is already installed${NC}"
else
    # Set environment variables for Erlang compilation
    export KERL_CONFIGURE_OPTIONS="--without-javac --with-ssl=$(brew --prefix openssl@3)"
    export KERL_BUILD_DOCS=yes

    asdf install erlang "$ERLANG_VERSION"
    echo -e "${GREEN}Erlang ${ERLANG_VERSION} installed successfully${NC}"
fi

# Install Elixir
echo ""
echo -e "${YELLOW}Installing Elixir ${ELIXIR_VERSION}...${NC}"

if asdf list elixir | grep -q "$ELIXIR_VERSION"; then
    echo -e "${GREEN}Elixir ${ELIXIR_VERSION} is already installed${NC}"
else
    asdf install elixir "$ELIXIR_VERSION"
    echo -e "${GREEN}Elixir ${ELIXIR_VERSION} installed successfully${NC}"
fi

# Set global versions
echo ""
echo -e "${YELLOW}Setting global versions...${NC}"
asdf global erlang "$ERLANG_VERSION"
asdf global elixir "$ELIXIR_VERSION"

# Verify installations
echo ""
CURRENT_ERLANG=$(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null || echo "not found")
CURRENT_ELIXIR=$(elixir --version | grep "Elixir" | awk '{print $2}' || echo "not found")

if [ "$CURRENT_ERLANG" = "not found" ] || [ "$CURRENT_ELIXIR" = "not found" ]; then
    echo -e "${YELLOW}Versions not detected. Reshimming asdf...${NC}"
    asdf reshim erlang
    asdf reshim elixir

    # Try again
    CURRENT_ERLANG=$(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null || echo "not found")
    CURRENT_ELIXIR=$(elixir --version | grep "Elixir" | awk '{print $2}' || echo "not found")
fi

echo -e "${GREEN}Active Erlang/OTP version: ${CURRENT_ERLANG}${NC}"
echo -e "${GREEN}Active Elixir version: ${CURRENT_ELIXIR}${NC}"

# Update Hex package manager
echo ""
echo -e "${YELLOW}Installing/updating Hex package manager...${NC}"
mix local.hex --force

# Install Rebar (Erlang build tool)
echo ""
echo -e "${YELLOW}Installing/updating Rebar3 build tool...${NC}"
mix local.rebar --force

# Install Phoenix
echo ""
echo -e "${YELLOW}Installing Phoenix framework...${NC}"
mix archive.install hex phx_new --force

# Verify Phoenix installation
PHOENIX_VERSION=$(mix phx.new --version 2>/dev/null | grep "Phoenix installer" | awk '{print $3}' || echo "not found")

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo -e "Erlang/OTP: ${GREEN}${CURRENT_ERLANG}${NC}"
echo -e "Elixir:     ${GREEN}${CURRENT_ELIXIR}${NC}"
echo -e "Hex:        ${GREEN}$(mix hex.info | grep "Hex:" | awk '{print $2}' || echo "installed")${NC}"
echo -e "Phoenix:    ${GREEN}${PHOENIX_VERSION}${NC}"
echo ""
echo -e "${YELLOW}To verify asdf is working correctly:${NC}"
echo -e "  which elixir   # Should show: $HOME/.asdf/shims/elixir"
echo -e "  which erl      # Should show: $HOME/.asdf/shims/erl"
echo -e "  elixir --version"
echo ""
echo -e "${YELLOW}To create a new Phoenix application:${NC}"
echo -e "  mix phx.new myapp"
echo -e "  cd myapp"
echo -e "  mix deps.get"
echo -e "  mix ecto.create"
echo -e "  mix phx.server"
echo ""
echo -e "${YELLOW}To create a Phoenix API-only application:${NC}"
echo -e "  mix phx.new myapp --no-html --no-assets"
echo ""
echo -e "${YELLOW}To get started with Ash Framework:${NC}"
echo -e "  # Add to mix.exs dependencies:"
echo -e '  {:ash, "~> 3.4"}'
echo -e '  {:ash_phoenix, "~> 2.0"}'
echo -e '  {:ash_postgres, "~> 2.0"}  # For PostgreSQL'
echo -e "  "
echo -e "  mix deps.get"
echo -e "  # Follow Ash documentation: https://ash-hq.org"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  mix deps.get         # Install dependencies"
echo -e "  mix compile          # Compile the project"
echo -e "  mix test             # Run tests"
echo -e "  iex -S mix           # Start interactive Elixir shell with project loaded"
echo -e "  mix format           # Format code"
echo -e "  mix credo            # Code analysis (install with: mix archive.install hex credo)"
echo ""
echo -e "${GREEN}Setup complete! Happy coding!${NC}"
