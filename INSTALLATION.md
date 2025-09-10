# Installation Guide

This guide will help you safely install these dotfiles on your Mac, whether you have an existing configuration or starting fresh.

## Before You Begin

**IMPORTANT**: This setup will modify your shell configuration. All existing files will be backed up automatically before any changes are made, ensuring you can always rollback to your original configuration.

## Installation Options

### Option 1: Automatic Installation (Recommended)

This method handles everything automatically, including backups:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/iamgerwin/dotfiles/main/setup.sh)"
```

### Option 2: Manual Installation with Review

If you want to review changes before applying them:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/iamgerwin/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Review your existing configuration**:
   ```bash
   # Check what will be backed up
   ls -la ~/.zshrc ~/.p10k.zsh ~/.gitconfig 2>/dev/null
   
   # Preview the new configuration
   cat ~/dotfiles/.zshrc
   ```

3. **Run the setup**:
   ```bash
   ./setup.sh
   ```

## For Users with Existing .zshrc

If you already have a working .zshrc file, you have several options:

### Preserve and Merge (Recommended)

1. **Backup your current configuration**:
   ```bash
   cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d)
   ```

2. **Extract your custom settings**:
   ```bash
   # Create a local overrides file
   touch ~/.zshrc.local
   
   # Copy any custom exports, aliases, or functions you want to keep
   # Edit this file with your specific customizations
   vim ~/.zshrc.local
   ```

3. **Install the dotfiles**:
   ```bash
   ~/dotfiles/setup.sh
   ```

Your custom settings in `~/.zshrc.local` will be automatically loaded.

### Full Replacement with Backup

Let the setup script handle everything:

```bash
# This will automatically backup your existing .zshrc
~/dotfiles/setup.sh
```

Your original .zshrc will be saved as `~/.zshrc.backup.[timestamp]`

## What Gets Installed

### Files Created/Modified
- `~/.zshrc` - Main configuration (symlink to ~/dotfiles/.zshrc)
- `~/.p10k.zsh` - Powerlevel10k theme config (symlink)
- `~/.tmux.conf` - Tmux configuration (symlink to ~/dotfiles/tmux.conf)
- `~/.gitconfig` - Git configuration (symlink, if exists)

### Backups Created
All existing files are backed up to:
- `~/.dotfiles-backup/[timestamp]/` - Complete backup with manifest
- `~/.dotfiles-backup/tmux-[timestamp]/` - Tmux-specific backups (when setting up tmux)
- Individual `.backup.[timestamp]` files

Each backup includes:
- Original configuration files
- Timestamp and manifest for easy identification
- Restore instructions in the manifest

### Dependencies Installed
- Homebrew packages (from Brewfile)
- Oh My Zsh (optional, prompted during setup)
- Powerlevel10k theme
- Zsh plugins (autosuggestions, syntax highlighting)
- Tmux with Tmux Plugin Manager (TPM)
- Tmux plugins (resurrect, continuum, vim-navigator)

## Verification Steps

After installation, verify everything is working:

1. **Check symlinks**:
   ```bash
   ls -la ~/.zshrc
   # Should show: .zshrc -> /Users/[username]/dotfiles/.zshrc
   ```

2. **Test configuration**:
   ```bash
   source ~/.zshrc
   # Should load without errors
   ```

3. **Verify aliases**:
   ```bash
   alias | grep -E "art|gc|brewu"
   # Should show your custom aliases
   ```

4. **Check backups**:
   ```bash
   ~/dotfiles/scripts/backup.sh list
   # Should show your backup history
   ```

5. **Test tmux configuration**:
   ```bash
   # Start a new tmux session
   tmux new -s test
   
   # Verify zsh is the default shell
   echo $SHELL
   # Should show: /opt/homebrew/bin/zsh or /usr/local/bin/zsh
   
   # Test key bindings (Ctrl-a is the prefix)
   # Ctrl-a | - Split horizontally
   # Ctrl-a - - Split vertically
   # Ctrl-a r - Reload config
   
   # Exit tmux
   exit
   ```

6. **Configure terminal font**:
   ```bash
   # Install required font
   brew install --cask font-meslo-lg-nerd-font
   ```
   Then configure your terminal to use **MesloLGS NF** font. See [TERMINAL_SETUP.md](TERMINAL_SETUP.md) for detailed instructions.

## Rollback / Uninstall

The dotfiles system maintains comprehensive backups of all your original configurations, making it safe to experiment and easy to rollback if needed.

### View Available Backups
```bash
# List all backups
~/dotfiles/scripts/uninstall.sh list

# Check backup directory
ls -la ~/.dotfiles-backup/
```

### Quick Rollback
```bash
# Restore from the latest backup
~/dotfiles/scripts/uninstall.sh restore

# Restore from a specific backup
~/dotfiles/scripts/uninstall.sh restore [timestamp]
```

This restores your original configuration from the backup.

### Tmux-Specific Restore
```bash
# Restore only tmux configuration
~/dotfiles/scripts/uninstall.sh restore-tmux

# Restore from a specific tmux backup
~/dotfiles/scripts/uninstall.sh restore-tmux ~/.dotfiles-backup/tmux-[timestamp]
```

### Complete Uninstall
```bash
~/dotfiles/scripts/uninstall.sh
```

This will:
1. Restore all original configuration files from backup
2. Remove all symbolic links created by dotfiles
3. Optionally remove the dotfiles repository
4. Optionally clean up all backup files
5. Restore your system to its pre-installation state

### Manual Rollback
```bash
# Restore specific files manually
cp ~/.zshrc.backup.[timestamp] ~/.zshrc
cp ~/.tmux.conf.backup.[timestamp] ~/.tmux.conf

# Or restore from the backup directory
cp ~/.dotfiles-backup/[timestamp]/.zshrc ~/.zshrc
cp ~/.dotfiles-backup/tmux-[timestamp]/.tmux.conf.backup ~/.tmux.conf

# Reload your shell
source ~/.zshrc

# Restart tmux if needed
tmux kill-server
```

### Safety Features
- **Automatic Backups**: Every installation and update creates timestamped backups
- **Non-Destructive**: Original files are never deleted, only renamed or backed up
- **Manifest Tracking**: Each backup includes a manifest with restore instructions
- **Incremental Backups**: Each component (tmux, zsh, etc.) maintains separate backups
- **Complete Restoration**: One command restores your entire original setup

## Troubleshooting

### "Permission Denied" Errors
```bash
chmod +x ~/dotfiles/setup.sh
chmod +x ~/dotfiles/scripts/*.sh
```

### Symlink Issues
```bash
# Remove broken symlinks
rm ~/.zshrc
# Recreate
ln -sf ~/dotfiles/.zshrc ~/.zshrc
```

### Oh My Zsh Not Loading
```bash
# Verify Oh My Zsh is installed
ls -la ~/.oh-my-zsh

# Reinstall if needed
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Homebrew Packages Not Installing
```bash
# Install Homebrew first
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Then install packages
cd ~/dotfiles
brew bundle install
```

### Tmux Using Wrong Shell
```bash
# If tmux opens with fish or another shell instead of zsh
# Check current default shell
echo $SHELL

# Verify tmux.conf is linked
ls -la ~/.tmux.conf

# Reload tmux config (inside tmux)
# Press Ctrl-a, then r

# Or manually set shell in tmux
tmux set-option -g default-shell /opt/homebrew/bin/zsh

# Kill all tmux sessions and restart
tmux kill-server
tmux new -s main
```

### Tmux Plugins Not Installing
```bash
# Install TPM if missing
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Inside tmux, install plugins manually
# Press Ctrl-a (prefix), then Shift-i

# Or run the setup script again
~/dotfiles/scripts/setup-tmux.sh
```

## Customization After Installation

### Add Machine-Specific Settings
Edit `~/.zshrc.local`:
```bash
# Work-specific aliases
alias work="cd ~/Work/projects"

# Local environment variables
export WORK_ENV="development"
```

### Add Private/Sensitive Data
Edit `~/.zshrc.private`:
```bash
# API keys and tokens
export GITHUB_TOKEN="your-token-here"
export AWS_SECRET_KEY="your-key-here"
```

Both files are automatically sourced but never tracked in git.

## Keeping Your Dotfiles Updated

### Pull Latest Changes
```bash
cd ~/dotfiles
git pull
source ~/.zshrc
```

### Share Your Changes
```bash
cd ~/dotfiles
git add .
git commit -m "Update configurations"
git push
```

## Support

If you encounter issues:
1. Check the backup manifest: `cat ~/.dotfiles-backup/manifest.json`
2. Review the setup log (if any errors occurred during installation)
3. Use the uninstall script to safely revert changes