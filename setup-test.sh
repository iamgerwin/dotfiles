#!/usr/bin/env bash
# Test setup script - non-interactive version for testing

set -e

# Configuration
DOTFILES_REPO="https://github.com/iamgerwin/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_header() {
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

# Main test flow
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Dotfiles Test Installation          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo

print_info "Running in test mode - non-interactive"
echo

# Step 1: Backup existing configuration
print_header "Creating Backups"

if [[ -f "$DOTFILES_DIR/scripts/backup.sh" ]]; then
    bash "$DOTFILES_DIR/scripts/backup.sh"
    print_success "Backup completed"
else
    print_warning "Backup script not found, using simple backup"
    for file in .zshrc .gitconfig .tmux.conf .p10k.zsh; do
        if [[ -f "$HOME/$file" ]] && [[ ! -L "$HOME/$file" ]]; then
            cp "$HOME/$file" "$HOME/$file.backup.$(date +%Y%m%d_%H%M%S)"
            print_success "Backed up $file"
        fi
    done
fi

# Step 2: Create symbolic links
print_header "Creating Symbolic Links"

# Remove existing files/links
remove_existing() {
    local file="$1"
    if [[ -e "$file" ]] || [[ -L "$file" ]]; then
        if [[ ! -L "$file" ]] || [[ "$(readlink "$file")" != "$DOTFILES_DIR/$(basename "$file")" ]]; then
            rm -f "$file"
            return 0
        fi
        return 1
    fi
    return 0
}

# Create .zshrc symlink
if remove_existing "$HOME/.zshrc"; then
    ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    print_success "Linked .zshrc"
else
    print_info ".zshrc already linked"
fi

# Create .p10k.zsh symlink
if [[ -f "$DOTFILES_DIR/p10k.zsh" ]]; then
    if remove_existing "$HOME/.p10k.zsh"; then
        ln -sf "$DOTFILES_DIR/p10k.zsh" "$HOME/.p10k.zsh"
        print_success "Linked .p10k.zsh"
    else
        print_info ".p10k.zsh already linked"
    fi
fi

# Step 3: Check if everything is working
print_header "Verification"

# Check symlinks
if [[ -L "$HOME/.zshrc" ]]; then
    target=$(readlink "$HOME/.zshrc")
    if [[ "$target" == "$DOTFILES_DIR/.zshrc" ]]; then
        print_success ".zshrc correctly linked to $target"
    else
        print_error ".zshrc linked to wrong location: $target"
    fi
else
    print_error ".zshrc is not a symlink"
fi

# Check if .zshrc.local exists
if [[ -f "$HOME/.zshrc.local" ]]; then
    print_success ".zshrc.local exists ($(wc -l < "$HOME/.zshrc.local" | tr -d ' ') lines)"
else
    print_warning ".zshrc.local not found - creating empty file"
    touch "$HOME/.zshrc.local"
fi

# Check if .zshrc.private exists
if [[ ! -f "$HOME/.zshrc.private" ]]; then
    touch "$HOME/.zshrc.private"
    print_success "Created .zshrc.private"
fi

# Test sourcing
print_header "Testing Configuration"

print_info "Attempting to source new .zshrc..."
if zsh -c "source $HOME/.zshrc" 2>/dev/null; then
    print_success "Configuration loads without errors"
else
    print_warning "Configuration may have issues - check manually"
fi

print_header "Installation Summary"

if [[ -f "$HOME/.dotfiles-backup/manifest.json" ]]; then
    print_success "Original configuration backed up to ~/.dotfiles-backup/"
fi

echo
print_info "Next steps:"
echo "  1. Run: source ~/.zshrc"
echo "  2. Check if your aliases work: alias | grep art"
echo "  3. If issues, rollback: ~/dotfiles/scripts/uninstall.sh restore"
echo
print_success "Test installation complete!"