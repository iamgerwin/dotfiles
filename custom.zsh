#!/usr/bin/env zsh
# Custom configurations and machine-specific settings

# Load local machine-specific configurations if they exist
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Load private/sensitive configurations (not tracked in git)
[[ -f ~/.zshrc.private ]] && source ~/.zshrc.private

# Load work-specific configurations
[[ -f ~/.zshrc.work ]] && source ~/.zshrc.work

# Custom prompt modifications (if not using a theme)
# Can be overridden per machine

# FZF configuration if installed
if [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# NVM (Node Version Manager) if installed
if [[ -d "$HOME/.nvm" ]]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
fi

# rbenv (Ruby Version Manager) if installed
if command -v rbenv &> /dev/null; then
    eval "$(rbenv init - zsh)"
fi

# pyenv (Python Version Manager) if installed
if command -v pyenv &> /dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Google Cloud SDK
if [[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]]; then
    source "$HOME/google-cloud-sdk/path.zsh.inc"
fi
if [[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]]; then
    source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# AWS CLI completion
if command -v aws_completer &> /dev/null; then
    complete -C aws_completer aws
fi

# Custom welcome message (optional)
# echo "Welcome back, $(whoami)! 🚀"