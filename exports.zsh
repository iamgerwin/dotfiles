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

# PATH additions
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"

# Homebrew (if on macOS)
if [[ "$(uname)" == "Darwin" ]]; then
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Node.js
export PATH="$HOME/.npm-global/bin:$PATH"
if command -v nvm &> /dev/null; then
    export NVM_DIR="$HOME/.nvm"
fi

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1
if [[ -d "$HOME/.pyenv" ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
fi

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

# GPG
export GPG_TTY=$(tty)

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