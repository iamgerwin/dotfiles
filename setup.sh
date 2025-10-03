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
    if [[ -f "$DOTFILES_DIR/tmux.conf" ]]; then
        remove_existing "$HOME/.tmux.conf"
        ln -sf "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
        print_success "Linked .tmux.conf"
    elif [[ -f "$DOTFILES_DIR/.tmux.conf" ]]; then
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

    # Check if git profiles are available
    if [[ -x "$DOTFILES_DIR/scripts/git-profile-manager" ]]; then
        print_info "Git Profile Management system detected!"
        echo
        echo "You can manage multiple Git identities (personal, work, etc.)"
        echo "with SSH keys and GitHub CLI integration."
        echo

        # Check if there's existing Git config or SSH keys to import
        local has_existing_config=false
        if [[ -n "$(git config --global user.name 2>/dev/null)" ]] || [[ -n "$(git config --global user.email 2>/dev/null)" ]]; then
            has_existing_config=true
        fi

        local has_ssh_keys=false
        if [[ -d "$HOME/.ssh" ]]; then
            for key in "$HOME/.ssh"/*; do
                if [[ -f "$key" ]] && [[ ! "$key" =~ \.pub$ ]] && [[ ! "$key" =~ known_hosts|authorized_keys|config$ ]]; then
                    if head -n 1 "$key" 2>/dev/null | grep -q "PRIVATE KEY"; then
                        has_ssh_keys=true
                        break
                    fi
                fi
            done
        fi

        if [[ "$has_existing_config" == "true" ]] || [[ "$has_ssh_keys" == "true" ]]; then
            print_warning "Existing Git configuration and/or SSH keys detected!"
            echo "What would you like to do?"
            echo "  1) Import existing configuration and SSH keys"
            echo "  2) Create a new profile from scratch"
            echo "  3) Skip for now"
            echo
            read -p "Enter choice [1-3]: " git_choice

            case $git_choice in
                1)
                    print_info "Importing existing configuration..."
                    if [[ -x "$DOTFILES_DIR/scripts/import-git-profiles" ]]; then
                        "$DOTFILES_DIR/scripts/import-git-profiles"
                    else
                        print_warning "Import script not found, using manual migration"
                        "$DOTFILES_DIR/scripts/ssh-key-manager" migrate
                    fi
                    ;;
                2)
                    print_info "Launching Git Profile Manager..."
                    "$DOTFILES_DIR/scripts/git-profile-manager" create
                    ;;
                3)
                    print_info "You can import or create profiles later with:"
                    echo "  Import: ~/dotfiles/scripts/import-git-profiles"
                    echo "  Create: gpm create"
                    ;;
                *)
                    print_warning "Invalid choice, skipping..."
                    ;;
            esac
        else
            read -p "Would you like to set up a Git profile now? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_info "Launching Git Profile Manager..."
                "$DOTFILES_DIR/scripts/git-profile-manager" create
            else
                print_info "You can set up profiles later with: gpm create"
            fi
        fi
    else
        # Standard git configuration when git-profile-manager is not available
        print_info "Git Profile Manager not found. Using standard configuration."
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
            local P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
            if [[ ! -d "$P10K_DIR" ]]; then
                if git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"; then
                    print_success "Installed Powerlevel10k theme"
                    # Verify the theme file exists
                    if [[ -f "$P10K_DIR/powerlevel10k.zsh-theme" ]]; then
                        print_success "Powerlevel10k theme file verified"
                    else
                        print_error "Powerlevel10k theme file not found after installation"
                    fi
                else
                    print_error "Failed to install Powerlevel10k theme"
                    print_info "You can install it manually later with:"
                    echo "  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $P10K_DIR"
                fi
            else
                print_success "Powerlevel10k theme already installed"
                # Verify the existing installation
                if [[ -f "$P10K_DIR/powerlevel10k.zsh-theme" ]]; then
                    print_success "Existing Powerlevel10k installation verified"
                else
                    print_warning "Powerlevel10k directory exists but theme file is missing"
                    print_info "Removing incomplete installation and reinstalling..."
                    rm -rf "$P10K_DIR"
                    if git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"; then
                        print_success "Reinstalled Powerlevel10k theme"
                    else
                        print_error "Failed to reinstall Powerlevel10k theme"
                    fi
                fi
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
    chmod +x "$DOTFILES_DIR/scripts/git-profile-switch" 2>/dev/null || true
    chmod +x "$DOTFILES_DIR/scripts/git-profile-manager" 2>/dev/null || true
    chmod +x "$DOTFILES_DIR/scripts/ssh-key-manager" 2>/dev/null || true
    chmod +x "$DOTFILES_DIR/scripts/import-git-profiles" 2>/dev/null || true
    
    # Create local config files if they don't exist
    touch "$HOME/.zshrc.local"
    touch "$HOME/.zshrc.private"
    
    print_success "Created local configuration files"
    
    # Setup tmux if installed
    if command -v tmux &> /dev/null; then
        print_info "Setting up tmux configuration..."

        # Install Tmux Plugin Manager (TPM) if not already installed
        if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
            print_info "Installing Tmux Plugin Manager..."
            git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
            print_success "TPM installed"
            print_info "Note: Press Ctrl-a + I inside tmux to install plugins"
        else
            print_success "TPM already installed"
        fi

        if [[ -x "$DOTFILES_DIR/scripts/setup-tmux.sh" ]]; then
            "$DOTFILES_DIR/scripts/setup-tmux.sh"
        fi
    fi

    # Setup Neovim if installed
    if command -v nvim &> /dev/null; then
        print_info "Setting up Neovim configuration..."
        if [[ -x "$DOTFILES_DIR/scripts/setup-neovim.sh" ]]; then
            "$DOTFILES_DIR/scripts/setup-neovim.sh"
        else
            # Fallback to basic symlink if script not available
            if [[ -d "$DOTFILES_DIR/nvim" ]]; then
                mkdir -p "$HOME/.config"
                if [[ ! -e "$HOME/.config/nvim" ]]; then
                    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
                    print_success "Linked Neovim configuration"
                elif [[ -L "$HOME/.config/nvim" ]] && [[ "$(readlink "$HOME/.config/nvim")" == "$DOTFILES_DIR/nvim" ]]; then
                    print_success "Neovim configuration already linked"
                else
                    print_warning "Existing Neovim configuration found at ~/.config/nvim"
                    print_info "Run ~/dotfiles/scripts/setup-neovim.sh for safe migration"
                fi
            fi
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

    # Optional Ruby and Rails setup
    print_header "Optional: Ruby & Rails Setup"
    print_info "Would you like to set up Ruby and Rails development environment?"
    echo "  This will install:"
    echo "  • Ruby via rbenv (version manager)"
    echo "  • Latest stable Ruby version (3.3.6)"
    echo "  • Latest stable Rails version"
    echo "  • Required build dependencies"
    echo
    read -p "Install Ruby and Rails? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -x "$DOTFILES_DIR/ruby/setup.sh" ]]; then
            print_info "Running Ruby and Rails setup..."
            "$DOTFILES_DIR/ruby/setup.sh"
            print_success "Ruby and Rails setup complete!"
        else
            print_warning "Ruby setup script not found at $DOTFILES_DIR/ruby/setup.sh"
            print_info "You can run it manually later:"
            echo "  cd ~/dotfiles && ./ruby/setup.sh"
        fi
    else
        print_info "Skipping Ruby and Rails setup"
        print_info "You can run it later with: ~/dotfiles/ruby/setup.sh"
    fi
    echo

    # Optional Python, FastAPI, and Django setup
    print_header "Optional: Python, FastAPI & Django Setup"
    print_info "Would you like to set up Python development environment?"
    echo "  This will install:"
    echo "  • Python via pyenv (version manager)"
    echo "  • Latest stable Python version (3.12.8)"
    echo "  • FastAPI with uvicorn server"
    echo "  • Django with REST framework"
    echo "  • Development tools (black, flake8, mypy, poetry)"
    echo
    read -p "Install Python, FastAPI, and Django? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -x "$DOTFILES_DIR/python/setup.sh" ]]; then
            print_info "Running Python, FastAPI, and Django setup..."
            "$DOTFILES_DIR/python/setup.sh"
            print_success "Python, FastAPI, and Django setup complete!"
        else
            print_warning "Python setup script not found at $DOTFILES_DIR/python/setup.sh"
            print_info "You can run it manually later:"
            echo "  cd ~/dotfiles && ./python/setup.sh"
        fi
    else
        print_info "Skipping Python, FastAPI, and Django setup"
        print_info "You can run it later with: ~/dotfiles/python/setup.sh"
    fi
    echo

    print_header "Installation Complete!"
    
    echo "Your development environment has been set up successfully!"
    echo
    
    if [[ -f "$HOME/.dotfiles-backup/manifest.json" ]]; then
        print_success "Your original configuration has been backed up"
        echo "  Location: ~/.dotfiles-backup/"
        echo "  Restore: ~/dotfiles/scripts/uninstall.sh restore"
        echo
    fi
    
    print_info "Final setup steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo
    
    # Check for Nerd Font and configure terminals
    FONT_FOUND=false
    if ls ~/Library/Fonts 2>/dev/null | grep -qi "meslo.*nerd" || \
       ls /Library/Fonts 2>/dev/null | grep -qi "meslo.*nerd" 2>/dev/null || \
       ls /System/Library/Fonts 2>/dev/null | grep -qi "meslo.*nerd" 2>/dev/null; then
        FONT_FOUND=true
        print_success "MesloLGS NF font is installed"
    fi
    
    if [[ "$FONT_FOUND" == "false" ]]; then
        print_warning "Terminal font required for optimal display!"
        print_info "Installing Powerlevel10k fonts..."
        if command -v brew &> /dev/null; then
            brew install --cask font-meslo-lg-nerd-font font-meslo-for-powerlevel10k
            print_success "Fonts installed successfully"
            FONT_FOUND=true
        else
            echo "  Install manually with: brew install --cask font-meslo-lg-nerd-font font-meslo-for-powerlevel10k"
        fi
    fi
    
    # Offer to configure terminal fonts automatically
    if [[ "$FONT_FOUND" == "true" ]]; then
        echo
        read -p "Would you like to automatically configure terminal fonts? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Configuring terminal fonts for iTerm2 and Terminal.app..."
            if [[ -x "$DOTFILES_DIR/scripts/configure-terminal-fonts.sh" ]]; then
                "$DOTFILES_DIR/scripts/configure-terminal-fonts.sh"
            else
                print_warning "Font configuration script not found"
                print_info "Manual setup: Set your terminal font to 'MesloLGS NF Regular'"
                print_info "See TERMINAL_SETUP.md for detailed instructions"
            fi
        else
            print_info "Manual font setup required:"
            echo "  1. Set your terminal font to: MesloLGS NF Regular"
            echo "  2. See TERMINAL_SETUP.md for detailed instructions"
            echo "  3. Or run: ~/dotfiles/scripts/configure-terminal-fonts.sh"
        fi
        echo
    fi
    
    # Prompt for Powerlevel10k configuration
    print_info "Powerlevel10k theme configuration:"
    echo "  After restarting your terminal, run: p10k configure"
    echo "  This interactive wizard will help you customize your prompt"
    echo
    
    # Check if Powerlevel10k is properly installed
    if [[ -f "$HOME/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
        read -p "Would you like to configure Powerlevel10k now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Loading Powerlevel10k and starting configuration..."
            # Try to start configuration in a new zsh session
            if zsh -c "source ~/.zshrc 2>/dev/null; command -v p10k &> /dev/null" 2>/dev/null; then
                print_success "Powerlevel10k loaded successfully, starting configuration..."
                zsh -ic "p10k configure"
            else
                print_warning "Powerlevel10k not ready yet. This is normal on first installation."
                print_info "Please restart your terminal and run: p10k configure"
                echo
                print_info "Troubleshooting steps if p10k configure doesn't work:"
                echo "  1. Ensure you're using Zsh: echo \$SHELL"
                echo "  2. Check theme is loaded: echo \$ZSH_THEME"
                echo "  3. Verify installation: ls ~/.oh-my-zsh/custom/themes/powerlevel10k/"
            fi
        else
            print_info "You can configure Powerlevel10k later by running: p10k configure"
        fi
    else
        print_warning "Powerlevel10k theme not found. Please run the setup again or install manually."
        print_info "Manual installation: git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k"
    fi
    echo
    
    print_info "Additional customization:"
    echo "  • Machine-specific settings: ~/.zshrc.local"
    echo "  • Private/sensitive data: ~/.zshrc.private (not tracked by git)"
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