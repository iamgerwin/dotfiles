#!/usr/bin/env zsh

# Check if Oh My Zsh is installed and set ZSH variable
export ZSH="$HOME/.oh-my-zsh"

# Set up FPATH for Zsh functions (must be done before autoload)
# Add standard Zsh function paths
typeset -U fpath
fpath=(
    /usr/share/zsh/5.9/functions
    /opt/homebrew/share/zsh/site-functions
    /opt/homebrew/Cellar/zsh/5.9/share/zsh/functions
    $fpath
)

# Load essential Zsh modules
autoload -Uz compinit && compinit -u
autoload -Uz bashcompinit && bashcompinit
autoload -Uz add-zsh-hook
autoload -Uz vcs_info
autoload -Uz colors && colors
autoload -Uz is-at-least
autoload -Uz select-word-style

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

# Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="/Users/gerwin/Library/Application Support/Herd/config/php/84/"


# Herd injected PHP 8.3 configuration.
export HERD_PHP_83_INI_SCAN_DIR="/Users/gerwin/Library/Application Support/Herd/config/php/83/"


# Herd injected PHP 8.2 configuration.
export HERD_PHP_82_INI_SCAN_DIR="/Users/gerwin/Library/Application Support/Herd/config/php/82/"


# Herd injected PHP 8.1 configuration.
export HERD_PHP_81_INI_SCAN_DIR="/Users/gerwin/Library/Application Support/Herd/config/php/81/"


# Herd injected PHP 8.5 configuration.
export HERD_PHP_85_INI_SCAN_DIR="/Users/gerwin/Library/Application Support/Herd/config/php/85/"
