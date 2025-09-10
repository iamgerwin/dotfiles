#!/usr/bin/env bash
# Uninstall Script - Removes dotfiles setup and restores original configurations
# Provides safe rollback to previous configuration state

set -e

# Configuration
DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup"
MANIFEST_FILE="$BACKUP_DIR/manifest.json"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

# Check for backups
check_backups() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        print_error "No backup manifest found at $MANIFEST_FILE"
        return 1
    fi
    
    local latest_backup=$(jq -r '.current.timestamp // empty' "$MANIFEST_FILE")
    if [[ -z "$latest_backup" ]]; then
        print_error "No backups found to restore"
        return 1
    fi
    
    echo "$latest_backup"
}

# Remove symlinks
remove_symlinks() {
    print_header "Removing Dotfiles Symlinks"
    
    local links_to_remove=(
        "$HOME/.zshrc"
        "$HOME/.gitconfig"
        "$HOME/.tmux.conf"
        "$HOME/.vimrc"
    )
    
    for link in "${links_to_remove[@]}"; do
        if [[ -L "$link" ]] && [[ "$(readlink "$link")" == *"$DOTFILES_DIR"* ]]; then
            rm "$link"
            print_success "Removed symlink: $(basename "$link")"
        fi
    done
}

# Restore from backup
restore_backups() {
    local timestamp="$1"
    
    print_header "Restoring Original Configuration"
    
    if [[ -z "$timestamp" ]]; then
        print_error "No backup timestamp provided"
        return 1
    fi
    
    # Get all backups for this timestamp
    local backup_items=$(jq -r --arg ts "$timestamp" \
        '.backups[] | select(.timestamp == $ts) | @json' "$MANIFEST_FILE")
    
    if [[ -z "$backup_items" ]]; then
        print_error "No backups found for timestamp: $timestamp"
        return 1
    fi
    
    # Restore each item
    while IFS= read -r item_json; do
        local item=$(echo "$item_json" | jq -r '.')
        local original_path=$(echo "$item" | jq -r '.original_path')
        local backup_path=$(echo "$item" | jq -r '.backup_path')
        local item_name=$(echo "$item" | jq -r '.item')
        
        if [[ -f "$backup_path" ]] || [[ -d "$backup_path" ]]; then
            # Remove existing file/directory if it exists
            if [[ -e "$original_path" ]] || [[ -L "$original_path" ]]; then
                rm -rf "$original_path"
            fi
            
            # Restore from backup
            cp -RPp "$backup_path" "$original_path"
            print_success "Restored: $item_name"
        else
            print_error "Backup not found: $backup_path"
        fi
    done <<< "$backup_items"
}

# Remove dotfiles repository
remove_repository() {
    print_header "Removing Dotfiles Repository"
    
    read -p "Do you want to remove the dotfiles repository? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -d "$DOTFILES_DIR" ]]; then
            rm -rf "$DOTFILES_DIR"
            print_success "Removed dotfiles repository"
        fi
    else
        print_info "Keeping dotfiles repository at $DOTFILES_DIR"
    fi
}

# Clean up backup files
cleanup_backups() {
    print_header "Backup Cleanup"
    
    read -p "Do you want to remove all backup files? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -d "$BACKUP_DIR" ]]; then
            rm -rf "$BACKUP_DIR"
            print_success "Removed all backups"
        fi
    else
        print_info "Keeping backups at $BACKUP_DIR"
    fi
}

# List packages that would be removed
list_packages() {
    print_header "Installed Packages"
    
    if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
        print_info "The following packages were installed from Brewfile:"
        echo
        grep -E '^(brew|cask)' "$DOTFILES_DIR/Brewfile" | sed 's/^/  - /'
        echo
        print_info "To remove these packages, run: brew bundle cleanup --force"
    fi
}

# Main uninstall process
uninstall() {
    clear
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║     Dotfiles Uninstall & Rollback     ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo
    
    print_info "This will remove the dotfiles setup and restore your original configuration"
    echo
    read -p "Are you sure you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninstall cancelled"
        exit 0
    fi
    
    # Check for backups
    local latest_backup=$(check_backups)
    if [[ $? -eq 0 ]] && [[ -n "$latest_backup" ]]; then
        print_success "Found backup from: $latest_backup"
        
        # Remove current symlinks
        remove_symlinks
        
        # Restore from backup
        restore_backups "$latest_backup"
    else
        print_info "No backups found - will only remove symlinks"
        remove_symlinks
    fi
    
    # List installed packages
    list_packages
    
    # Remove repository
    remove_repository
    
    # Cleanup backups
    cleanup_backups
    
    print_header "Uninstall Complete"
    
    print_success "Dotfiles setup has been removed"
    print_info "Please restart your terminal for changes to take effect"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        print_info "Backups are still available at: $BACKUP_DIR"
    fi
}

# Quick restore (without full uninstall)
quick_restore() {
    local timestamp="${1:-}"
    
    if [[ -z "$timestamp" ]]; then
        timestamp=$(check_backups)
    fi
    
    if [[ -n "$timestamp" ]]; then
        print_header "Quick Restore from Backup"
        print_info "Restoring from: $timestamp"
        
        remove_symlinks
        restore_backups "$timestamp"
        
        print_success "Configuration restored"
        print_info "Run 'source ~/.zshrc' to reload your shell"
    else
        print_error "No backup found to restore"
        exit 1
    fi
}

# Restore tmux configuration specifically
restore_tmux() {
    local backup_dir="${1:-}"
    
    print_header "Restoring Tmux Configuration"
    
    # Find tmux backup directory if not specified
    if [[ -z "$backup_dir" ]]; then
        backup_dir=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "tmux-*" | sort -r | head -n1)
    fi
    
    if [[ ! -d "$backup_dir" ]]; then
        print_error "No tmux backup found"
        return 1
    fi
    
    print_info "Restoring from: $backup_dir"
    
    # Remove current tmux setup
    if [[ -L "$HOME/.tmux.conf" ]]; then
        rm "$HOME/.tmux.conf"
        print_success "Removed tmux.conf symlink"
    fi
    
    # Restore original tmux.conf if it exists
    if [[ -f "$backup_dir/.tmux.conf.backup" ]]; then
        cp -P "$backup_dir/.tmux.conf.backup" "$HOME/.tmux.conf"
        print_success "Restored original .tmux.conf"
    fi
    
    # Restore .tmux directory if it exists
    if [[ -d "$backup_dir/.tmux.backup" ]]; then
        rm -rf "$HOME/.tmux"
        cp -r "$backup_dir/.tmux.backup" "$HOME/.tmux"
        print_success "Restored original .tmux directory"
    fi
    
    # Kill tmux server to apply changes
    if command -v tmux &> /dev/null && tmux list-sessions &> /dev/null; then
        print_info "Killing tmux server to apply changes..."
        tmux kill-server
    fi
    
    print_success "Tmux configuration restored"
}

# Main execution
main() {
    case "${1:-}" in
        restore)
            quick_restore "${2:-}"
            ;;
        restore-tmux)
            restore_tmux "${2:-}"
            ;;
        list)
            if [[ -f "$MANIFEST_FILE" ]]; then
                jq -r '.backups | group_by(.timestamp) | .[] | 
                    "\(.[0].timestamp): \(length) item(s)"' "$MANIFEST_FILE"
            else
                print_error "No backups found"
            fi
            # Also list tmux-specific backups
            echo
            print_info "Tmux-specific backups:"
            find "$BACKUP_DIR" -maxdepth 1 -type d -name "tmux-*" 2>/dev/null | while read -r dir; do
                echo "  - $(basename "$dir")"
            done || echo "  None found"
            ;;
        *)
            uninstall
            ;;
    esac
}

main "$@"