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

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'
alias gdiff='git diff'

# System
alias c='clear'
alias h='history'
alias which='type -a'
alias path='echo -e ${PATH//:/\\n}'

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