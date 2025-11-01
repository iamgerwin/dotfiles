#!/usr/bin/env zsh
# Exports - Environment variables and PATH

# Default programs
export EDITOR='vim'
export VISUAL='vim'
export PAGER='less'
export BROWSER='open'

# Language and locale
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# History
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zsh_history

# Oh My Zsh installation path
export ZSH="$HOME/.oh-my-zsh"

# PATH additions
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"

# Dotfiles scripts
export PATH="$HOME/dotfiles/scripts:$PATH"

# Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# Herd PHP Configuration
export PATH="$HOME/Library/Application Support/Herd/bin/:$PATH"

# Herd injected PHP configurations
export HERD_PHP_84_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/84/"
export HERD_PHP_83_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/83/"
export HERD_PHP_82_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/82/"
export HERD_PHP_81_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/81/"

# Homebrew (if on macOS)
if [[ "$(uname)" == "Darwin" ]]; then
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
export PATH="$HOME/.npm-global/bin:$PATH"

# Pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Ruby
if [[ -d "$HOME/.rbenv" ]]; then
    export PATH="$HOME/.rbenv/bin:$PATH"
fi

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Java
if [[ -f "/usr/libexec/java_home" ]]; then
    export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null)
fi

# Less options
export LESS='-R -F -X'
export LESSHISTFILE='-'

# Colors
export CLICOLOR=1
export LSCOLORS='GxFxCxDxBxegedabagaced'

# GPG (with guard for VSCode/Windsurf terminals)
if [[ -t 0 && ! -n "$VSCODE_PID" ]]; then
    export GPG_TTY=$(tty)
fi

# FZF defaults
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# Man pages color
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

# AI Agent CLI Tools
# Add your API keys to ~/.zshrc.local for security
# export GEMINI_API_KEY="your-gemini-api-key-here"
# export OPENAI_API_KEY="your-openai-api-key-here"
# export ANTHROPIC_API_KEY="your-anthropic-api-key-here"
# export CLAUDE_API_KEY="your-claude-api-key-here"  # Alternative naming
