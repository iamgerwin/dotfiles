#!/usr/bin/env bash
# Dotfiles Setup Script
# Automated installation and configuration for new machines

set -e  # Exit on error

# Configuration
DOTFILES_REPO="https://github.com/iamgerwin/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_header() {
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

# Check if running on macOS
check_os() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is intended for macOS only"
        exit 1
    fi
    print_success "Running on macOS"
}

# Install or update Homebrew
install_homebrew() {
    print_header "Homebrew Installation"
    
    if [[ -f "$DOTFILES_DIR/scripts/install-brew.sh" ]]; then
        bash "$DOTFILES_DIR/scripts/install-brew.sh"
    else
        # Fallback to direct installation if script not available
        if ! command -v brew &> /dev/null; then
            print_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add to PATH for Apple Silicon Macs
            if [[ -f "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        else
            print_success "Homebrew is already installed"
        fi
    fi
}

# Clone or update dotfiles repository
setup_dotfiles() {
    print_header "Dotfiles Repository Setup"
    
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        print_info "Updating existing dotfiles repository..."
        cd "$DOTFILES_DIR"
        git pull origin main
        print_success "Dotfiles updated"
    else
        if [[ -d "$DOTFILES_DIR" ]]; then
            print_info "Backing up existing dotfiles directory..."
            mv "$DOTFILES_DIR" "$DOTFILES_DIR.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        print_info "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        print_success "Dotfiles cloned successfully"
    fi
    
    # Make scripts executable
    chmod +x "$DOTFILES_DIR/scripts/"*.sh 2>/dev/null || true
}

# Install Homebrew packages from Brewfile
install_packages() {
    print_header "Package Installation"
    
    if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
        print_info "Installing packages from Brewfile..."
        cd "$DOTFILES_DIR"
        brew bundle install
        print_success "All packages installed"
    else
        print_error "Brewfile not found at $DOTFILES_DIR/Brewfile"
    fi
}

# Backup existing configuration
backup_existing() {
    print_header "Backing Up Existing Configuration"
    
    if [[ -f "$DOTFILES_DIR/scripts/backup.sh" ]]; then
        bash "$DOTFILES_DIR/scripts/backup.sh"
        print_success "Backup completed"
    else
        print_info "Backup script not found, using simple backup"
        # Fallback to simple backup
        for file in .zshrc .gitconfig .tmux.conf; do
            if [[ -f "$HOME/$file" ]] && [[ ! -L "$HOME/$file" ]]; then
                cp "$HOME/$file" "$HOME/$file.backup.$(date +%Y%m%d_%H%M%S)"
                print_success "Backed up $file"
            fi
        done
    fi
}

# Create symbolic links
create_symlinks() {
    print_header "Creating Symbolic Links"
    
    # Remove existing files/links
    remove_existing() {
        local file="$1"
        if [[ -e "$file" ]] || [[ -L "$file" ]]; then
            if [[ ! -L "$file" ]] || [[ "$(readlink "$file")" != "$DOTFILES_DIR/$(basename "$file")" ]]; then
                rm -f "$file"
            fi
        fi
    }
    
    # Create .zshrc symlink
    remove_existing "$HOME/.zshrc"
    ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    print_success "Linked .zshrc"
    
    # Create .gitconfig symlink if it exists
    if [[ -f "$DOTFILES_DIR/.gitconfig" ]]; then
        remove_existing "$HOME/.gitconfig"
        ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
        print_success "Linked .gitconfig"
    fi
    
    # Create .tmux.conf symlink if it exists
    if [[ -f "$DOTFILES_DIR/.tmux.conf" ]]; then
        remove_existing "$HOME/.tmux.conf"
        ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
        print_success "Linked .tmux.conf"
    fi
}

# Configure Git
configure_git() {
    print_header "Git Configuration"
    
    read -p "Enter your Git username: " git_username
    read -p "Enter your Git email: " git_email
    
    if [[ -n "$git_username" ]]; then
        git config --global user.name "$git_username"
        print_success "Git username set to: $git_username"
    fi
    
    if [[ -n "$git_email" ]]; then
        git config --global user.email "$git_email"
        print_success "Git email set to: $git_email"
    fi
}

# Setup Oh My Zsh (optional)
setup_oh_my_zsh() {
    print_header "Oh My Zsh Setup (Optional)"
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_success "Oh My Zsh is already installed"
    else
        read -p "Do you want to install Oh My Zsh? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installing Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            print_success "Oh My Zsh installed"
            
            # Install popular plugins
            print_info "Installing zsh plugins..."
            
            # zsh-autosuggestions
            if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
                git clone https://github.com/zsh-users/zsh-autosuggestions \
                    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
                print_success "Installed zsh-autosuggestions"
            fi
            
            # zsh-syntax-highlighting
            if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
                git clone https://github.com/zsh-users/zsh-syntax-highlighting \
                    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
                print_success "Installed zsh-syntax-highlighting"
            fi
        fi
    fi
}

# Final setup steps
final_setup() {
    print_header "Final Setup"
    
    # Make scripts executable
    chmod +x "$DOTFILES_DIR/setup.sh"
    chmod +x "$DOTFILES_DIR/scripts/"*.sh 2>/dev/null || true
    
    # Create local config files if they don't exist
    touch "$HOME/.zshrc.local"
    touch "$HOME/.zshrc.private"
    
    print_success "Created local configuration files"
}

# Main installation flow
main() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       Dotfiles Setup & Installation    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo
    
    check_os
    setup_dotfiles
    backup_existing
    install_homebrew
    install_packages
    create_symlinks
    configure_git
    setup_oh_my_zsh
    final_setup
    
    print_header "Installation Complete!"
    
    echo "Your development environment has been set up successfully!"
    echo
    print_info "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. Customize ~/.zshrc.local for machine-specific settings"
    echo "  3. Add sensitive data to ~/.zshrc.private (not tracked by git)"
    echo
    print_info "Useful commands:"
    echo "  • Update packages: brew update && brew upgrade"
    echo "  • Sync dotfiles: cd ~/dotfiles && git pull"
    echo "  • Update Brewfile: brew bundle dump --force --file=~/dotfiles/Brewfile"
    echo "  • Uninstall dotfiles: ~/dotfiles/scripts/uninstall.sh"
    echo "  • View backups: ~/dotfiles/scripts/backup.sh list"
    echo
    print_success "Happy coding! 🚀"
}

# Run main function
main "$@"