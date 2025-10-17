#!/usr/bin/env bash
#
# Update All Packages Script
# This script updates all package managers and installed applications
# Author: Dotfiles Configuration
# Usage: ./update-all.sh [options]
#   Options:
#     --brew-only     Only update Homebrew packages
#     --npm-only      Only update npm packages
#     --pip-only      Only update pip packages
#     --no-cleanup    Skip cleanup operations
#     --verbose       Show detailed output

# Allow script to continue on errors but track them
set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
VERBOSE=false
CLEANUP=true
UPDATE_BREW=true
UPDATE_NPM=true
UPDATE_PIP=true
UPDATE_GEM=true
UPDATE_COMPOSER=true
UPDATE_RUST=true
UPDATE_GO=true

# Timeout configuration (in seconds)
DEFAULT_TIMEOUT=300
BREW_UPDATE_TIMEOUT=60
BREW_UPGRADE_TIMEOUT=600
NPM_TIMEOUT=300
PIP_TIMEOUT=300
GEM_TIMEOUT=300
COMPOSER_TIMEOUT=300

# Track script errors
HAS_ERRORS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --brew-only)
            UPDATE_NPM=false
            UPDATE_PIP=false
            UPDATE_GEM=false
            UPDATE_COMPOSER=false
            UPDATE_RUST=false
            UPDATE_GO=false
            shift
            ;;
        --npm-only)
            UPDATE_BREW=false
            UPDATE_PIP=false
            UPDATE_GEM=false
            UPDATE_COMPOSER=false
            UPDATE_RUST=false
            UPDATE_GO=false
            shift
            ;;
        --pip-only)
            UPDATE_BREW=false
            UPDATE_NPM=false
            UPDATE_GEM=false
            UPDATE_COMPOSER=false
            UPDATE_RUST=false
            UPDATE_GO=false
            shift
            ;;
        --no-cleanup)
            CLEANUP=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --brew-only     Only update Homebrew packages"
            echo "  --npm-only      Only update npm packages"
            echo "  --pip-only      Only update pip packages"
            echo "  --no-cleanup    Skip cleanup operations"
            echo "  --verbose       Show detailed output"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    HAS_ERRORS=true
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_section() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Safe command execution with timeout
run_with_timeout() {
    local timeout=$1
    shift
    local cmd="$@"
    
    # Use --kill-after to force kill if timeout is reached
    # Use --foreground to ensure proper signal handling
    if command -v timeout >/dev/null 2>&1; then
        timeout --foreground --kill-after=10 $timeout bash -c "$cmd"
        return $?
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout --foreground --kill-after=10 $timeout bash -c "$cmd"
        return $?
    else
        # Fallback without timeout
        bash -c "$cmd"
        return $?
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update Homebrew and packages
update_homebrew() {
    if [[ "$UPDATE_BREW" == true ]] && command_exists brew; then
        log_section "Updating Homebrew"
        
        # Clean up any stale lock files before updating
        local brew_prefix=$(brew --prefix 2>/dev/null)
        if [[ -n "$brew_prefix" && -f "$brew_prefix/var/homebrew/locks/update" ]]; then
            log_warning "Found stale Homebrew lock file, removing..."
            rm -f "$brew_prefix/var/homebrew/locks/update" 2>/dev/null || true
        fi
        
        log_info "Updating Homebrew itself..."
        if $VERBOSE; then
            run_with_timeout $BREW_UPDATE_TIMEOUT "brew update" || log_warning "Homebrew update timed out or failed"
        else
            run_with_timeout $BREW_UPDATE_TIMEOUT "brew update 2>&1" || log_warning "Homebrew update timed out or failed"
        fi
        [[ $? -eq 0 ]] && log_success "Homebrew updated"
        
        log_info "Upgrading Homebrew packages..."
        if $VERBOSE; then
            run_with_timeout $BREW_UPGRADE_TIMEOUT "brew upgrade" || log_warning "Some packages failed to upgrade"
        else
            run_with_timeout $BREW_UPGRADE_TIMEOUT "brew upgrade 2>&1" || log_warning "Some packages failed to upgrade"
        fi
        [[ $? -eq 0 ]] && log_success "Homebrew packages upgraded"
        
        log_info "Upgrading Homebrew casks (non-interactive)..."
        if $VERBOSE; then
            run_with_timeout $BREW_UPGRADE_TIMEOUT "brew upgrade --cask --greedy" || log_warning "Some casks failed to upgrade"
        else
            run_with_timeout $BREW_UPGRADE_TIMEOUT "brew upgrade --cask --greedy 2>&1" || log_warning "Some casks failed to upgrade"
        fi
        [[ $? -eq 0 ]] && log_success "Homebrew casks upgraded"
        
        if [[ "$CLEANUP" == true ]]; then
            log_info "Cleaning up Homebrew..."
            if $VERBOSE; then
                run_with_timeout 60 "brew cleanup -s" || log_warning "Cleanup incomplete"
                run_with_timeout 60 "brew autoremove" || log_warning "Autoremove incomplete"
            else
                run_with_timeout 60 "brew cleanup -s >/dev/null 2>&1" || true
                run_with_timeout 60 "brew autoremove >/dev/null 2>&1" || true
            fi
            log_success "Homebrew cleaned up"
        fi
        
        # Check for outdated packages (only if verbose mode)
        if $VERBOSE; then
            log_info "Checking for outdated packages..."
            outdated=$(run_with_timeout 10 "brew outdated 2>/dev/null" || true)
            if [[ -n "$outdated" ]]; then
                log_warning "Some packages are still outdated:"
                echo "$outdated"
            else
                log_success "All Homebrew packages are up to date"
            fi
        fi
    fi
}

# Update npm packages
update_npm() {
    if [[ "$UPDATE_NPM" == true ]] && command_exists npm; then
        log_section "Updating npm packages"
        
        log_info "Updating npm itself..."
        if $VERBOSE; then
            run_with_timeout $NPM_TIMEOUT "npm install -g npm@latest" || log_error "npm update failed or timed out"
        else
            run_with_timeout $NPM_TIMEOUT "npm install -g npm@latest >/dev/null 2>&1" || log_error "npm update failed or timed out"
        fi
        [[ $? -eq 0 ]] && log_success "npm updated"
        
        log_info "Updating global npm packages..."
        if $VERBOSE; then
            run_with_timeout $NPM_TIMEOUT "npm update -g" || log_warning "Some npm packages failed to update"
        else
            run_with_timeout $NPM_TIMEOUT "npm update -g >/dev/null 2>&1" || log_warning "Some npm packages failed to update"
        fi
        [[ $? -eq 0 ]] && log_success "Global npm packages updated"
        
        # List outdated global packages
        log_info "Checking for outdated npm packages..."
        outdated=$(npm outdated -g --depth=0 2>/dev/null || true)
        if [[ -n "$outdated" ]]; then
            log_warning "Some npm packages may need manual update:"
            echo "$outdated"
        else
            log_success "All npm packages are up to date"
        fi
        
        if [[ "$CLEANUP" == true ]]; then
            log_info "Cleaning npm cache..."
            if $VERBOSE; then
                npm cache clean --force
            else
                npm cache clean --force >/dev/null 2>&1
            fi
            log_success "npm cache cleaned"
        fi
    fi
}

# Update Python packages
update_pip() {
    if [[ "$UPDATE_PIP" == true ]] && command_exists pip3; then
        log_section "Updating Python packages"

        # Check if we're in an externally managed environment (PEP 668)
        if pip3 --version 2>&1 | grep -q "python3.1[0-9]" && [[ "$OSTYPE" == "darwin"* ]]; then
            log_warning "Python environment is externally managed by Homebrew"
            log_info "Using --user flag for pip operations to avoid system package conflicts"
            PIP_USER_FLAG="--user"
        else
            PIP_USER_FLAG=""
        fi

        log_info "Updating pip itself..."
        if $VERBOSE; then
            run_with_timeout $PIP_TIMEOUT "pip3 install --upgrade $PIP_USER_FLAG pip" || {
                log_warning "Could not update pip (may be externally managed)"
            }
        else
            run_with_timeout $PIP_TIMEOUT "pip3 install --upgrade $PIP_USER_FLAG pip >/dev/null 2>&1" || {
                log_warning "Could not update pip (may be externally managed)"
            }
        fi

        log_info "Checking for outdated Python packages..."
        # Get list of outdated packages
        outdated=$(pip3 list --outdated --format=json 2>/dev/null | python3 -c "import sys, json; print(' '.join([p['name'] for p in json.load(sys.stdin)]))" 2>/dev/null || echo "")

        if [[ -n "$outdated" ]]; then
            log_info "Found outdated packages: $outdated"
            if [[ -n "$PIP_USER_FLAG" ]]; then
                log_info "Upgrading user packages..."
                if $VERBOSE; then
                    run_with_timeout $PIP_TIMEOUT "pip3 install --upgrade $PIP_USER_FLAG $outdated" || {
                        log_warning "Some packages could not be upgraded"
                    }
                else
                    run_with_timeout $PIP_TIMEOUT "pip3 install --upgrade $PIP_USER_FLAG $outdated >/dev/null 2>&1" || {
                        log_warning "Some packages could not be upgraded"
                    }
                fi
            else
                if $VERBOSE; then
                    run_with_timeout $PIP_TIMEOUT "pip3 install --upgrade $outdated" || log_warning "Some packages could not be upgraded"
                else
                    run_with_timeout $PIP_TIMEOUT "pip3 install --upgrade $outdated >/dev/null 2>&1" || log_warning "Some packages could not be upgraded"
                fi
            fi
            log_success "Python packages update completed"
        else
            log_success "All Python packages are up to date"
        fi

        if [[ "$CLEANUP" == true ]]; then
            log_info "Cleaning pip cache..."
            if $VERBOSE; then
                pip3 cache purge 2>/dev/null && log_success "pip cache cleaned" || log_warning "Could not clean pip cache"
            else
                pip3 cache purge >/dev/null 2>&1 && log_success "pip cache cleaned" || true
            fi
        fi
    fi
}

# Update Ruby gems
update_gems() {
    if [[ "$UPDATE_GEM" == true ]] && command_exists gem; then
        log_section "Updating Ruby gems"

        # Check Ruby installation source
        ruby_path=$(which ruby)
        gem_path=$(which gem)

        # Check if using Homebrew Ruby (in /opt/homebrew or /usr/local)
        if [[ "$ruby_path" == "/opt/homebrew/"* ]] || [[ "$ruby_path" == "/usr/local/"* ]]; then
            log_info "Using Homebrew Ruby at: $ruby_path"
        elif [[ "$ruby_path" == "$HOME/.rbenv/"* ]] || [[ "$ruby_path" == "$HOME/.rvm/"* ]]; then
            log_info "Using managed Ruby (rbenv/rvm) at: $ruby_path"
        elif [[ "$ruby_path" == "/usr/bin/ruby" ]] || [[ "$ruby_path" == "/System/"* ]]; then
            log_warning "Using system Ruby - skipping gem updates (requires sudo)"
            log_info "Consider installing Ruby via Homebrew: brew install ruby"
            log_info "Or use a Ruby version manager like rbenv or rvm"
            return
        fi

        log_info "Updating RubyGems system (non-interactive)..."
        if $VERBOSE; then
            run_with_timeout $GEM_TIMEOUT "gem update --system --no-document" || {
                log_warning "Could not update RubyGems system (check permissions or use rbenv/rvm)"
            }
        else
            run_with_timeout $GEM_TIMEOUT "gem update --system --no-document >/dev/null 2>&1" || {
                log_warning "Could not update RubyGems system (check permissions)"
            }
        fi

        log_info "Updating installed gems (non-interactive)..."
        if $VERBOSE; then
            run_with_timeout $GEM_TIMEOUT "gem update --user-install --no-document 2>/dev/null || gem update --no-document 2>/dev/null" || {
                log_warning "Could not update gems (check permissions)"
            }
        else
            run_with_timeout $GEM_TIMEOUT "gem update --user-install --no-document >/dev/null 2>&1 || gem update --no-document >/dev/null 2>&1" || {
                log_warning "Could not update gems"
            }
        fi

        if [[ "$CLEANUP" == true ]]; then
            log_info "Cleaning up old gem versions..."
            if $VERBOSE; then
                gem cleanup --user-install 2>/dev/null || gem cleanup 2>/dev/null || {
                    log_warning "Could not clean up old gems"
                }
            else
                gem cleanup --user-install >/dev/null 2>&1 || gem cleanup >/dev/null 2>&1 || true
            fi
            [[ $? -eq 0 ]] && log_success "Old gem versions cleaned"
        fi

        log_success "Ruby gems update completed"
    fi
}

# Update Composer packages
update_composer() {
    if [[ "$UPDATE_COMPOSER" == true ]] && command_exists composer; then
        log_section "Updating Composer packages"

        log_info "Updating Composer itself (non-interactive)..."
        if $VERBOSE; then
            run_with_timeout $COMPOSER_TIMEOUT "composer self-update --no-interaction" || log_warning "Could not update Composer"
        else
            run_with_timeout $COMPOSER_TIMEOUT "composer self-update --no-interaction >/dev/null 2>&1" || log_warning "Could not update Composer"
        fi

        log_info "Updating global Composer packages (non-interactive)..."
        if $VERBOSE; then
            run_with_timeout $COMPOSER_TIMEOUT "composer global update --no-interaction" || log_warning "Could not update global Composer packages"
        else
            run_with_timeout $COMPOSER_TIMEOUT "composer global update --no-interaction >/dev/null 2>&1" || log_warning "Could not update global Composer packages"
        fi

        if [[ "$CLEANUP" == true ]]; then
            log_info "Clearing Composer cache..."
            if $VERBOSE; then
                composer clear-cache && log_success "Composer cache cleared" || log_warning "Could not clear Composer cache"
            else
                composer clear-cache >/dev/null 2>&1 && log_success "Composer cache cleared" || true
            fi
        fi

        log_success "Composer update completed"
    fi
}

# Update Rust and cargo packages
update_rust() {
    if [[ "$UPDATE_RUST" == true ]] && command_exists rustup; then
        log_section "Updating Rust"

        log_info "Updating Rust toolchain..."
        if $VERBOSE; then
            rustup update && log_success "Rust toolchain updated" || log_warning "Could not update Rust toolchain"
        else
            rustup update >/dev/null 2>&1 && log_success "Rust toolchain updated" || log_warning "Could not update Rust toolchain"
        fi

        if command_exists cargo-install-update; then
            log_info "Updating cargo packages..."
            if $VERBOSE; then
                cargo install-update -a && log_success "Cargo packages updated" || log_warning "Could not update cargo packages"
            else
                cargo install-update -a >/dev/null 2>&1 && log_success "Cargo packages updated" || log_warning "Could not update cargo packages"
            fi
        else
            log_warning "cargo-update not installed. Install with: cargo install cargo-update"
        fi
    fi
}

# Update Go packages
update_go() {
    if [[ "$UPDATE_GO" == true ]] && command_exists go; then
        log_section "Updating Go packages"
        
        log_info "Updating Go modules..."
        if [[ -d "$HOME/go/bin" ]]; then
            for binary in "$HOME/go/bin"/*; do
                if [[ -f "$binary" ]]; then
                    binary_name=$(basename "$binary")
                    log_info "Checking $binary_name..."
                    # This is a simplified approach - ideally we'd track the import paths
                    # For now, we'll just notify the user
                fi
            done
            log_warning "Go binaries found. Consider updating them manually with 'go install package@latest'"
        else
            log_success "No Go binaries found in GOPATH"
        fi
    fi
}

# Update macOS system
update_macos() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_section "Checking macOS Updates"
        
        log_info "Checking for macOS software updates..."
        updates=$(softwareupdate -l 2>/dev/null | grep -c "^   \*" || echo "0")
        updates="${updates//[^0-9]/}"  # Remove any non-numeric characters

        if [[ -n "$updates" && "$updates" -gt 0 ]]; then
            log_warning "macOS updates available. Run 'softwareupdate -ia' to install"
        else
            log_success "macOS is up to date"
        fi
    fi
}

# Update Oh My Zsh
update_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_section "Updating Oh My Zsh"
        
        log_info "Updating Oh My Zsh (non-interactive)..."
        # Set RUNZSH=no to prevent interactive shell launch
        if $VERBOSE; then
            run_with_timeout 60 "RUNZSH=no ZSH=\"$HOME/.oh-my-zsh\" sh \"$HOME/.oh-my-zsh/tools/upgrade.sh\"" || log_warning "Oh My Zsh update failed or timed out"
        else
            run_with_timeout 60 "RUNZSH=no ZSH=\"$HOME/.oh-my-zsh\" sh \"$HOME/.oh-my-zsh/tools/upgrade.sh\" >/dev/null 2>&1" || log_warning "Oh My Zsh update failed or timed out"
        fi
        [[ $? -eq 0 ]] && log_success "Oh My Zsh updated"
    fi
}

# Update tmux plugins
update_tmux_plugins() {
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        log_section "Updating tmux plugins"
        
        log_info "Updating tmux plugins..."
        if command_exists tmux; then
            "$HOME/.tmux/plugins/tpm/bin/update_plugins" all >/dev/null 2>&1 || true
            log_success "tmux plugins updated"
        else
            log_warning "tmux not installed"
        fi
    fi
}

# Update Neovim plugins
update_neovim_plugins() {
    if command_exists nvim && [[ -d "$HOME/.config/nvim" ]]; then
        log_section "Updating Neovim plugins"
        
        log_info "Updating Neovim plugins..."
        if $VERBOSE; then
            nvim --headless "+Lazy! sync" +qa
        else
            nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || true
        fi
        log_success "Neovim plugins updated"
    fi
}

# Main execution
main() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                   Package Update Manager                   ║"
    echo "║                 Updating all package managers              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    start_time=$(date +%s)
    
    # Run updates
    update_homebrew
    update_npm
    update_pip
    update_gems
    update_composer
    update_rust
    update_go
    update_oh_my_zsh
    update_tmux_plugins
    update_neovim_plugins
    update_macos
    
    # Calculate execution time
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    minutes=$((duration / 60))
    seconds=$((duration % 60))
    
    echo ""
    if [[ "$HAS_ERRORS" == true ]]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}⚠ Updates completed with some errors or warnings${NC}"
        echo -e "${YELLOW}  Time taken: ${minutes}m ${seconds}s${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✓ All updates completed successfully!${NC}"
        echo -e "${GREEN}  Time taken: ${minutes}m ${seconds}s${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
    
    # Reminder
    echo ""
    log_info "Remember to:"
    echo "  • Restart your terminal for some changes to take effect"
    echo "  • Check for any manual updates mentioned above"
    echo "  • Review any warnings or errors"
    
    if [[ "$HAS_ERRORS" == true ]]; then
        echo ""
        log_warning "Script completed with errors. Review the output above for details."
        return 1
    fi
}

# Run main function
main