#!/usr/bin/env zsh
# Key bindings configuration

# Use emacs key bindings (default)
bindkey -e

# Navigation
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^[[1;5C' forward-word   # Ctrl+Right
bindkey '^[[1;5D' backward-word  # Ctrl+Left
bindkey '^[[H' beginning-of-line # Home
bindkey '^[[F' end-of-line       # End

# History search
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
bindkey '^P' history-search-backward
bindkey '^N' history-search-forward
bindkey '^[[A' up-line-or-history    # Up arrow
bindkey '^[[B' down-line-or-history  # Down arrow

# Editing
bindkey '^K' kill-line
bindkey '^U' backward-kill-line
bindkey '^W' backward-kill-word
bindkey '^[[3~' delete-char      # Delete
bindkey '^?' backward-delete-char # Backspace

# Completion
bindkey '^I' complete-word        # Tab
bindkey '^[[Z' reverse-menu-complete # Shift+Tab

# Undo/Redo
bindkey '^Z' undo
bindkey '^Y' redo

# Accept autosuggestion (if using zsh-autosuggestions)
bindkey '^Space' autosuggest-accept
bindkey '^[[1;2C' autosuggest-accept # Shift+Right

# Clear screen
bindkey '^L' clear-screen

# Edit command line in editor
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Make search up and down work with arrow keys
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# Better word movement (treating paths as single words)
autoload -U select-word-style
select-word-style bash