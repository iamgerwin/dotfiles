#!/usr/bin/env zsh
# Prompt - Terminal prompt configuration

# Skip if using Powerlevel10k (avoid conflicts)
if [[ "$ZSH_THEME" == "powerlevel10k/powerlevel10k" ]]; then
    return 0
fi

# Enable prompt substitution
setopt PROMPT_SUBST

# Colors
autoload -U colors && colors

# Version control info
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes false
zstyle ':vcs_info:*' unstagedstr ' *'
zstyle ':vcs_info:*' stagedstr ' +'
zstyle ':vcs_info:git:*' formats ' [%b%u%c]'
zstyle ':vcs_info:git:*' actionformats ' [%b|%a%u%c]'

# Simple elegant prompt with git info
PROMPT='%{$fg[cyan]%}%n@%m%{$reset_color%}:%{$fg[green]%}%~%{$reset_color%}%{$fg[yellow]%}${vcs_info_msg_0_}%{$reset_color%}
%(?:%{$fg[green]%}➜ :%{$fg[red]%}➜ )%{$reset_color%}'

# Right prompt with time
RPROMPT='%{$fg[gray]%}[%*]%{$reset_color%}'

# Alternative prompts (uncomment to use)

# Minimal prompt
# PROMPT='%{$fg[blue]%}%1~%{$reset_color%} %# '

# Two-line prompt with more info
# PROMPT='%{$fg[blue]%}┌─[%{$fg[cyan]%}%n%{$fg[blue]%}@%{$fg[cyan]%}%m%{$fg[blue]%}]─[%{$fg[green]%}%~%{$fg[blue]%}]%{$fg[yellow]%}${vcs_info_msg_0_}%{$reset_color%}
# %{$fg[blue]%}└─➜%{$reset_color%} '

# Powerline-style (requires powerline fonts)
# PROMPT='%{$fg[white]$bg[blue]%} %n@%m %{$fg[blue]$bg[green]%}%{$fg[black]$bg[green]%} %~ %{$fg[green]$bg[yellow]%}%{$fg[black]$bg[yellow]%}${vcs_info_msg_0_} %{$reset_color$fg[yellow]%}%{$reset_color%} '