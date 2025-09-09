#!/usr/bin/env bash
# Backup Script - Creates backups of existing configurations before installation
# Maintains a backup manifest for easy restoration

set -e

# Configuration
BACKUP_DIR="$HOME/.dotfiles-backup"
MANIFEST_FILE="$BACKUP_DIR/manifest.json"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Create backup directory structure
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        print_success "Created backup directory: $BACKUP_DIR"
    fi
    
    # Create timestamped subdirectory for this backup
    CURRENT_BACKUP="$BACKUP_DIR/$TIMESTAMP"
    mkdir -p "$CURRENT_BACKUP"
}

# Initialize or update manifest
init_manifest() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        echo '{
  "backups": [],
  "current": null,
  "original": null
}' > "$MANIFEST_FILE"
        print_success "Initialized backup manifest"
    fi
}

# Backup a file or directory
backup_item() {
    local source="$1"
    local item_name="$(basename "$source")"
    
    if [[ -e "$source" ]] || [[ -L "$source" ]]; then
        # Check if it's a symlink to our dotfiles
        if [[ -L "$source" ]] && [[ "$(readlink "$source")" == *"/dotfiles/"* ]]; then
            print_info "Skipping $item_name (already linked to dotfiles)"
            return 0
        fi
        
        # Create backup
        cp -RPp "$source" "$CURRENT_BACKUP/$item_name"
        print_success "Backed up: $item_name"
        
        # Record in manifest using temporary file
        local temp_manifest=$(mktemp)
        jq --arg ts "$TIMESTAMP" \
           --arg item "$item_name" \
           --arg path "$source" \
           --arg backup "$CURRENT_BACKUP/$item_name" \
           '.backups += [{
               "timestamp": $ts,
               "item": $item,
               "original_path": $path,
               "backup_path": $backup
           }]' "$MANIFEST_FILE" > "$temp_manifest"
        mv "$temp_manifest" "$MANIFEST_FILE"
        
        return 0
    else
        print_info "No existing $item_name found to backup"
        return 1
    fi
}

# Backup all dotfiles
backup_dotfiles() {
    print_info "Starting backup process..."
    
    create_backup_dir
    init_manifest
    
    # List of files to backup
    local files_to_backup=(
        "$HOME/.zshrc"
        "$HOME/.zprofile"
        "$HOME/.bash_profile"
        "$HOME/.bashrc"
        "$HOME/.gitconfig"
        "$HOME/.tmux.conf"
        "$HOME/.vimrc"
        "$HOME/.oh-my-zsh"
    )
    
    local backed_up=0
    for file in "${files_to_backup[@]}"; do
        if backup_item "$file"; then
            ((backed_up++))
        fi
    done
    
    # Update manifest with current backup info
    local temp_manifest=$(mktemp)
    jq --arg ts "$TIMESTAMP" \
       --arg dir "$CURRENT_BACKUP" \
       '.current = {
           "timestamp": $ts,
           "directory": $dir,
           "items_backed_up": (.backups | map(select(.timestamp == $ts)) | length)
       }' "$MANIFEST_FILE" > "$temp_manifest"
    mv "$temp_manifest" "$MANIFEST_FILE"
    
    if [[ $backed_up -gt 0 ]]; then
        print_success "Backup completed: $backed_up items backed up"
        print_info "Backup location: $CURRENT_BACKUP"
    else
        print_info "No files needed backing up"
    fi
}

# List available backups
list_backups() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        print_error "No backups found"
        return 1
    fi
    
    echo "Available backups:"
    echo
    jq -r '.backups | group_by(.timestamp) | .[] | 
        "\(.[0].timestamp): \(length) item(s) backed up"' "$MANIFEST_FILE"
}

# Get latest backup timestamp
get_latest_backup() {
    if [[ -f "$MANIFEST_FILE" ]]; then
        jq -r '.current.timestamp // empty' "$MANIFEST_FILE"
    fi
}

# Main execution
main() {
    case "${1:-}" in
        list)
            list_backups
            ;;
        latest)
            get_latest_backup
            ;;
        *)
            backup_dotfiles
            ;;
    esac
}

main "$@"