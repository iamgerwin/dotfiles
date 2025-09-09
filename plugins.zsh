#!/usr/bin/env zsh
# Plugin configuration

# Oh My Zsh configuration (if using Oh My Zsh)
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    
    # Theme
    ZSH_THEME="robbyrussell"
    
    # Plugins
    plugins=(
        git
        docker
        docker-compose
        kubectl
        npm
        node
        macos
        brew
        zsh-autosuggestions
        zsh-syntax-highlighting
        z
    )
    
    # Load Oh My Zsh
    source $ZSH/oh-my-zsh.sh
fi

# Homebrew completions
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# Load completions
autoload -Uz compinit && compinit

# zsh-autosuggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#999"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Enable extended globbing
setopt EXTENDED_GLOB