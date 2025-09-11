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
                export PATH="/opt/homebrew/bin:$PATH"
            elif [[ -f "/usr/local/bin/brew" ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
                export PATH="/usr/local/bin:$PATH"
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
        
        # Ensure Homebrew is in PATH
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            export PATH="/opt/homebrew/bin:$PATH"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            export PATH="/usr/local/bin:$PATH"
        fi
        
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
    
    # Create .p10k.zsh symlink if it exists
    if [[ -f "$DOTFILES_DIR/p10k.zsh" ]]; then
        remove_existing "$HOME/.p10k.zsh"
        ln -sf "$DOTFILES_DIR/p10k.zsh" "$HOME/.p10k.zsh"
        print_success "Linked .p10k.zsh"
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
            
            # Install Powerlevel10k theme
            print_info "Installing Powerlevel10k theme..."
            if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
                git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
                    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
                print_success "Installed Powerlevel10k theme"
            else
                print_success "Powerlevel10k theme already installed"
            fi
            
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

# Change default shell to Homebrew Zsh
setup_shell() {
    print_header "Shell Configuration"
    
    # Determine correct Zsh path
    local ZSH_PATH=""
    if [[ -f "/opt/homebrew/bin/zsh" ]]; then
        ZSH_PATH="/opt/homebrew/bin/zsh"
    elif [[ -f "/usr/local/bin/zsh" ]]; then
        ZSH_PATH="/usr/local/bin/zsh"
    else
        print_warning "Homebrew Zsh not found, using system Zsh"
        ZSH_PATH="/bin/zsh"
    fi
    
    # Check if Zsh is in /etc/shells
    if ! grep -q "$ZSH_PATH" /etc/shells; then
        print_info "Adding $ZSH_PATH to /etc/shells..."
        echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
        print_success "Added $ZSH_PATH to /etc/shells"
    fi
    
    # Change default shell if not already set
    if [[ "$SHELL" != "$ZSH_PATH" ]]; then
        print_info "Changing default shell to $ZSH_PATH..."
        if chsh -s "$ZSH_PATH"; then
            print_success "Default shell changed to $ZSH_PATH"
            print_info "Please restart your terminal for the change to take effect"
        else
            print_warning "Could not change default shell automatically"
            print_info "Run this command manually: chsh -s $ZSH_PATH"
        fi
    else
        print_success "Shell is already set to $ZSH_PATH"
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
    
    # Setup tmux if installed
    if command -v tmux &> /dev/null; then
        print_info "Setting up tmux configuration..."
        if [[ -x "$DOTFILES_DIR/scripts/setup-tmux.sh" ]]; then
            "$DOTFILES_DIR/scripts/setup-tmux.sh"
        fi
    fi
}

# Check for existing configuration
check_existing_config() {
    print_header "Checking Existing Configuration"
    
    if [[ -f "$HOME/.zshrc" ]] && [[ ! -L "$HOME/.zshrc" ]]; then
        print_warning "Found existing .zshrc configuration"
        echo
        echo "Your current .zshrc contains $(wc -l < "$HOME/.zshrc" | tr -d ' ') lines"
        echo
        echo "What would you like to do?"
        echo "  1) Adaptive setup - Preserve all customizations (recommended)"
        echo "  2) Standard setup - Backup and replace"
        echo "  3) View existing .zshrc first"
        echo "  4) Cancel installation"
        echo
        read -p "Enter choice [1-4]: " choice
        
        case $choice in
            1)
                print_info "Running adaptive setup..."
                if [[ -f "$DOTFILES_DIR/scripts/adaptive-setup.sh" ]]; then
                    bash "$DOTFILES_DIR/scripts/adaptive-setup.sh"
                    print_success "Adaptive setup complete!"
                    echo
                    print_info "Your customizations have been preserved."
                    print_info "Run 'source ~/.zshrc' to reload your configuration."
                    exit 0
                else
                    print_warning "Adaptive setup script not found, using standard setup"
                    print_info "Proceeding with backup..."
                fi
                ;;
            2)
                print_info "Proceeding with standard setup (backup and replace)..."
                ;;
            3)
                less "$HOME/.zshrc"
                echo
                read -p "Continue with installation? (y/n) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    print_info "Installation cancelled"
                    exit 0
                fi
                ;;
            4)
                print_info "Installation cancelled"
                print_info "To preserve custom settings before installing:"
                echo "  1. Run adaptive setup: ~/dotfiles/scripts/adaptive-setup.sh"
                echo "  2. Or manually copy to ~/.zshrc.local"
                exit 0
                ;;
            *)
                print_error "Invalid choice"
                exit 1
                ;;
        esac
    else
        print_success "No existing .zshrc found or already using dotfiles"
    fi
}

# Main installation flow
main() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       Dotfiles Setup & Installation    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo
    
    print_info "This setup will:"
    echo "  • Backup any existing configuration files"
    echo "  • Install required dependencies"
    echo "  • Create symlinks to dotfiles"
    echo "  • Configure your development environment"
    echo
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    check_os
    check_existing_config
    setup_dotfiles
    backup_existing
    install_homebrew
    install_packages
    create_symlinks
    setup_shell
    configure_git
    setup_oh_my_zsh
    final_setup
    
    print_header "Installation Complete!"
    
    echo "Your development environment has been set up successfully!"
    echo
    
    if [[ -f "$HOME/.dotfiles-backup/manifest.json" ]]; then
        print_success "Your original configuration has been backed up"
        echo "  Location: ~/.dotfiles-backup/"
        echo "  Restore: ~/dotfiles/scripts/uninstall.sh restore"
        echo
    fi
    
    print_info "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. Customize ~/.zshrc.local for machine-specific settings"
    echo "  3. Add sensitive data to ~/.zshrc.private (not tracked by git)"
    echo
    # Check for Nerd Font
    if ! ls ~/Library/Fonts 2>/dev/null | grep -qi "meslo.*nerd"; then
        print_warning "Terminal font not installed!"
        echo "  Install with: brew install --cask font-meslo-lg-nerd-font"
        echo "  Then set your terminal font to: MesloLGS NF"
        echo "  See TERMINAL_SETUP.md for details"
        echo
    fi
    
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