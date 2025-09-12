# CLI Tools Setup Guide

Comprehensive installation and configuration guide for development CLI tools including GPT Codex CLI, Claude Code, and related dependencies.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Claude Code CLI](#claude-code-cli)
- [GPT Codex CLI](#gpt-codex-cli)
- [Environment Configuration](#environment-configuration)
- [OS-Specific Instructions](#os-specific-instructions)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before installing the CLI tools, ensure you have the following prerequisites installed:

### Required Dependencies

#### 1. Node.js and npm
```bash
# macOS with Homebrew
brew install node

# Verify installation
node --version  # Should be v18.0.0 or higher
npm --version   # Should be v8.0.0 or higher
```

#### 2. Git
```bash
# macOS with Homebrew
brew install git

# Verify installation
git --version
```

#### 3. Python (for some CLI tools)
```bash
# macOS with Homebrew
brew install python@3.11

# Verify installation
python3 --version
```

## Claude Code CLI

### Installation

Claude Code is Anthropic's official CLI for development assistance.

#### macOS Installation

```bash
# Install via Homebrew (recommended)
brew install --cask claude

# Alternative: Direct download
# Visit: https://claude.ai/download
# Download the appropriate installer for your system
```

#### Linux Installation

```bash
# Using snap
sudo snap install claude

# Using AppImage
wget https://releases.anthropic.com/claude-latest.AppImage
chmod +x claude-latest.AppImage
sudo mv claude-latest.AppImage /usr/local/bin/claude
```

#### Windows Installation

```powershell
# Using Chocolatey
choco install claude

# Using Scoop
scoop bucket add extras
scoop install claude

# Alternative: Download installer
# Visit: https://claude.ai/download
```

### Configuration

1. **Initial Setup**
```bash
# Initialize Claude Code
claude init

# Login with your Anthropic account
claude login
```

2. **Configure API Key**
```bash
# Set API key (if using API mode)
export ANTHROPIC_API_KEY="your-api-key-here"

# Add to shell configuration for persistence
echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.zshrc
```

3. **Workspace Configuration**
Create `.claude/config.json` in your project root:
```json
{
  "model": "claude-3-opus-20240229",
  "temperature": 0.7,
  "max_tokens": 4096,
  "workspace": {
    "include": ["src/**", "lib/**"],
    "exclude": ["node_modules", "dist", ".git"]
  }
}
```

### Usage Aliases

Add these aliases to your shell configuration:
```bash
# Claude Code aliases
alias cl='claude'
alias clc='claude chat'
alias clr='claude review'
alias cld='claude debug'
alias clh='claude help'
```

## GPT Codex CLI

### Installation Options

#### Option 1: OpenAI CLI (Official)

```bash
# Install via pip
pip install openai-cli

# Or using pipx (recommended for isolated installation)
pipx install openai-cli

# Verify installation
openai --version
```

#### Option 2: GitHub Copilot CLI

```bash
# Install GitHub CLI first
brew install gh

# Install Copilot extension
gh extension install github/gh-copilot

# Authenticate
gh auth login
gh copilot config
```

#### Option 3: GPT CLI Tools

```bash
# Install gpt-cli via npm
npm install -g gpt-cli

# Or using yarn
yarn global add gpt-cli

# Alternative: ai-cli tool
npm install -g @alexrudall/ai-cli
```

### Configuration

#### OpenAI CLI Configuration

1. **Set API Key**
```bash
# Set OpenAI API key
export OPENAI_API_KEY="sk-your-api-key-here"

# Add to shell configuration
echo 'export OPENAI_API_KEY="sk-your-api-key-here"' >> ~/.zshrc
```

2. **Configure Model Preferences**
```bash
# Create configuration file
mkdir -p ~/.config/openai
cat > ~/.config/openai/config.json << EOF
{
  "default_model": "gpt-4-turbo-preview",
  "temperature": 0.7,
  "max_tokens": 2048,
  "organization": "org-your-org-id"
}
EOF
```

#### GitHub Copilot CLI Configuration

```bash
# Configure Copilot CLI
gh copilot config

# Set default editor
gh config set editor "code"

# Enable suggestions
gh copilot suggest --enable
```

### Usage Examples

```bash
# OpenAI CLI
openai complete "Write a function to calculate fibonacci"
openai chat "Explain this code: $(cat script.js)"

# GitHub Copilot CLI
gh copilot suggest "create a docker compose file"
gh copilot explain "git rebase -i HEAD~3"

# GPT CLI
gpt "Convert this JSON to YAML" < data.json
gpt code "implement binary search in Python"
```

## Environment Configuration

### Shell Configuration

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# =================================================================
# CLI Tools Configuration
# =================================================================

# Claude Code Configuration
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
export CLAUDE_MODEL="claude-3-opus-20240229"
export CLAUDE_WORKSPACE="$HOME/Development"

# OpenAI Configuration
export OPENAI_API_KEY="${OPENAI_API_KEY:-}"
export OPENAI_ORG_ID="${OPENAI_ORG_ID:-}"
export OPENAI_MODEL="gpt-4-turbo-preview"

# GitHub Copilot Configuration
export COPILOT_ENABLED=true
export GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# Custom CLI paths
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# CLI Tool Aliases
alias ai='claude'
alias gpt='openai'
alias cop='gh copilot'

# Quick commands
alias ai-review='claude review --files'
alias ai-commit='claude commit --generate'
alias gpt-explain='openai explain --verbose'
alias cop-suggest='gh copilot suggest'

# Functions for enhanced usage
ai-help() {
    claude chat "Help me with: $*"
}

gpt-code() {
    openai complete "Write code for: $*" --format code
}

cop-fix() {
    gh copilot suggest "fix this error: $*"
}
```

### API Keys Management

#### Secure Storage with 1Password CLI

```bash
# Install 1Password CLI
brew install --cask 1password-cli

# Store API keys securely
op item create \
  --category=apikey \
  --title="Anthropic API Key" \
  --vault="Development" \
  apikey="your-anthropic-key"

# Retrieve in shell configuration
export ANTHROPIC_API_KEY="$(op read "op://Development/Anthropic API Key/apikey")"
```

#### Using macOS Keychain

```bash
# Store API key in keychain
security add-generic-password \
  -a "$USER" \
  -s "anthropic-api-key" \
  -w "your-api-key-here"

# Retrieve in shell configuration
export ANTHROPIC_API_KEY="$(security find-generic-password -a "$USER" -s "anthropic-api-key" -w)"
```

#### Using .env Files

```bash
# Create .env file (add to .gitignore!)
cat > ~/.env.cli-tools << EOF
ANTHROPIC_API_KEY=your-anthropic-key
OPENAI_API_KEY=sk-your-openai-key
GITHUB_TOKEN=ghp_your-github-token
EOF

# Source in shell configuration
[[ -f ~/.env.cli-tools ]] && source ~/.env.cli-tools
```

## OS-Specific Instructions

### macOS

#### System Requirements
- macOS 12.0 (Monterey) or later
- Xcode Command Line Tools: `xcode-select --install`
- Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

#### Permissions Setup
```bash
# Grant terminal full disk access if needed
# System Preferences > Security & Privacy > Privacy > Full Disk Access

# Fix permissions for global npm packages
sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}
```

### Linux

#### Ubuntu/Debian
```bash
# Update package lists
sudo apt update

# Install prerequisites
sudo apt install -y curl wget git build-essential

# Install Node.js via NodeSource
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Install Python and pip
sudo apt install -y python3 python3-pip pipx
```

#### Fedora/RHEL
```bash
# Install development tools
sudo dnf groupinstall "Development Tools"

# Install Node.js
sudo dnf install nodejs npm

# Install Python
sudo dnf install python3 python3-pip
```

#### Arch Linux
```bash
# Install prerequisites
sudo pacman -S base-devel git nodejs npm python python-pip
```

### Windows

#### Using WSL2 (Recommended)
```bash
# Install WSL2
wsl --install

# Follow Linux instructions above within WSL2
```

#### Native Windows

1. **Install Node.js**
   - Download from: https://nodejs.org/
   - Use LTS version
   - Verify: `node --version` in PowerShell

2. **Install Python**
   - Download from: https://python.org/
   - Check "Add Python to PATH" during installation
   - Verify: `python --version` in PowerShell

3. **Install Git**
   - Download from: https://git-scm.com/
   - Use recommended settings
   - Verify: `git --version` in PowerShell

4. **Package Managers**
```powershell
# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Or install Scoop
iwr -useb get.scoop.sh | iex
```

## Verification

### Test Installation

Create a test script `verify-cli-tools.sh`:

```bash
#!/bin/bash

echo "Verifying CLI Tools Installation..."
echo "=================================="

# Check Node.js
echo -n "Node.js: "
if command -v node &> /dev/null; then
    node --version
else
    echo "NOT INSTALLED"
fi

# Check npm
echo -n "npm: "
if command -v npm &> /dev/null; then
    npm --version
else
    echo "NOT INSTALLED"
fi

# Check Python
echo -n "Python: "
if command -v python3 &> /dev/null; then
    python3 --version
else
    echo "NOT INSTALLED"
fi

# Check Claude
echo -n "Claude Code: "
if command -v claude &> /dev/null; then
    claude --version 2>/dev/null || echo "Installed (version check not available)"
else
    echo "NOT INSTALLED"
fi

# Check OpenAI CLI
echo -n "OpenAI CLI: "
if command -v openai &> /dev/null; then
    openai --version
else
    echo "NOT INSTALLED"
fi

# Check GitHub CLI
echo -n "GitHub CLI: "
if command -v gh &> /dev/null; then
    gh --version | head -n1
else
    echo "NOT INSTALLED"
fi

# Check API Keys
echo ""
echo "API Key Configuration:"
echo "----------------------"
[[ -n "$ANTHROPIC_API_KEY" ]] && echo "✓ Anthropic API Key configured" || echo "✗ Anthropic API Key not set"
[[ -n "$OPENAI_API_KEY" ]] && echo "✓ OpenAI API Key configured" || echo "✗ OpenAI API Key not set"
[[ -n "$GITHUB_TOKEN" ]] && echo "✓ GitHub Token configured" || echo "✗ GitHub Token not set"
```

Run verification:
```bash
chmod +x verify-cli-tools.sh
./verify-cli-tools.sh
```

### Test Commands

```bash
# Test Claude Code
claude --help
claude chat "Hello, test message"

# Test OpenAI CLI
openai --help
echo "Test prompt" | openai complete

# Test GitHub Copilot
gh copilot --help
gh copilot suggest "list all docker containers"
```

## Troubleshooting

### Common Issues

#### 1. Permission Denied Errors

```bash
# Fix npm global permissions
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc

# Fix pip permissions
pip install --user <package>
# Or use pipx for isolated installs
pipx install <package>
```

#### 2. API Key Not Found

```bash
# Check if API key is set
echo $ANTHROPIC_API_KEY
echo $OPENAI_API_KEY

# Re-export if needed
export ANTHROPIC_API_KEY="your-key-here"
export OPENAI_API_KEY="sk-your-key-here"

# Verify shell configuration
grep "API_KEY" ~/.zshrc
```

#### 3. Command Not Found

```bash
# Refresh shell configuration
source ~/.zshrc

# Check PATH
echo $PATH

# Find installation location
which claude
which openai
which gh

# Reinstall if necessary
brew reinstall claude
npm install -g openai-cli
```

#### 4. SSL/Certificate Errors

```bash
# Update certificates on macOS
brew install ca-certificates

# On Linux
sudo apt-get install ca-certificates
sudo update-ca-certificates

# Temporary workaround (not recommended for production)
export NODE_TLS_REJECT_UNAUTHORIZED=0
```

#### 5. Rate Limiting

```bash
# Configure rate limiting for API calls
export OPENAI_RATE_LIMIT=10  # requests per minute
export ANTHROPIC_RATE_LIMIT=5  # requests per minute

# Add delay between requests
alias ai-safe='claude --delay 2000'  # 2 second delay
```

### Debug Mode

Enable debug output for troubleshooting:

```bash
# Claude Code debug mode
export CLAUDE_DEBUG=true
claude --debug chat "test"

# OpenAI CLI verbose mode
openai --verbose complete "test"

# GitHub Copilot debug
export GH_DEBUG=api
gh copilot suggest "test"
```

### Getting Help

- **Claude Code**: `claude help` or visit https://docs.anthropic.com/claude-code
- **OpenAI CLI**: `openai --help` or visit https://platform.openai.com/docs
- **GitHub Copilot CLI**: `gh copilot --help` or visit https://docs.github.com/copilot
- **Community Support**: Check GitHub issues for each tool
- **Stack Overflow**: Search with tags `claude-code`, `openai-cli`, `github-copilot`

## Best Practices

### Security

1. **Never commit API keys to version control**
   ```bash
   # Add to .gitignore
   echo ".env*" >> .gitignore
   echo "*.key" >> .gitignore
   ```

2. **Use environment-specific configurations**
   ```bash
   # Development
   export CLAUDE_ENV=development
   
   # Production
   export CLAUDE_ENV=production
   ```

3. **Rotate API keys regularly**
   - Set calendar reminders for key rotation
   - Use key management services when possible

### Performance

1. **Cache responses when appropriate**
   ```bash
   # Enable caching for Claude Code
   export CLAUDE_CACHE_DIR="$HOME/.cache/claude"
   export CLAUDE_CACHE_TTL=3600  # 1 hour
   ```

2. **Use appropriate models for tasks**
   - Fast models for simple queries
   - Advanced models for complex reasoning

3. **Batch operations when possible**
   ```bash
   # Process multiple files at once
   claude review src/**/*.js --batch
   ```

### Integration

1. **Integrate with your IDE**
   - VS Code: Install Claude/Copilot extensions
   - Neovim: Use copilot.vim or similar plugins
   - JetBrains: Install GitHub Copilot plugin

2. **Set up git hooks**
   ```bash
   # Pre-commit hook for code review
   cat > .git/hooks/pre-commit << 'EOF'
   #!/bin/bash
   claude review --staged --fail-on-issues
   EOF
   chmod +x .git/hooks/pre-commit
   ```

3. **Create custom workflows**
   ```bash
   # Custom function for PR reviews
   pr-review() {
       gh pr diff $1 | claude review --format markdown
   }
   ```

## Additional Resources

### Official Documentation
- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [OpenAI Platform Docs](https://platform.openai.com/docs)
- [GitHub Copilot Docs](https://docs.github.com/copilot)

### Tutorials and Guides
- [Getting Started with Claude Code](https://claude.ai/docs/quickstart)
- [OpenAI API Best Practices](https://platform.openai.com/docs/guides/best-practices)
- [GitHub Copilot Tips and Tricks](https://github.blog/2023-06-20-copilot-tips/)

### Community Resources
- [Claude Code GitHub Repository](https://github.com/anthropics/claude-code)
- [OpenAI Community Forum](https://community.openai.com/)
- [GitHub Copilot Discussions](https://github.com/community/community/discussions/categories/copilot)

### Video Tutorials
- Search YouTube for "Claude Code setup tutorial"
- Search YouTube for "OpenAI CLI tutorial"
- Search YouTube for "GitHub Copilot CLI guide"