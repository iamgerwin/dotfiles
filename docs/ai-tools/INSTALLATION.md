# AI CLI Tools Installation Guide

This guide will help you install and configure Claude, Gemini, and Codex CLI tools on your system.

## Quick Installation

### Option 1: Automated Installation (Recommended)

Run the Homebrew installation script which includes an option to install AI tools:

```bash
~/dotfiles/scripts/install-brew.sh
```

The script will:
1. Install or update Homebrew
2. Prompt you to install AI CLI tools (Claude, Gemini, Codex)
3. Optionally configure API keys immediately

### Option 2: Manual Installation

Install AI tools via Homebrew:

```bash
# Install Claude Code (AI pair programming)
brew install --cask claude-code

# Install Gemini CLI
brew install gemini-cli

# Install Codex (as a cask application)
brew install --cask codex
```

Then configure API keys:

```bash
~/dotfiles/scripts/setup-ai-tools.sh
```

### Option 3: Install via Brewfile

Install all packages from the Brewfile (includes AI tools):

```bash
cd ~/dotfiles
brew bundle install
```

Then run the setup script to configure API keys:

```bash
~/dotfiles/scripts/setup-ai-tools.sh
```

## Getting API Keys

### Claude (Anthropic)
1. Visit: https://console.anthropic.com/
2. Sign up or log in
3. Navigate to API Keys section
4. Generate a new API key

### Gemini (Google)
1. Visit: https://makersuite.google.com/app/apikey
2. Sign in with your Google account
3. Create a new API key
4. Copy the key for configuration

### Codex (OpenAI)
1. Visit: https://platform.openai.com/api-keys
2. Sign up or log in
3. Create a new secret key
4. Save the key immediately (it won't be shown again)

## Configuration

### Automated Configuration

Run the setup script:

```bash
~/dotfiles/scripts/setup-ai-tools.sh
```

The script will:
- Check which AI tools are installed
- Prompt for API keys (if not already configured)
- Store API keys securely in `~/.zshrc.private`
- Create documentation symlinks

### Manual Configuration

Add API keys to `~/.zshrc.private`:

```bash
# Claude/Anthropic
export CLAUDE_API_KEY="your-claude-api-key-here"
export ANTHROPIC_API_KEY="your-claude-api-key-here"

# Gemini/Google
export GEMINI_API_KEY="your-gemini-api-key-here"

# Codex/OpenAI
export OPENAI_API_KEY="your-openai-api-key-here"
```

Then reload your shell:

```bash
source ~/.zshrc
```

## Verification

Test your installation:

```bash
# Check if tools are installed
command -v claude && echo "Claude: ✓" || echo "Claude: ✗"
command -v gemini && echo "Gemini: ✓" || echo "Gemini: ✗"
command -v codex && echo "Codex: ✓" || echo "Codex: ✗"

# Check versions
claude --version
gemini --version
codex --version
```

## Troubleshooting

### Command Not Found

If you get "command not found" after installation:

```bash
# Reload shell configuration
source ~/.zshrc

# Or restart your terminal
```

### API Key Not Working

Verify your API keys are set:

```bash
# Don't echo the actual keys, just check if they're set
[[ -n "$CLAUDE_API_KEY" ]] && echo "Claude key: set" || echo "Claude key: not set"
[[ -n "$GEMINI_API_KEY" ]] && echo "Gemini key: set" || echo "Gemini key: not set"
[[ -n "$OPENAI_API_KEY" ]] && echo "OpenAI key: set" || echo "OpenAI key: not set"
```

### Permission Errors

If you encounter permission errors during installation:

```bash
# Fix Homebrew permissions
sudo chown -R $(whoami) /usr/local/Cellar /usr/local/Homebrew
```

## Updating

Update AI tools via Homebrew:

```bash
# Update all packages
brew update && brew upgrade

# Or update specific tools
brew upgrade --cask claude-code
brew upgrade gemini-cli
brew upgrade --cask codex
```

## Uninstallation

Remove AI tools:

```bash
brew uninstall --cask claude-code
brew uninstall gemini-cli
brew uninstall --cask codex
```

Remove API keys from `~/.zshrc.private`:

```bash
# Edit the file and remove the export statements
nano ~/.zshrc.private
```

## Next Steps

1. Read the comprehensive guide: `~/dotfiles/docs/ai-tools/AI.md`
2. Test the tools with simple queries
3. Review security best practices
4. Set up shell aliases for convenience

## Support

- Main Documentation: `~/dotfiles/docs/ai-tools/AI.md`
- Homebrew Issues: `brew doctor`
- API Key Issues: Check provider's documentation
- Script Issues: Review `~/dotfiles/scripts/setup-ai-tools.sh`

For more information, see the main AI tools documentation or the AGENTS.md rule file in your dotfiles.
