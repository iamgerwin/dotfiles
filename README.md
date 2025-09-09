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
- **Development Tools**: NVM, Pyenv, Herd PHP, and other development environment managers
- **Laravel/PHP Ready**: Aliases and tools for Laravel development workflow
- **Custom Preservation**: Automatically detects and preserves your existing aliases, functions, and tools

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
├── Brewfile            # Homebrew package definitions
├── setup.sh            # Automated setup script
└── scripts/
    ├── install-brew.sh # Homebrew installation script
    ├── backup.sh       # Backup management script
    └── uninstall.sh    # Uninstall and rollback script
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

### 🔒 Safety Features

Every installation automatically:
- **Creates timestamped backups** before making any changes
- **Stores backups** in `~/.dotfiles-backup/` with a JSON manifest
- **Preserves all original files** with timestamps
- **Provides instant rollback** capability via `uninstall.sh`
- **Never overwrites** without backing up first

### 📖 Important: Terminal Font Setup

**Powerlevel10k requires a Nerd Font** to display icons correctly. Without it, you'll see question marks in your prompt.

Quick fix:
```bash
brew install --cask font-meslo-lg-nerd-font
```

Then set your terminal font to **MesloLGS NF**. See [TERMINAL_SETUP.md](TERMINAL_SETUP.md) for detailed instructions.

### 📖 Detailed Installation Guide

For step-by-step instructions and troubleshooting, see [INSTALLATION.md](INSTALLATION.md)

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
```

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