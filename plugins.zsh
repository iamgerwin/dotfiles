#!/usr/bin/env zsh
# Plugin configuration

# Disable Oh My Zsh completion security checks
export ZSH_DISABLE_COMPFIX="true"

# Oh My Zsh configuration
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    # Theme
    ZSH_THEME="powerlevel10k/powerlevel10k"
    
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
        composer
        laravel
        python
        pip
        zsh-autosuggestions
        zsh-syntax-highlighting
        z
    )
    
    # Load Oh My Zsh
    source $ZSH/oh-my-zsh.sh
fi

# NVM (Node Version Manager) - Lazy load for faster startup
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # Skip NVM loading in VSCode/Windsurf to avoid hangs
    if [[ -z "$VSCODE_PID" && -z "$TERM_PROGRAM" ]]; then
        \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    else
        # Lazy load NVM when needed
        nvm() {
            unset -f nvm
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
            nvm "$@"
        }
        node() {
            unset -f node
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            node "$@"
        }
        npm() {
            unset -f npm
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            npm "$@"
        }
    fi
fi

# Pyenv initialization
if command -v pyenv >/dev/null; then
    eval "$(pyenv init -)"
fi

# rbenv initialization
if command -v rbenv >/dev/null; then
    eval "$(rbenv init - zsh)"
fi

# Homebrew completions
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# zsh-autosuggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#999"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Enable extended globbing
setopt EXTENDED_GLOB

# FZF integration
if [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
fi