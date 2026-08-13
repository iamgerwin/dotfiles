# AI CLI Tools Installation Guide

This guide will help you install and configure Claude, Gemini, Codex, and OpenCode CLI tools on your system, plus the supporting `rtk-ai` and `gh-stack` CLI extensions.

## Quick Installation

### Option 1: Automated Installation (Recommended)

Run the Homebrew installation script which includes an option to install AI tools:

```bash
~/dotfiles/scripts/install-brew.sh
```

The script will:
1. Install or update Homebrew
2. Prompt you to install AI CLI tools (Claude, Gemini, Codex, OpenCode)
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

# Install OpenCode (terminal-based AI coding assistant)
brew install opencode
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

## Installing rtk-ai (Token Optimization Proxy)

[rtk-ai](https://github.com/rtk-ai/rtk) is a token-optimized CLI proxy that filters and summarizes command output (git, find, grep, test runners, etc.) before it reaches an assistant's context, cutting token usage by up to ~90% on common commands.

### Automated Installation (Recommended)

```bash
~/dotfiles/scripts/setup-rtk.sh
```

The script will:
1. Install `rtk` globally via Homebrew (also included in the Brewfile — `brew bundle install` installs it too)
2. Wire it into Claude Code (`rtk init -g --auto-patch`) — registers a `PreToolUse` Bash hook in `~/.claude/settings.json`
3. Wire it into Codex CLI (`rtk init --codex -g`) — adds `~/.codex/RTK.md` and references it from `~/.codex/AGENTS.md`
4. Wire it into OpenCode (`rtk init --opencode -g --auto-patch`) — installs `~/.config/opencode/plugins/rtk.ts`
5. Skip any tool that isn't installed

### Manual Installation

```bash
# Install globally
brew install rtk

# Wire into each assistant CLI you use
rtk init -g --auto-patch          # Claude Code
rtk init --codex -g               # Codex CLI
rtk init --opencode -g --auto-patch  # OpenCode
```

### Verification

```bash
rtk --version
rtk gain
which rtk
```

## Installing gh-stack (Stacked PRs)

[gh-stack](https://github.com/github/gh-stack) is a `gh` CLI extension for managing stacked branches and dependent pull requests, with an accompanying agent skill for creating/rebasing/syncing stacks from Claude Code, Codex, and OpenCode.

### Automated Installation (Recommended)

```bash
~/dotfiles/scripts/setup-gh-stack.sh
```

The script will:
1. Install the extension: `gh extension install github/gh-stack`
2. Install the agent skill at user (global) scope for Claude Code, Codex, and OpenCode via `gh skill install github/gh-stack --agent <agent> --scope user`

### Manual Installation

```bash
gh extension install github/gh-stack
gh skill install github/gh-stack --agent claude-code --scope user
gh skill install github/gh-stack --agent codex --scope user
gh skill install github/gh-stack --agent opencode --scope user
```

### Verification

```bash
gh extension list
gh skill list
gh stack --help
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

### OpenCode
OpenCode supports multiple providers. Configure the API key for your preferred provider:
- **Anthropic**: Use `ANTHROPIC_API_KEY` (same as Claude)
- **OpenAI**: Use `OPENAI_API_KEY` (same as Codex)
- **Google**: Use `GEMINI_API_KEY` (same as Gemini)

Configuration file: `~/.config/opencode/config.json`

For more details, visit: https://opencode.ai/docs

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
command -v opencode && echo "OpenCode: ✓" || echo "OpenCode: ✗"
command -v rtk && echo "rtk: ✓" || echo "rtk: ✗"
gh extension list | grep -q gh-stack && echo "gh-stack: ✓" || echo "gh-stack: ✗"

# Check versions
claude --version
gemini --version
codex --version
opencode --version
rtk --version
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
brew upgrade opencode
brew upgrade rtk
gh extension upgrade github/gh-stack
gh skill update --all
```

## Uninstallation

Remove AI tools:

```bash
brew uninstall --cask claude-code
brew uninstall gemini-cli
brew uninstall --cask codex
brew uninstall opencode
brew uninstall rtk
gh extension remove github/gh-stack
```

To remove rtk's per-tool wiring: `rtk init -g --uninstall`, `rtk init --codex -g --uninstall`, `rtk init --opencode -g --uninstall`.

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
- Script Issues: Review `~/dotfiles/scripts/setup-ai-tools.sh`, `~/dotfiles/scripts/setup-rtk.sh`, `~/dotfiles/scripts/setup-gh-stack.sh`
- rtk-ai: https://github.com/rtk-ai/rtk
- gh-stack: https://github.com/github/gh-stack

For more information, see the main AI tools documentation or the AGENTS.md rule file in your dotfiles.
