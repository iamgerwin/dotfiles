#!/usr/bin/env zsh
# Aliases - Command shortcuts

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# List files
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -ltr'

# Modern replacements (if installed)
if command -v eza &> /dev/null; then
    alias ls='eza --icons'
    alias ll='eza -lah --icons'
    alias la='eza -a --icons'
    alias lt='eza -lah --sort=modified --icons'
    alias tree='eza --tree --icons'
fi

if command -v bat &> /dev/null; then
    alias cat='bat'
fi

if command -v zoxide &> /dev/null; then
    alias cd='z'
fi

if command -v dust &> /dev/null; then
    alias du='dust'
fi

if command -v delta &> /dev/null; then
    alias diff='delta'
fi

if command -v httpie &> /dev/null; then
    alias http='httpie'
fi

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git checkout'  # Using git checkout as gc like in your config
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'
alias gdiff='git diff'
alias gpod='git pull origin develop'
alias gdog='git log --all --decorate --oneline --graph'
alias gclean='git reset --hard && git clean -dfx'
alias gdp='git checkout develop && git pull origin develop'
alias grh='git reset --hard'

# Laravel & PHP
alias art='php artisan'
alias pbc='php bin/console'
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
alias pint='./vendor/bin/pint'
alias pint-modified='./vendor/bin/pint $(git diff --name-only --diff-filter=AM HEAD && git diff --cached --name-only --diff-filter=AM | sort -u | grep "\.php$")'

# System
alias c='clear'
alias h='history'
alias which='type -a'
alias path='echo -e ${PATH//:/\\n}'

# Neovim
if command -v nvim &> /dev/null; then
    alias vim='nvim'
    alias vi='nvim'
    alias v='nvim'
    alias nv='nvim'
    alias nvconf='cd ~/.config/nvim && nvim'
fi

# Lazygit
if command -v lazygit &> /dev/null; then
    alias lg='lazygit'
fi

# Package Management
alias brewu='brew update && brew upgrade && brew cleanup'
alias update-all='~/dotfiles/scripts/update-all.sh'
alias ua='update-all'
alias update='update-all'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

# Shortcuts
alias reload='source ~/.zshrc'
alias zshconfig='${EDITOR:-vim} ~/.zshrc'
alias dotfiles='cd ~/dotfiles'

# Docker
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'

# Python
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'

# Directory shortcuts
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'
alias docs='cd ~/Documents'
alias dev='cd ~/Development'

# Processes
alias psg='ps aux | grep'
alias port='lsof -i -P -n | grep LISTEN'

# Custom tools
alias clauded='SHELL=/bin/bash claude --dangerously-skip-permissions'
alias claude='SHELL=/bin/bash claude'

# AI Prompts Management
alias aip='ai-prompt'
alias aipl='ai-prompt list'
alias aips='ai-prompt search'
alias aipc='ai-prompt copy'
alias aipa='ai-prompt add'

# Quick template copy
alias pc='prompt-copy'
alias pct='prompt-copy create-ticket'
alias pcl='prompt-copy laravel-backend'
alias pcb='prompt-copy bug'
alias pcf='prompt-copy feature'
alias pca='prompt-copy api'
alias pcd='prompt-copy deployment'

# SSH Management
alias sshc='~/dotfiles/scripts/ssh-connect'
alias sshl='~/dotfiles/scripts/ssh-connect --list'
alias sshq='~/dotfiles/scripts/ssh-connect --quick'

# Tmux aliases
alias ta='tmux attach -t'
alias tad='tmux attach -d -t'
alias ts='tmux new-session -s'
alias tl='tmux list-sessions'
alias tksv='tmux kill-server'
alias tkss='tmux kill-session -t'
alias tmuxconf='$EDITOR ~/.tmux.conf'
alias tdev='~/.tmux/scripts/dev-session.sh'
alias tproject='~/.tmux/scripts/project-launcher.sh'
alias trn='tmux rename-session -t'
alias trw='tmux rename-window -t'
alias tn='tmux new-window -n'
alias tsp='tmux split-window -h'
alias tspv='tmux split-window -v'
alias tsw='tmux swap-window -t'
alias tlw='tmux list-windows'
alias tlp='tmux list-panes'
alias tkw='tmux kill-window -t'
alias tkp='tmux kill-pane -t'
alias trs='tmux resize-pane'
alias tcap='tmux capture-pane -t'
alias tsave='tmux save-buffer'
alias tshow='tmux show-buffer'