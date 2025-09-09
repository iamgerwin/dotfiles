#!/usr/bin/env zsh
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Main .zshrc configuration file
# This file sources all modular zsh configuration files

# Define the dotfiles directory
DOTFILES_DIR="$HOME/dotfiles"

# Source configuration files in order
# The order matters for some configurations

# 1. Environment variables and PATH
[[ -f "$DOTFILES_DIR/exports.zsh" ]] && source "$DOTFILES_DIR/exports.zsh"

# 2. Shell options
[[ -f "$DOTFILES_DIR/options.zsh" ]] && source "$DOTFILES_DIR/options.zsh"

# 3. Plugins (should be loaded before aliases to ensure plugin aliases work)
[[ -f "$DOTFILES_DIR/plugins.zsh" ]] && source "$DOTFILES_DIR/plugins.zsh"

# 4. Custom functions
[[ -f "$DOTFILES_DIR/functions.zsh" ]] && source "$DOTFILES_DIR/functions.zsh"

# 5. Command aliases
[[ -f "$DOTFILES_DIR/aliases.zsh" ]] && source "$DOTFILES_DIR/aliases.zsh"

# 6. Key bindings
[[ -f "$DOTFILES_DIR/keybindings.zsh" ]] && source "$DOTFILES_DIR/keybindings.zsh"

# 7. Prompt configuration
[[ -f "$DOTFILES_DIR/prompt.zsh" ]] && source "$DOTFILES_DIR/prompt.zsh"

# 8. Custom/machine-specific configurations (loaded last to allow overrides)
[[ -f "$DOTFILES_DIR/custom.zsh" ]] && source "$DOTFILES_DIR/custom.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Performance profiling (uncomment to debug slow startup)
# zprof