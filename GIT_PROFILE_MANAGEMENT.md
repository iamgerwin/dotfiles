# Git Profile Management System

A comprehensive solution for managing multiple Git profiles with different SSH keys, email addresses, and GitHub accounts.

## Overview

This system allows you to easily switch between different Git identities (personal, work, client projects, etc.) with proper SSH key management and GitHub CLI integration.

## Installation

1. Ensure the scripts are executable:
```bash
chmod +x ~/dotfiles/scripts/git-profile-switch
chmod +x ~/dotfiles/scripts/git-profile-manager
chmod +x ~/dotfiles/scripts/ssh-key-manager
```

2. Source your aliases:
```bash
source ~/.zshrc
```

## Directory Structure

```
dotfiles/
├── scripts/
│   ├── git-profile-switch     # Profile switching script
│   ├── git-profile-manager    # Profile management (CRUD operations)
│   └── ssh-key-manager        # SSH key management
├── config/
│   └── git-profiles/          # Profile configurations (gitignored)
│       ├── example.conf       # Template file (committed)
│       ├── personal.conf      # Your profiles (gitignored)
│       └── work.conf          # Your profiles (gitignored)
├── ssh-keys/                  # SSH keys directory (gitignored)
│   ├── README.md              # Documentation (committed)
│   ├── github-personal        # Private keys (gitignored)
│   ├── github-personal.pub    # Public keys (gitignored)
│   └── ...
└── aliases.zsh                # Shell aliases
```

## Quick Start

### 1. Create Your First Profile

```bash
gpm create
# Or use the full command:
~/dotfiles/scripts/git-profile-manager create
```

You'll be prompted for:
- Profile name (e.g., "personal", "work")
- Git user name
- Git email address
- SSH key name (from ~/.ssh/)
- GitHub account name (optional)
- GPG signing key (optional)

### 2. Switch to a Profile

```bash
gp personal
# Or:
gpm switch personal
```

This will configure:
- Git user.name and user.email
- SSH key for Git operations
- GPG signing (if configured)

### 3. Check Current Profile

```bash
gpm current
# Or:
gpm-current
```

## Available Commands

### Profile Management (gpm)

| Command | Alias | Description |
|---------|-------|-------------|
| `gpm create` | `gpm-new` | Create a new profile interactively |
| `gpm list` | `gpm-list` | List all profiles with details |
| `gpm current` | `gpm-current` | Show current active profile |
| `gpm update <name>` | `gpm-edit` | Update an existing profile |
| `gpm delete <name>` | `gpm-delete` | Delete a profile |
| `gpm show <name>` | - | Show profile configuration |
| `gpm clone <src> <dest>` | - | Clone a profile to create a new one |
| `gpm switch <name>` | `gp <name>` | Switch to a profile |

### Profile Switching (gp)

| Command | Description |
|---------|-------------|
| `gp <profile>` | Switch to a profile |
| `gp list` | List available profiles |
| `gp current` | Show current configuration |
| `gp help` | Show help information |

## Profile Configuration

Profile files are stored in `~/dotfiles/config/git-profiles/` with `.conf` extension.

### Example Profile Structure

```bash
# Git Profile: personal
# Created: 2024-01-15

# Git user configuration
GIT_USER_NAME="John Doe"
GIT_USER_EMAIL="john@example.com"

# SSH key path (relative to ~/.ssh/)
SSH_KEY_NAME="id_rsa_personal"

# GitHub CLI account (optional)
GH_ACCOUNT="johndoe"

# GPG signing key (optional)
GIT_SIGNING_KEY="ABC123DEF456"
```

## SSH Key Management

### Using the SSH Key Manager

The system includes a dedicated SSH key manager for organizing keys in `~/dotfiles/ssh-keys/`:

#### Generate a New SSH Key
```bash
~/dotfiles/scripts/ssh-key-manager generate
# Or use: ssh-keygen -t ed25519 -C "email@example.com" -f ~/dotfiles/ssh-keys/github-personal
```

#### List All SSH Keys
```bash
~/dotfiles/scripts/ssh-key-manager list
```

#### Migrate Existing Keys
Move your existing SSH keys from `~/.ssh/` to the organized structure:
```bash
~/dotfiles/scripts/ssh-key-manager migrate
```

#### Test SSH Connection
```bash
~/dotfiles/scripts/ssh-key-manager test github-personal
```

#### Copy Public Key to Clipboard
```bash
~/dotfiles/scripts/ssh-key-manager copy github-personal
```

### SSH Key Storage

SSH keys are stored in `~/dotfiles/ssh-keys/` for better organization:

1. **Generate keys directly in the dotfiles directory:**
```bash
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/dotfiles/ssh-keys/github-personal
```

2. **Create symlinks for SSH to find them:**
```bash
ln -sf ~/dotfiles/ssh-keys/github-personal ~/.ssh/github-personal
ln -sf ~/dotfiles/ssh-keys/github-personal.pub ~/.ssh/github-personal.pub
```

3. **Add to ssh-agent:**
```bash
ssh-add ~/dotfiles/ssh-keys/github-personal
```

### SSH Config Setup

Your `~/.ssh/config` should contain host entries for different accounts:

```
# Personal GitHub
Host github.com-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/github-personal

# Work GitHub
Host github.com-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/github-work
```

**Note:** The IdentityFile points to `~/.ssh/` (which are symlinks) for compatibility.

## GitHub CLI Integration

### Setting Up Multiple GitHub CLI Accounts

1. Login to GitHub CLI with your first account:
```bash
gh auth login
```

2. Add additional accounts:
```bash
gh auth login --hostname github.com
```

3. Switch between accounts:
```bash
gh auth switch
```

The profile manager will remind you to switch GitHub CLI accounts when needed.

## Usage Scenarios

### Scenario 1: Working on Personal Projects

```bash
# Switch to personal profile
gp personal

# Clone a personal repo
git clone git@github.com-personal:username/project.git

# Your commits will use personal email and SSH key
```

### Scenario 2: Working on Company Projects

```bash
# Switch to work profile
gp work

# Clone a work repo
git clone git@github.com-work:company/project.git

# Your commits will use work email and SSH key
```

### Scenario 3: Per-Repository Configuration

```bash
cd ~/projects/client-project

# Switch profile for this repository only
gp client

# This only affects the current repository
# Other repositories remain unchanged
```

## Security Notes

1. **Profile configurations are gitignored** - Your personal information in profile files won't be committed to version control.

2. **SSH keys are gitignored** - The entire `ssh-keys/` directory (except README.md) is gitignored to prevent accidental commits.

3. **SSH keys remain secure** - The system only references SSH key names, not the actual keys.

4. **The example.conf template** - This is the only profile file that gets committed, serving as a template for others.

5. **Organized structure** - Keys are stored in `~/dotfiles/ssh-keys/` with symlinks to `~/.ssh/` for compatibility.

## Troubleshooting

### Profile Not Found

If you get "Profile not found" error:
```bash
# List available profiles
gpm list

# Create the profile if it doesn't exist
gpm create
```

### SSH Key Issues

If SSH authentication fails:
```bash
# Check if SSH key exists
ls -la ~/.ssh/

# Test SSH connection
ssh -T git@github.com

# Verify SSH key is loaded
ssh-add -l
```

### GitHub CLI Not Switching

The scripts remind you to switch GitHub CLI accounts but don't do it automatically:
```bash
# Manually switch GitHub CLI account
gh auth switch
```

### Current Profile Not Detected

If no matching profile is found:
```bash
# Check current git configuration
git config user.email
git config user.name

# Create a profile matching your current setup
gpm create
```

## Best Practices

1. **Use descriptive profile names**: "personal", "work", "freelance", etc.

2. **Keep profiles updated**: Run `gpm update <profile>` when credentials change.

3. **Test after switching**: Always run `gpm current` after switching profiles to verify.

4. **Use per-repository configs**: For client or sensitive projects, configure profiles per-repository rather than globally.

5. **Regular backups**: While profiles are gitignored, consider backing up your `config/git-profiles/` directory.

## Advanced Usage

### Cloning Profiles

Create variations of existing profiles:
```bash
gpm clone personal personal-oss
gpm update personal-oss  # Modify as needed
```

### Scripting

Use in scripts for automation:
```bash
#!/bin/bash
# Auto-switch profile based on directory
if [[ "$PWD" == *"work"* ]]; then
    gp work
else
    gp personal
fi
```

### Integration with Shell Prompt

Add current profile to your shell prompt by checking:
```bash
gpm current | grep "Active profile" | cut -d: -f2
```

## Contributing

To adapt this system for your dotfiles:

1. Copy the scripts to your dotfiles
2. Update paths in scripts if needed
3. Create your own profiles using `gpm create`
4. Customize aliases in your shell configuration

The system is designed to be portable and adaptable to different dotfile structures.