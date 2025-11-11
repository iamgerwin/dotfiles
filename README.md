# Dotfiles - Personal Development Environment Configuration

A modular, maintainable approach to managing shell configurations and development environment across multiple macOS machines.

## Overview

This repository contains my personal dotfiles configuration, designed with modularity and maintainability in mind. The configuration is split into logical components, making it easy to understand, modify, and sync across different workstations.

## Features

- **Adaptive Setup**: Intelligently learns from and preserves existing user customizations
- **Zero Disruption**: Integrates with your current workflow without breaking anything
- **Modular Configuration**: Shell settings are organized into separate files by functionality
- **Cross-Machine Sync**: Easy synchronization between personal and work computers
- **Automated Setup**: One-command installation for new machines
- **Package Management**: Centralized Homebrew package management via Brewfile
- **Version Control**: All configurations tracked in Git for easy rollback and history
- **Oh My Zsh Integration**: Pre-configured with useful plugins and Powerlevel10k theme
- **Neovim Configuration**: Modern IDE-like setup with LSP, Treesitter, and productivity plugins
- **Development Tools**: NVM, Pyenv, rbenv, asdf, Herd PHP, and other development environment managers
- **Elixir & Phoenix Setup**: Automated Elixir/Erlang version management with asdf for Phoenix and Ash development
- **Ruby & Rails Setup**: Automated Ruby version management with rbenv and Rails installation
- **Laravel/PHP Ready**: Aliases and tools for Laravel development workflow
- **Custom Preservation**: Automatically detects and preserves your existing aliases, functions, and tools
- **Git Profile Management**: Manage multiple Git identities (personal, work) with SSH keys and GitHub CLI integration
- **SSH Key Organization**: Centralized SSH key management with migration and backup capabilities
- **AI Prompts Management**: Organized system for managing AI prompts and context scripts by company/project
- **AI Agent CLI Tools**: Support for Gemini, Claude, and Codex CLI tools with co-existence strategy
- **Best Practices Documentation**: Comprehensive guides for modern development technologies and frameworks

## Structure

```
dotfiles/
├── .zshrc              # Main configuration file that sources all modules
├── aliases.zsh         # Command shortcuts and aliases (git, Laravel, Docker)
├── exports.zsh         # Environment variables and PATH configuration
├── functions.zsh       # Custom shell functions and utilities
├── options.zsh         # Zsh shell options and settings
├── plugins.zsh         # Plugin configurations (Oh My Zsh, NVM, Pyenv)
├── keybindings.zsh     # Custom keyboard shortcuts
├── prompt.zsh          # Shell prompt appearance and behavior
├── custom.zsh          # Machine-specific configurations
├── p10k.zsh            # Powerlevel10k prompt configuration
├── tmux.conf           # Tmux configuration with best practices
├── nvim/               # Neovim configuration with LSP and plugins
├── elixir/             # Elixir, Phoenix, and Ash setup configuration
│   ├── .tool-versions  # Default Erlang/Elixir versions (27.2/1.18.1)
│   ├── setup.sh        # Automated Elixir/Phoenix/Ash installation script
│   └── README.md       # Elixir setup documentation
├── ruby/               # Ruby and Rails setup configuration
│   ├── .ruby-version   # Default Ruby version (3.3.6)
│   ├── .gemrc          # Gem configuration (skip docs, concurrent downloads)
│   ├── setup.sh        # Automated Ruby/Rails installation script
│   └── README.md       # Ruby setup documentation
├── python/             # Python, FastAPI, and Django setup configuration
│   ├── .python-version # Default Python version (3.12.8)
│   ├── setup.sh        # Automated Python/FastAPI/Django installation script
│   └── README.md       # Python setup documentation
├── Brewfile            # Homebrew package definitions
├── AGENTS.md           # AI Agent CLI tools best practices
├── CLAUDE.md -> AGENTS.md    # Symlink to AGENTS.md
├── CODEX.md -> AGENTS.md     # Symlink to AGENTS.md
├── GEMINI.md -> AGENTS.md    # Symlink to AGENTS.md
├── AI_PROMPTS.md       # AI prompts management documentation
├── TEMPLATES.md        # Quick reference for all prompt templates
├── GIT_PROFILE_MANAGEMENT.md # Git profiles and SSH keys documentation
├── setup.sh            # Automated setup script
├── config/             # Configuration files
│   └── git-profiles/   # Git profile configurations (gitignored)
├── ssh-keys/           # Organized SSH keys directory (gitignored)
├── docs/               # Documentation directory
│   └── best-practices/ # Comprehensive technology guides
│       ├── ai-tools/   # AI-powered development tools
│       ├── databases/  # Database technologies
│       ├── mobile-frameworks/ # Mobile development platforms
│       ├── progressive-web-apps/ # PWA and service workers
│       ├── pwa-tooling/ # PWA development tools
│       ├── frontend/   # Frontend frameworks and libraries
│       ├── backend/    # Backend frameworks and APIs
│       ├── mobile/     # Mobile development platforms
│       ├── database/   # Database technologies
│       ├── devops/     # DevOps and cloud platforms
│       ├── backend-services/ # Backend-as-a-Service platforms
│       ├── cms/        # Content Management Systems
│       ├── enterprise/ # Enterprise software platforms
│       ├── automation/ # Workflow automation platforms
│       ├── build-tools/ # Build systems and monorepo tools
│       ├── security/   # Security frameworks and compliance
│       ├── testing/    # Testing frameworks and tools
│       ├── languages/  # Programming languages
│       ├── editors/    # Code editors and IDEs
│       ├── stacks/     # Technology stacks (LAMP, MERN, etc.)
│       ├── system-architecture/ # API design and architecture
│       ├── machine-learning/    # AI/ML best practices
│       ├── version-control/ # Git workflows and best practices
│       └── programming-principles/ # Core programming principles and patterns
├── ai-prompts/         # AI prompts management system
└── scripts/
    ├── install-brew.sh # Homebrew installation script
    ├── setup-tmux.sh   # Tmux setup and configuration script
    ├── setup-neovim.sh # Neovim setup with backup and migration
    ├── backup.sh       # Backup management script
    ├── uninstall.sh    # Uninstall and rollback script
    ├── ai-prompt       # AI prompts CLI tool
    ├── ai-prompts-init.sh # AI prompts initialization
    ├── prompt-copy     # Quick template copy to clipboard
    ├── ssh-connect     # SSH connection helper with saved profiles
    ├── git-profile-switch  # Quick git profile switching
    ├── git-profile-manager # Full git profile CRUD operations
    ├── ssh-key-manager     # SSH key organization and migration
    ├── import-git-profiles # Import existing Git config and SSH keys
    └── clickup/        # ClickUp API integration scripts
        ├── clickup-api.sh      # Main ClickUp API wrapper
        ├── clickup-download.sh # File download utility
        └── .env.example        # Configuration template
```

## Quick Start

### 🎯 Adaptive Setup for Existing Configurations

If you already have a working .zshrc and custom setup, use our **Adaptive Setup** that preserves everything:

```bash
# Clone the repository
git clone https://github.com/iamgerwin/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run adaptive setup - learns from your existing configuration
./scripts/adaptive-setup.sh
```

This will:
- ✅ Detect and preserve all your custom aliases and functions
- ✅ Capture your installed packages (Homebrew, npm, VS Code extensions)
- ✅ Keep sensitive data separate and secure
- ✅ Create restoration scripts for your complete environment
- ✅ Integrate dotfiles without disrupting your workflow

#### Alternative: Standard Setup with Migration

```bash
# Run the main setup - it will offer adaptive mode
./setup.sh
# Choose option 1: "Adaptive setup - Preserve all customizations"
```

### 🆕 For New Mac or Fresh Installation

Run this single command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/iamgerwin/dotfiles/main/setup.sh)"
```

This will:
1. Install Homebrew (if not present)
2. Clone this repository
3. Create backups of any existing configurations
4. Install all packages from Brewfile
5. Set up symbolic links
6. Configure your shell environment
7. Prompt you to configure Powerlevel10k theme

### 🔒 Safety Features

Every installation automatically:
- **Creates timestamped backups** before making any changes
- **Stores backups** in `~/.dotfiles-backup/` with a JSON manifest
- **Preserves all original files** with timestamps
- **Provides instant rollback** capability via `uninstall.sh`
- **Never overwrites** without backing up first

### 📖 Important: Terminal Font & Theme Setup

**Powerlevel10k requires a Nerd Font** to display icons correctly. Without it, you'll see question marks in your prompt.

**After installation, complete these final steps:**

1. **Install the required fonts** (included in setup):
   ```bash
   brew install --cask font-meslo-lg-nerd-font font-meslo-for-powerlevel10k
   ```

2. **Configure your terminal font** automatically or manually:
   ```bash
   # Automatic configuration (recommended)
   ~/dotfiles/scripts/configure-terminal-fonts.sh
   
   # Or manually set your terminal font to: MesloLGS NF Regular
   ```
   See [TERMINAL_SETUP.md](TERMINAL_SETUP.md) for detailed manual instructions.

3. **Configure your prompt theme**:
   ```bash
   p10k configure
   ```
   This interactive wizard will help you customize your prompt appearance with icons, colors, and layout options.

4. **Restart your terminal** to see the final result.

### 📖 Detailed Installation Guide

For step-by-step instructions and troubleshooting, see [INSTALLATION.md](INSTALLATION.md)

## Homebrew Cask Remediation

The update script includes comprehensive handling for problematic Homebrew casks:

### Automatic Error Detection

- Detects cask upgrade failures that Homebrew doesn't report (exit code 0 despite errors)
- Identifies common failure patterns:
  - Missing app sources (`It seems the App source is not there`)
  - Uninstaller script issues
  - Installation conflicts
- Reports failed casks with helpful guidance

### Cask Ignore List

Skip problematic casks to prevent wasted time on repeated failures:

```bash
# Casks in .dotfiles-cask-ignore are automatically excluded from upgrades
cat .dotfiles-cask-ignore
```

**Format** (inline comments supported):
```
skype
alt-tab          # App source missing error
arc              # App source missing error
logitech-options # Requires password prompt then fails
```

**When to add casks:**
- Persistent upgrade failures (missing app sources, uninstaller issues)
- Interactive prompts that block automation (password requests)
- Apps you prefer to manage manually

**Add failed casks to ignore list:**
```bash
# The script will suggest casks to add after detecting failures
echo "cask-name  # reason" >> .dotfiles-cask-ignore
```

### Remediation Options

- **Default**: Automatic remediation for known problematic casks
- **Skip remediation**: `scripts/update-all.sh --cask-no-remediation`
- **Pre-emptive exclusion**: Casks in `.dotfiles-cask-ignore` are filtered before upgrade attempts

This reduces noise from vendor issues and prevents blocking operations.

## Configuration Files

### Core Modules

- **aliases.zsh**: Command shortcuts including:
  - Git workflow aliases (gc, gpod, gdog, gclean, gdp)
  - Laravel/PHP development (art, sail, pint, pbc)
  - Docker shortcuts (dps, dpsa, di, dex)
  - System utilities (brewu, reload, dotfiles)
- **exports.zsh**: PATH and environment variables for:
  - Herd PHP configuration (multiple PHP versions)
  - NVM (Node Version Manager)
  - Pyenv (Python Version Manager)
  - Windsurf, Homebrew, and other tools
- **functions.zsh**: Reusable shell functions for productivity
- **options.zsh**: Zsh behavior settings (history, completion, etc.)
- **plugins.zsh**: Configurations for:
  - Oh My Zsh with Powerlevel10k theme
  - Development plugins (git, docker, laravel, composer)
  - Auto-suggestions and syntax highlighting
  - NVM and Pyenv initialization
- **keybindings.zsh**: Terminal keyboard shortcuts
- **prompt.zsh**: Additional prompt customization
- **custom.zsh**: Local overrides and machine-specific settings
- **p10k.zsh**: Powerlevel10k prompt configuration
- **tmux.conf**: Professional tmux configuration with:
  - Vim-style keybindings and smart pane navigation
  - Enhanced status bar with system information
  - macOS clipboard integration
  - Session persistence with tmux-resurrect
  - Optimized performance settings
  - Custom development layouts and scripts

### Terminal Setup Tools

The dotfiles now include comprehensive terminal setup tools for an enhanced development environment:

#### Terminal Emulators
- **Ghostty**: Fast, feature-rich terminal emulator with GPU acceleration
- **Warp**: Modern, Rust-based terminal with AI features (already included)
- **WezTerm**: GPU-accelerated cross-platform terminal emulator
- **iTerm2**: Traditional favorite terminal for macOS (already included)

#### Modern Shells
- **Fish**: User-friendly command line shell with auto-suggestions
- **Nushell**: Modern shell written in Rust with structured data pipelines
- **Zsh**: UNIX shell with Oh My Zsh framework (already included)

#### Terminal Multiplexers
- **Tmux**: Terminal multiplexer for managing multiple sessions
- **Zellij**: Modern terminal workspace with built-in layouts and plugins

#### Shell Enhancements
- **Starship**: Cross-shell prompt customization with minimal, blazing-fast design
- **Carapace**: Multi-shell completion framework for consistent auto-completions
- **Atuin**: Magical shell history that syncs across machines
- **Zoxide**: Smarter cd command that learns your habits
- **FZF**: Command-line fuzzy finder for quick navigation

#### Modern CLI Tools
- **Exa/Eza**: Modern replacement for `ls` with colors and icons
- **Bat**: Cat clone with syntax highlighting
- **Ripgrep**: Ultra-fast recursive search
- **Fd**: Simple, fast alternative to `find`
- **Dust**: More intuitive version of `du` written in Rust

#### Fonts
The setup includes JetBrains Mono and other Nerd Fonts for proper icon display in terminals.

### Package Management

The `Brewfile` contains all Homebrew packages, casks, and fonts. To manage packages:

```bash
# Install all packages
brew bundle install

# Update all packages
brew bundle update

# Check what would be cleaned up
brew bundle cleanup --dry-run

# Remove packages not in Brewfile
brew bundle cleanup
```

## Syncing Between Machines

### Pull Latest Changes

```bash
cd ~/dotfiles
git pull
brew bundle install  # Install any new packages
source ~/.zshrc      # Reload configuration
```

### Push Local Changes

```bash
cd ~/dotfiles
git add .
git commit -m "Update configurations"
git push
```

### Update All Packages

```bash
# Update Homebrew and all packages
brew update && brew upgrade && brew cleanup

# Update package list in Brewfile
brew bundle dump --force --file=~/dotfiles/Brewfile

# Update all system packages including AI tools (recommended)
~/dotfiles/scripts/update-all.sh

# Update with verbose output
~/dotfiles/scripts/update-all.sh --verbose

# Update only specific package managers
~/dotfiles/scripts/update-all.sh --brew-only
~/dotfiles/scripts/update-all.sh --npm-only
~/dotfiles/scripts/update-all.sh --pip-only
~/dotfiles/scripts/update-all.sh --ai-tools-only
```

### Updating AI/LLM CLI Tools

The dotfiles include automated updates for AI CLI tools like `gemini-cli`, `codex`, and `claude-code`:

```bash
# Update AI tools as part of full system update
~/dotfiles/scripts/update-all.sh

# Update only LLM CLI tools (recommended)
~/dotfiles/scripts/update-all.sh --ai-tools-only

# Update only AI tools (alternative method)
source ~/dotfiles/scripts/update-all.sh && update_ai_tools

# Skip AI tools during system update
UPDATE_AI_TOOLS=false ~/dotfiles/scripts/update-all.sh

# Manual update of individual tools
brew upgrade gemini-cli codex          # Formula-based tools
brew upgrade --cask claude-code        # Cask-based tools
```

**Features:**
- Automatic detection of installed AI tools
- Smart update handling with timeout protection
- Helpful installation messages for missing tools
- Integrated with package manager isolation flags
- Non-blocking: failures on one tool don't prevent updates to others

## Customization

### Machine-Specific Settings

Create a `.zshrc.local` file in your home directory for machine-specific configurations that shouldn't be shared:

```bash
echo "export WORK_SPECIFIC_VAR=value" >> ~/.zshrc.local
```

### Private/Sensitive Data

Store sensitive information in `~/.zshrc.private` (not tracked by Git):

```bash
echo "export SECRET_API_KEY=xxx" >> ~/.zshrc.private
```

### Git Profile Management

Manage multiple Git identities (personal, work, client) with integrated SSH key management:

#### Import Existing Configuration

If you have existing Git configuration and SSH keys, import them automatically:

```bash
# Interactive import wizard
~/dotfiles/scripts/import-git-profiles

# Quick import (non-interactive)
~/dotfiles/scripts/import-git-profiles --quick
```

The import tool will:
- Detect your current Git configuration
- Find all SSH keys in ~/.ssh
- Create profiles based on key names (personal, work, github, etc.)
- Migrate SSH keys to organized structure
- Preserve all existing settings

#### Profile Management Commands

```bash
# Create a new profile
gpm create              # Interactive profile creation
gpm-new                 # Alias for quick access

# List all profiles
gpm list                # Show all profiles with details
gpm-list                # Quick alias

# Switch profiles
gp personal             # Switch to personal profile
gp work                 # Switch to work profile

# Check current profile
gpm current             # Show active profile
gpm-current             # Quick alias

# Manage profiles
gpm update personal     # Edit existing profile
gpm delete old-profile  # Remove a profile
gpm clone work client   # Copy profile as template
```

### SSH Key Management

Organized SSH key management with migration capabilities:

```bash
# Generate new SSH key
sshkm-gen               # Interactive key generation

# Migrate existing keys from ~/.ssh to organized structure
sshkm-migrate           # Auto-detect and migrate keys

# List all SSH keys
sshkm-list              # Show keys with status

# Test SSH connection
sshkm-test github-personal

# Manual migration
~/dotfiles/scripts/ssh-key-manager generate    # Create new key
~/dotfiles/scripts/ssh-key-manager link        # Create symlinks
```

SSH keys are stored in `~/dotfiles/ssh-keys/` (gitignored) with symlinks to `~/.ssh/` for compatibility.
See [GIT_PROFILE_MANAGEMENT.md](GIT_PROFILE_MANAGEMENT.md) for complete documentation.

### GitHub CLI Authentication

Quick aliases for managing GitHub CLI authentication and account switching:

```bash
# Check authentication status
ghs                     # gh auth status

# Login to GitHub
ghl                     # gh auth login

# Logout from GitHub
ghlo                    # gh auth logout

# Switch between GitHub accounts
ghsw                    # gh auth switch

# Refresh authentication
ghr                     # gh auth refresh

# Get authentication token
ght                     # gh auth token
```

These aliases work seamlessly with the Git Profile Management system for managing multiple GitHub accounts.

### Elixir, Phoenix, and Ash Development

Automated Elixir and Phoenix setup with asdf for version management, targeting Phoenix and Ash framework development:

```bash
# Run automated setup (installs Erlang 27.2 and Elixir 1.18.1)
~/dotfiles/elixir/setup.sh

# Verify installation
elixir --version            # Check Elixir and Erlang versions
mix --version               # Check Mix build tool
which elixir                # Should show: ~/.asdf/shims/elixir

# Verify Phoenix installation
mix phx.new --version       # Check Phoenix version

# Manage Elixir/Erlang versions
asdf list all erlang        # List available Erlang versions
asdf list all elixir        # List available Elixir versions
asdf install erlang 27.2    # Install specific Erlang version
asdf install elixir 1.18.1-otp-27  # Install specific Elixir version
asdf global erlang 27.2     # Set global Erlang version
asdf global elixir 1.18.1-otp-27   # Set global Elixir version

# Create new Phoenix app
mix phx.new myapp
cd myapp
mix deps.get
mix ecto.create
mix phx.server

# Create Phoenix API
mix phx.new myapi --no-html --no-assets

# Project-specific versions
echo "erlang 27.2" > .tool-versions
echo "elixir 1.18.1-otp-27" >> .tool-versions
cd .  # Activate versions
```

**Features:**
- asdf for multi-language version management
- Erlang/OTP 27.2 with optimized compilation
- Elixir 1.18.1 with OTP 27 compatibility
- Phoenix framework for web applications
- Hex package manager and Rebar3 build tool
- Ready for Phoenix and Ash framework development
- Automatic dependency installation (wxwidgets, openssl, etc.)

**Frameworks Supported:**
- **Phoenix**: Web framework for building APIs and full-stack applications
- **Ash**: Declarative, resource-based framework for robust APIs
- **LiveView**: Real-time server-rendered apps (included in Phoenix)
- **Ecto**: Database wrapper and query DSL

See [elixir/README.md](elixir/README.md) for complete documentation, Phoenix setup, Ash framework guide, and troubleshooting.

### Ruby & Rails Development

Automated Ruby and Rails setup with rbenv for version management:

```bash
# Run automated setup (installs Ruby 3.3.6 and latest Rails)
~/dotfiles/ruby/setup.sh

# Verify installation
ruby -v                 # Check Ruby version
rails -v                # Check Rails version
which ruby              # Should show: ~/.rbenv/shims/ruby

# Manage Ruby versions
rbenv install --list    # List available versions
rbenv install 3.2.0     # Install specific version
rbenv versions          # List installed versions
rbenv global 3.3.6      # Set global version
rbenv local 3.2.0       # Set project-specific version

# Create new Rails app
rails new myapp
cd myapp
bundle install
rails server

# Project-specific Ruby version
echo "3.3.6" > .ruby-version
cd .  # Activate version
```

**Features:**
- rbenv for lightweight Ruby version management
- Automatic dependency installation (OpenSSL, readline, libyaml)
- Optimized gem configuration (skip docs, concurrent downloads)
- Latest Ruby LTS (3.3.6) and Rails (7.2.x)
- Node.js and Yarn for Rails asset pipeline

See [ruby/README.md](ruby/README.md) for complete documentation and troubleshooting.

### Python, FastAPI, and Django Development

Automated Python development setup with pyenv for version management, including FastAPI and Django frameworks:

```bash
# Run automated setup (installs Python 3.12.8, FastAPI, and Django)
~/dotfiles/python/setup.sh

# Verify installation
python --version            # Check Python version
pip --version               # Check pip version
which python                # Should show: ~/.pyenv/shims/python

# Verify frameworks
python -c "import fastapi; print(fastapi.__version__)"
python -c "import django; print(django.get_version())"

# Manage Python versions
pyenv install --list        # List available versions
pyenv install 3.11.0        # Install specific version
pyenv versions              # List installed versions
pyenv global 3.12.8         # Set global version
pyenv local 3.11.0          # Set project-specific version

# Create FastAPI project
mkdir myapi && cd myapi
python -m venv venv
source venv/bin/activate
pip install fastapi uvicorn[standard]
uvicorn main:app --reload

# Create Django project
django-admin startproject myproject
cd myproject
python manage.py migrate
python manage.py runserver

# Project-specific Python version
echo "3.12.8" > .python-version
cd .  # Activate version
```

**Features:**
- pyenv for lightweight Python version management
- Python 3.12.8 (latest stable LTS)
- FastAPI with uvicorn for modern async APIs
- Django with REST framework and common dependencies
- Development tools: black, flake8, mypy, poetry
- System Python 3.12 as fallback (installed via Homebrew)
- Virtual environment support (venv and Poetry)

**Installed Packages:**
- **FastAPI**: Modern async web framework
- **Django**: Full-featured web framework
- **uvicorn**: ASGI server for FastAPI
- **djangorestframework**: API toolkit for Django
- **Poetry**: Modern dependency management
- **Testing**: pytest, pytest-asyncio, httpx
- **Code Quality**: black, flake8, mypy, pylint

See [python/README.md](python/README.md) for complete documentation and troubleshooting.

### .NET Development

Automated .NET development setup, including the .NET SDK and development certificates.

```bash
# Run automated setup (installs .NET SDK)
~/dotfiles/scripts/dotnet/install.sh

# Verify installation
dotnet --version            # Check .NET version

# Install development certificates (optional)
~/dotfiles/scripts/dotnet/dev-certs.sh
```

**Features:**
- Installs the latest .NET SDK (currently 8.0).
- Configures the shell environment for .NET development.
- Optional script to install and trust development certificates for HTTPS.

**Note:** For local development environments previously using MAMP or XAMPP, consider using Laravel Herd for PHP development or Docker containers for full-stack applications.

### AI Prompts Management

Manage AI prompts and context scripts organized by company/project:

```bash
# Initialize AI prompts system
~/dotfiles/scripts/ai-prompts-init.sh

# List available prompts
ai-prompt list

# Search for prompts
ai-prompt search "laravel"

# Copy prompt to clipboard
ai-prompt copy development/code-review
```

See [AI_PROMPTS.md](AI_PROMPTS.md) for complete documentation.

### SSH Connection Management

Simplified SSH connection management with saved profiles:

```bash
# Interactive connection with saved profiles
sshc                    # Launch interactive SSH helper

# Quick commands
sshl                    # List saved connections
sshq                    # Quick connect without saving
sshc -c myserver        # Connect to saved profile

# Managing connections
sshc -d myserver        # Delete saved connection

# Features
- Save frequently used connections with custom names
- Automatic SSH key detection from ~/.ssh directory
- Support for both password and key-based authentication
- Interactive mode with user-friendly prompts
- Port customization (default: 22)
```

The SSH helper stores connections in `~/.ssh_connections` for quick access.

### ClickUp Integration

Comprehensive ClickUp API integration for task management automation:

```bash
# Configuration
cp ~/dotfiles/scripts/clickup/.env.example ~/dotfiles/scripts/clickup/.env
# Edit .env with your CLICKUP_API_KEY

# Task Management
clickup-api get-task TASK_ID                    # Get task details
clickup-api create-task LIST_ID "Name" "Desc"   # Create new task
clickup-api update-status TASK_ID "in progress" # Update task status
clickup-api batch-update-status "done" ID1 ID2  # Bulk status update

# Comments & Attachments
clickup-api get-comments TASK_ID                # Get all comments
clickup-api add-comment TASK_ID "comment"       # Add comment
clickup-api auto-download-images TASK_ID        # Download all images

# Advanced Features
clickup-api search-tasks TEAM_ID "query"        # Search tasks
clickup-api fetch-tasks LIST_ID                 # List all tasks

# File Downloads
clickup-download URL FILENAME                   # Download with retry logic
clickup-download -c URL FILENAME                # Resume partial download
```

Features:
- Secure API key management via environment variables
- Batch operations for efficient task management
- Automatic retry logic with configurable timeouts
- Progress indicators for file downloads
- Color-coded output for better readability

See `scripts/clickup/README.md` for complete documentation.

### Tmux Configuration

The dotfiles include a comprehensive tmux setup with productivity-focused features:

```bash
# Setup tmux (automatically done during installation)
~/dotfiles/scripts/setup-tmux.sh

# Quick commands
tl              # List all sessions
ts myproject    # Create new session named 'myproject'
ta myproject    # Attach to session
tdev            # Launch development session with predefined layout
tproject name ~/path  # Create project-specific session

# Key bindings (after pressing Ctrl-a)
|     # Split pane horizontally
-     # Split pane vertically
h/j/k/l  # Navigate panes (vim-style)
H/J/K/L  # Resize panes
z     # Toggle pane zoom
r     # Reload configuration
```

The configuration includes:
- **TPM (Tmux Plugin Manager)** for plugin management
- **tmux-resurrect** for session persistence across restarts
- **tmux-continuum** for automatic session saves
- **vim-tmux-navigator** for seamless vim/tmux navigation
- **tmux-sensible** for sensible default settings
- **tmux-yank** for enhanced copy functionality
- **tmux-copycat** for regex search in scrollback
- **tmux-open** for opening highlighted files/URLs
- **tmux-pain-control** for better pane control
- **aw-watcher-tmux** for activity tracking integration
- **muxile** for mobile-friendly tmux control
- **tmux-autoreload** for automatic config reloading
- **tmux-browser** for browser integration
- **tmux-cargo** for Rust cargo integration
- **tmux-cowboy** for killing unresponsive processes
- **tmux-fpp** for file path picker integration
- **tmux-fzf-url** for fuzzy URL selection
- **tmux-fzf** for fuzzy finding in tmux
- **tmux-git-autofetch** for automatic git fetching
- **tmux-logging** for logging and screen capture
- **tmux-menus** for popup menus
- **tmux-mighty-scroll** for improved scrolling
- **tmux-neolazygit** for lazygit integration
- **tmux-nerd-font-window-name** for icon window names
- **tmux-notify** for desktop notifications
- **tmux-powerline** for powerline status bar
- **Custom scripts** for development workflows

### Best Practices Documentation

Access comprehensive development guides for modern technologies:

```bash
# Browse documentation
open ~/dotfiles/docs/best-practices/

# Quick reference by category:
ls ~/dotfiles/docs/best-practices/frontend/    # React, Vue, Angular, etc.
ls ~/dotfiles/docs/best-practices/backend/     # Laravel, Django, NestJS, etc.
ls ~/dotfiles/docs/best-practices/mobile/      # Flutter, React Native, etc.
ls ~/dotfiles/docs/best-practices/devops/      # AWS, Docker, Cloudflare, etc.
```

#### Available Technologies

**AI-Powered Development**
- Codex CLI (OpenAI): AI-powered code generation with secure API integration

**Progressive Web Applications**
- Service Workers & Caching: Offline functionality and performance optimization
- React with Workbox: Building PWAs with intelligent caching strategies

**Databases**
- DuckDB 1.4.0: Embedded analytical SQL database for OLAP workloads

**Mobile Frameworks**
- Ionic with Capacitor: Cross-platform mobile development using web technologies

**Frontend & UI**
- React ecosystem (Next.js, Jotai), Vue.js (Nuxt.js v4), Vaadin
- State Management: Redux Toolkit, Zustand, MobX, Context API
- Svelte & SvelteKit with Runes reactivity system
- Modern Reactive Frameworks: Solid.js (fine-grained reactivity), Alpine.js (lightweight interactivity)
- Authentication: Clerk, Better Auth
- UI libraries: shadcn/ui, Bootstrap, Tailwind CSS
- Animation: GSAP
- Data management: TanStack (Query, Router, Start, DB)
- Legacy: jQuery

**Full-Stack Frameworks**
- Laravel Livewire: Full-stack framework for building dynamic UIs with PHP
- Inertia.js: Build server-driven SPAs without APIs

**Backend & APIs**
- PHP: Laravel, Laravel Nova, Laravel Eloquent ORM, Laravel Filament v4, Symfony with API Platform, CodeIgniter 4
  - Performance Technologies: Laravel Octane, FrankenPHP, PHP-FPM, Open Swoole, RoadRunner
- JavaScript/TypeScript: NestJS, Hono.js, Meteor.js, AdonisJS (Laravel-inspired MVC), SailsJS (Rails-like MVC), FeathersJS (real-time micro-services)
- Python: Django, general Python best practices
- Ruby: Ruby on Rails
- Elixir: Ash framework
- .NET: ASP.NET Core with C#, Entity Framework Core
- Java: Modern Java features, Spring Boot integration

**Mobile Development**
- Cross-platform: Flutter, React Native, .NET MAUI
- Native: Swift (iOS), Kotlin (Android)

**Database & Storage**
- ORM: Prisma, Entity Framework Core
- Relational: PostgreSQL, Neon (serverless PostgreSQL)
- NoSQL: MongoDB, Firestore, CouchDB, DynamoDB (AWS managed NoSQL)
- Key-Value: Redis (caching, sessions, pub/sub), Valkey (open-source Redis fork)
- Analytics: DuckDB (OLAP, data analysis)
- Edge Database: Turso (libSQL/SQLite)
- Low-Code Database: Airtable

**Backend-as-a-Service (BaaS)**
- Real-time platforms: Convex (real-time backend with reactive queries)
- Open-source Firebase alternatives: Appwrite, Supabase, PocketBase

**Automation & Workflow**
- Workflow automation: N8N (fair-code workflow automation platform)

**Build Tools & Monorepo Management**
- High-performance build systems: Turborepo (JavaScript/TypeScript monorepos)
- Extensible build system: Nx (enterprise-grade monorepo tools with computation caching)

**DevOps & Cloud**
- Load Balancers & Proxies: Traefik, NGINX
- Containerization: Docker, Kubernetes
- CI/CD: Jenkins, CircleCI, GitHub Actions, GitLab CI
- Infrastructure as Code: Terraform, AWS CloudFormation, Ansible
- Cloud platforms: AWS, Azure, Google Cloud Platform, DigitalOcean
- Edge computing: Cloudflare (Workers, Pages, D1, R2)
- Static Hosting: GitHub Pages, Netlify, Vercel

**Content Management**
- Headless CMS: Strapi (customizable API-first CMS)
- WordPress: Core development, plugin development, theme development
- Drupal: Module and theme development
- SharePoint: SPFx development, REST API, PnP JS library

**Enterprise Systems**
- SAP: ABAP, SAPUI5/OpenUI5
- Integration: MuleSoft
- CRM: Salesforce Lightning, Zoho

**Security & Compliance**
- Frameworks: NIST, ISO 27001, SOC 2, HIPAA, GDPR
- Application security: OWASP Top 10, OWASP ASVS
- Payment security: PCI DSS

**Testing & Quality**
- E2E testing: Playwright, Cypress
- Performance testing: JMeter
- Code Quality: SonarQube

**System Architecture**
- API design: RESTful APIs, GraphQL, gRPC
- Documentation: OpenAPI/Swagger

**Languages**
- Systems programming: Rust, Go, Zig
- Web development: TypeScript (comprehensive type system guide), PHP (PSR standards, Swoole, Laravel Octane)
- Enterprise: Java (Java 8-17+ features, design patterns)

**AI & Machine Learning**
- RAG (Retrieval-Augmented Generation) best practices

**Version Control**
- Git workflows: Git worktrees for parallel development

**Programming Principles**
- SOLID Principles: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- CUPID Principles: Composable, Unix philosophy, Predictable, Idiomatic, Domain-based
- GRASP Patterns: Information Expert, Creator, Controller, Low Coupling, High Cohesion, Polymorphism, Pure Fabrication, Indirection, Protected Variations
- DRY Principle: Don't Repeat Yourself implementation strategies
- DDD: Domain-Driven Design patterns and practices
- Gang of Four Design Patterns: 23 classic object-oriented design patterns

**Project Management & Documentation**
- Diagramming: Mermaid, PlantUML, dbdiagram.io
- Architecture: C4 Model, UML diagrams, ERD tools
- Timing & Sequence: Sequence diagrams, timing diagrams, state machines
- Mind mapping and flowcharts for technical documentation

**Technology Stacks**
- Traditional: LAMP (Linux, Apache, MySQL, PHP)
- JavaScript: MERN (MongoDB, Express, React, Node.js), MEAN (Angular), MEVN (Vue)
- Modern: JAMstack (JavaScript, APIs, Markup), T3 Stack (TypeScript, Next.js, tRPC, Prisma)
- Full-Stack: PERN (PostgreSQL, Express, React, Node.js), Django Stack, Rails Stack
- Laravel: TALL Stack (Tailwind, Alpine.js, Laravel, Livewire), VILT (Vue, Inertia, Laravel, Tailwind)
- Enterprise: .NET Stack, Java Spring Stack

**Code Editors & IDEs**
- Claude Code: Anthropic's official CLI with comprehensive slash commands and AI-powered development
- Neovim: Modern vim with Lua configuration, LSP support, and extensive plugin ecosystem
- Terminal Tools: Tmux (multiplexer), Lazygit (git UI), and modern CLI replacements

**Monitoring & Observability**
- Metrics & Visualization: Prometheus, Grafana
- Log Management: ELK Stack (Elasticsearch, Logstash, Kibana)
- Application Performance Monitoring: Datadog, New Relic
- Error Tracking: Sentry, Rollbar
- Logging and Analytics: Complete monitoring stack implementation

**Security & Secrets Management**
- Secrets Management: HashiCorp Vault
- Certificate Management: Let's Encrypt, cert-manager

**Project Management & Collaboration**
- Agile Methodologies: Scrum Framework, Sprint Planning, Retrospectives
- Project Management Tools: JIRA, ClickUp, Azure DevOps
- Team Communication: Slack integrations and webhooks
- Documentation: Confluence, Notion
- ClickUp API Integration: Task automation and management scripts

**SEO & Web Optimization**
- Technical SEO: Site architecture, Core Web Vitals, structured data
- Content Optimization: Keyword research, content structure
- Tools & Analytics: Google Search Console, performance monitoring

Each guide includes practical examples, project structures, common pitfalls, performance optimization, and production-ready patterns.

## Maintenance

### Adding New Packages

1. Install the package:
   ```bash
   brew install <package>
   ```

2. Update Brewfile:
   ```bash
   brew bundle dump --force --file=~/dotfiles/Brewfile
   ```

3. Commit changes:
   ```bash
   cd ~/dotfiles
   git add Brewfile
   git commit -m "Add <package> to Brewfile"
   git push
   ```

### Removing Packages

1. Edit the `Brewfile` and remove the package line
2. Run cleanup:
   ```bash
   brew bundle cleanup
   ```

## Backup and Rollback

### Viewing Backups

List all available backups:
```bash
~/dotfiles/scripts/backup.sh list
```

### Manual Backup

Create a backup of current configuration:
```bash
~/dotfiles/scripts/backup.sh
```

### Uninstalling Dotfiles

Complete removal with automatic restoration of original files:
```bash
~/dotfiles/scripts/uninstall.sh
```

This will:
1. Restore your original configuration files from backup
2. Remove all symbolic links
3. Optionally remove the dotfiles repository
4. Optionally clean up backup files

### Quick Restore

Restore configuration without full uninstall:
```bash
~/dotfiles/scripts/uninstall.sh restore
```

## Troubleshooting

### Shell Not Loading Configuration

Ensure the symbolic link is correct:
```bash
ls -la ~/.zshrc
# Should point to ~/dotfiles/.zshrc
```

### Homebrew Issues

Re-run the Homebrew installation:
```bash
~/dotfiles/scripts/install-brew.sh
```

### Permission Issues

Fix permissions on the dotfiles directory:
```bash
chmod -R 755 ~/dotfiles
```

### Backup Recovery

If something goes wrong, backups are stored in:
```bash
~/.dotfiles-backup/
```

View backup manifest:
```bash
cat ~/.dotfiles-backup/manifest.json | jq
```

## Contributing

This is a personal configuration, but feel free to fork and adapt it for your own use. If you find any issues or have suggestions, please open an issue.

## License

MIT - Feel free to use any part of this configuration for your own dotfiles.

## Docker DB Import
See docs/docker-db-import.md for usage of the import script.
