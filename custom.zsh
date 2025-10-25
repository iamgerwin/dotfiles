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

# NOTE: NVM, rbenv, and pyenv are already loaded in plugins.zsh
# Do not load them again here to avoid hangs and slow startup

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