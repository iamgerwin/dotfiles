#!/usr/bin/env zsh
# Plugin configuration

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

# NVM (Node Version Manager)
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

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

# Load completions
autoload -Uz compinit && compinit

# zsh-autosuggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#999"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Enable extended globbing
setopt EXTENDED_GLOB

# FZF integration
if [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
fi