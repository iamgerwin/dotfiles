#!/usr/bin/env bash
# Pre-installation Check Script
# Analyzes existing configuration and provides recommendations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Functions
print_header() {
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Check existing files
check_existing_configs() {
    print_header "Checking Existing Configuration"
    
    local has_configs=false
    local configs_to_check=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.p10k.zsh"
        "$HOME/.gitconfig"
        "$HOME/.tmux.conf"
    )
    
    for config in "${configs_to_check[@]}"; do
        if [[ -f "$config" ]] || [[ -L "$config" ]]; then
            has_configs=true
            if [[ -L "$config" ]]; then
                local target=$(readlink "$config")
                print_info "$(basename "$config") exists (symlink → $target)"
            else
                local size=$(wc -l < "$config" | tr -d ' ')
                print_info "$(basename "$config") exists ($size lines)"
            fi
        fi
    done
    
    if ! $has_configs; then
        print_success "No existing configuration files found - clean installation"
    fi
    
    echo "$has_configs"
}

# Check for Oh My Zsh
check_oh_my_zsh() {
    print_header "Checking Shell Framework"
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_success "Oh My Zsh is installed"
        
        # Check for Powerlevel10k
        if [[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
            print_success "Powerlevel10k theme is installed"
        else
            print_warning "Powerlevel10k theme not found"
            echo "  → Will be installed during setup"
        fi
        
        # Check for common plugins
        local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
        if [[ -d "$plugins_dir/zsh-autosuggestions" ]]; then
            print_success "zsh-autosuggestions plugin found"
        else
            print_info "zsh-autosuggestions will be installed"
        fi
        
        if [[ -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
            print_success "zsh-syntax-highlighting plugin found"
        else
            print_info "zsh-syntax-highlighting will be installed"
        fi
    else
        print_warning "Oh My Zsh is not installed"
        echo "  → Will be installed during setup (optional)"
    fi
}

# Check development tools
check_dev_tools() {
    print_header "Checking Development Tools"
    
    # Homebrew
    if command -v brew &> /dev/null; then
        print_success "Homebrew is installed ($(brew --version | head -n1))"
    else
        print_warning "Homebrew is not installed"
        echo "  → Will be installed during setup"
    fi
    
    # NVM
    if [[ -d "$HOME/.nvm" ]]; then
        print_success "NVM is installed"
    else
        print_info "NVM not found (will be configured if installed via Homebrew)"
    fi
    
    # Pyenv
    if command -v pyenv &> /dev/null || [[ -d "$HOME/.pyenv" ]]; then
        print_success "Pyenv is installed"
    else
        print_info "Pyenv not found (will be configured if installed via Homebrew)"
    fi
    
    # PHP/Herd
    if [[ -d "/Users/$(whoami)/Library/Application Support/Herd" ]]; then
        print_success "Laravel Herd is installed"
    else
        print_info "Laravel Herd not found (configuration will be added if installed)"
    fi
    
    # Git
    if command -v git &> /dev/null; then
        print_success "Git is installed ($(git --version))"
    else
        print_error "Git is not installed - required for setup"
        echo "  → Please install Xcode Command Line Tools first"
    fi
}

# Check shell
check_shell() {
    print_header "Checking Shell Configuration"
    
    local current_shell=$(echo $SHELL)
    print_info "Current shell: $current_shell"
    
    if [[ "$current_shell" == *"zsh"* ]]; then
        print_success "Zsh is your default shell"
    else
        print_warning "Your default shell is not Zsh"
        echo "  → You may want to change it with: chsh -s /bin/zsh"
    fi
    
    # Check Zsh version
    if command -v zsh &> /dev/null; then
        local zsh_version=$(zsh --version | cut -d' ' -f2)
        print_info "Zsh version: $zsh_version"
    fi
}

# Check for backups
check_backups() {
    print_header "Checking Existing Backups"
    
    if [[ -d "$HOME/.dotfiles-backup" ]]; then
        print_success "Backup directory exists"
        
        if [[ -f "$HOME/.dotfiles-backup/manifest.json" ]]; then
            local backup_count=$(jq '.backups | length' "$HOME/.dotfiles-backup/manifest.json" 2>/dev/null || echo "0")
            print_info "Found $backup_count existing backup(s)"
        fi
    else
        print_info "No existing backups found"
        echo "  → Backups will be created during installation"
    fi
    
    # Check for old-style backups
    local old_backups=$(ls $HOME/.*.backup.* 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$old_backups" -gt "0" ]]; then
        print_info "Found $old_backups old-style backup file(s)"
    fi
}

# Analyze current .zshrc
analyze_zshrc() {
    if [[ -f "$HOME/.zshrc" ]] && [[ ! -L "$HOME/.zshrc" ]]; then
        print_header "Analyzing Current .zshrc"
        
        # Check for common configurations
        if grep -q "export NVM_DIR" "$HOME/.zshrc" 2>/dev/null; then
            print_info "NVM configuration found"
        fi
        
        if grep -q "pyenv init" "$HOME/.zshrc" 2>/dev/null; then
            print_info "Pyenv configuration found"
        fi
        
        if grep -q "oh-my-zsh.sh" "$HOME/.zshrc" 2>/dev/null; then
            print_info "Oh My Zsh configuration found"
        fi
        
        if grep -q "p10k.zsh" "$HOME/.zshrc" 2>/dev/null; then
            print_info "Powerlevel10k configuration found"
        fi
        
        # Count custom aliases
        local alias_count=$(grep -c "^alias " "$HOME/.zshrc" 2>/dev/null || echo "0")
        if [[ $alias_count -gt 0 ]]; then
            print_info "Found $alias_count custom alias(es)"
            echo "  → These should be preserved in ~/.zshrc.local after installation"
        fi
        
        # Check for custom functions
        local function_count=$(grep -c "^function " "$HOME/.zshrc" 2>/dev/null || echo "0")
        if [[ $function_count -gt 0 ]]; then
            print_info "Found $function_count custom function(s)"
            echo "  → These should be preserved in ~/.zshrc.local after installation"
        fi
    fi
}

# Provide recommendations
provide_recommendations() {
    print_header "Installation Recommendations"
    
    echo -e "${CYAN}Based on your current setup:${NC}"
    echo
    
    if [[ -f "$HOME/.zshrc" ]] && [[ ! -L "$HOME/.zshrc" ]]; then
        echo "1. Your existing .zshrc will be backed up automatically"
        echo "2. Review your current configuration for custom settings:"
        echo "   ${YELLOW}cat ~/.zshrc | grep -E '^(alias|export|function)'${NC}"
        echo "3. Save any custom settings to ~/.zshrc.local before or after installation"
        echo
    fi
    
    echo -e "${GREEN}Recommended installation method:${NC}"
    echo "   cd ~/dotfiles"
    echo "   ./setup.sh"
    echo
    echo -e "${CYAN}To preserve custom settings:${NC}"
    echo "1. Before installation: Copy them to ~/.zshrc.local"
    echo "2. After installation: They'll be in ~/.zshrc.backup.[timestamp]"
    echo
    echo -e "${YELLOW}Rollback is always available:${NC}"
    echo "   ~/dotfiles/scripts/uninstall.sh restore"
}

# Main execution
main() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║    Dotfiles Pre-Installation Check     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    
    check_shell
    check_existing_configs > /dev/null
    check_oh_my_zsh
    check_dev_tools
    check_backups
    analyze_zshrc
    provide_recommendations
    
    print_header "Ready to Install"
    echo -e "${GREEN}✓ Pre-check complete${NC}"
    echo
    read -p "Do you want to proceed with installation? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo
        echo "Running setup..."
        if [[ -f "$(dirname "$0")/../setup.sh" ]]; then
            bash "$(dirname "$0")/../setup.sh"
        else
            echo "Error: setup.sh not found"
            exit 1
        fi
    else
        echo "Installation cancelled"
        echo "Run ./setup.sh when you're ready"
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi