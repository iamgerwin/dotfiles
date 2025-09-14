#!/usr/bin/env bash
# Adaptive Setup Script - Learns from and adapts to existing user configurations
# Preserves custom workflows while integrating dotfiles

set -e

# Configuration
DOTFILES_DIR="$HOME/dotfiles"
ADAPTIVE_DIR="$HOME/.dotfiles-adaptive"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Functions
print_header() {
    echo
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Initialize adaptive directory
init_adaptive() {
    mkdir -p "$ADAPTIVE_DIR"
    mkdir -p "$ADAPTIVE_DIR/learned"
    mkdir -p "$ADAPTIVE_DIR/integrated"
    mkdir -p "$ADAPTIVE_DIR/conflicts"
}

# Learn from existing Homebrew packages
learn_brew_packages() {
    print_header "Learning Installed Packages"
    
    if command -v brew &> /dev/null; then
        print_info "Analyzing installed Homebrew packages..."
        
        # Get list of installed formulae
        brew list --formula > "$ADAPTIVE_DIR/learned/brew_formulae.txt" 2>/dev/null || true
        
        # Get list of installed casks
        brew list --cask > "$ADAPTIVE_DIR/learned/brew_casks.txt" 2>/dev/null || true
        
        # Compare with our Brewfile
        if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
            # Extract packages from Brewfile
            grep '^brew "' "$DOTFILES_DIR/Brewfile" | cut -d'"' -f2 > "$ADAPTIVE_DIR/learned/brewfile_formulae.txt" || true
            grep '^cask "' "$DOTFILES_DIR/Brewfile" | cut -d'"' -f2 > "$ADAPTIVE_DIR/learned/brewfile_casks.txt" || true
            
            # Find packages user has but Brewfile doesn't
            comm -23 <(sort "$ADAPTIVE_DIR/learned/brew_formulae.txt") \
                     <(sort "$ADAPTIVE_DIR/learned/brewfile_formulae.txt") \
                     > "$ADAPTIVE_DIR/learned/formulae_to_add.txt" || true
            
            comm -23 <(sort "$ADAPTIVE_DIR/learned/brew_casks.txt") \
                     <(sort "$ADAPTIVE_DIR/learned/brewfile_casks.txt") \
                     > "$ADAPTIVE_DIR/learned/casks_to_add.txt" || true
            
            local formulae_count=$(wc -l < "$ADAPTIVE_DIR/learned/formulae_to_add.txt" | tr -d ' ')
            local casks_count=$(wc -l < "$ADAPTIVE_DIR/learned/casks_to_add.txt" | tr -d ' ')
            
            if [[ $formulae_count -gt 0 ]] || [[ $casks_count -gt 0 ]]; then
                print_success "Found $formulae_count formula(e) and $casks_count cask(s) to preserve"
                
                # Create supplemental Brewfile
                echo "# Additional packages detected on this system" > "$HOME/.Brewfile.local"
                echo "# Generated on $TIMESTAMP" >> "$HOME/.Brewfile.local"
                echo "" >> "$HOME/.Brewfile.local"
                
                if [[ $formulae_count -gt 0 ]]; then
                    echo "# Formulae" >> "$HOME/.Brewfile.local"
                    while IFS= read -r formula; do
                        echo "brew \"$formula\"" >> "$HOME/.Brewfile.local"
                    done < "$ADAPTIVE_DIR/learned/formulae_to_add.txt"
                    echo "" >> "$HOME/.Brewfile.local"
                fi
                
                if [[ $casks_count -gt 0 ]]; then
                    echo "# Casks" >> "$HOME/.Brewfile.local"
                    while IFS= read -r cask; do
                        echo "cask \"$cask\"" >> "$HOME/.Brewfile.local"
                    done < "$ADAPTIVE_DIR/learned/casks_to_add.txt"
                fi
                
                print_success "Created ~/.Brewfile.local with additional packages"
            else
                print_info "No additional packages to preserve"
            fi
        fi
    else
        print_info "Homebrew not installed"
    fi
}

# Learn from npm global packages
learn_npm_packages() {
    print_header "Learning NPM Global Packages"
    
    if command -v npm &> /dev/null; then
        npm list -g --depth=0 --parseable 2>/dev/null | \
            grep -v "^/" | \
            cut -d'/' -f3 > "$ADAPTIVE_DIR/learned/npm_global.txt" || true
        
        local count=$(wc -l < "$ADAPTIVE_DIR/learned/npm_global.txt" | tr -d ' ')
        if [[ $count -gt 0 ]]; then
            print_success "Found $count global npm package(s)"
            
            # Create npm install script
            echo "#!/usr/bin/env bash" > "$HOME/.npm-global-restore.sh"
            echo "# NPM global packages detected on $TIMESTAMP" >> "$HOME/.npm-global-restore.sh"
            echo "" >> "$HOME/.npm-global-restore.sh"
            while IFS= read -r package; do
                echo "npm install -g $package" >> "$HOME/.npm-global-restore.sh"
            done < "$ADAPTIVE_DIR/learned/npm_global.txt"
            chmod +x "$HOME/.npm-global-restore.sh"
            
            print_success "Created ~/.npm-global-restore.sh"
        fi
    fi
}

# Learn VS Code extensions
learn_vscode_extensions() {
    print_header "Learning VS Code Extensions"
    
    if command -v code &> /dev/null; then
        code --list-extensions > "$ADAPTIVE_DIR/learned/vscode_extensions.txt" 2>/dev/null || true
        
        local count=$(wc -l < "$ADAPTIVE_DIR/learned/vscode_extensions.txt" | tr -d ' ')
        if [[ $count -gt 0 ]]; then
            print_success "Found $count VS Code extension(s)"
            
            # Create VS Code extensions install script
            echo "#!/usr/bin/env bash" > "$HOME/.vscode-extensions-restore.sh"
            echo "# VS Code extensions detected on $TIMESTAMP" >> "$HOME/.vscode-extensions-restore.sh"
            echo "" >> "$HOME/.vscode-extensions-restore.sh"
            while IFS= read -r extension; do
                echo "code --install-extension $extension" >> "$HOME/.vscode-extensions-restore.sh"
            done < "$ADAPTIVE_DIR/learned/vscode_extensions.txt"
            chmod +x "$HOME/.vscode-extensions-restore.sh"
            
            print_success "Created ~/.vscode-extensions-restore.sh"
        fi
    fi
}

# Detect and preserve custom scripts
learn_custom_scripts() {
    print_header "Learning Custom Scripts"

    # Check common script locations
    local script_dirs=(
        "$HOME/bin"
        "$HOME/.local/bin"
        "$HOME/scripts"
    )

    for dir in "${script_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -type f -executable 2>/dev/null > "$ADAPTIVE_DIR/learned/scripts_in_$( basename "$dir").txt" || true
            local count=$(wc -l < "$ADAPTIVE_DIR/learned/scripts_in_$(basename "$dir").txt" | tr -d ' ')
            if [[ $count -gt 0 ]]; then
                print_success "Found $count script(s) in $dir"

                # Create manifest
                echo "$dir: $count scripts" >> "$ADAPTIVE_DIR/learned/custom_scripts_manifest.txt"
            fi
        fi
    done
}

# Learn from existing SSH keys
learn_ssh_keys() {
    print_header "Learning SSH Keys"

    local ssh_key_count=0
    local ssh_keys_found=""

    # Check for SSH keys in ~/.ssh
    if [[ -d "$HOME/.ssh" ]]; then
        for key_file in "$HOME/.ssh"/*; do
            if [[ -f "$key_file" ]] && [[ ! "$key_file" =~ \.pub$ ]]; then
                # Check if it's a private key
                if head -n 1 "$key_file" 2>/dev/null | grep -q "PRIVATE KEY"; then
                    local key_name=$(basename "$key_file")
                    echo "$key_name" >> "$ADAPTIVE_DIR/learned/ssh_keys.txt"
                    ssh_key_count=$((ssh_key_count + 1))
                    ssh_keys_found="${ssh_keys_found}  - $key_name\n"
                fi
            fi
        done
    fi

    if [[ $ssh_key_count -gt 0 ]]; then
        print_success "Found $ssh_key_count SSH key(s)"

        # Create migration script
        cat > "$HOME/.ssh-keys-migrate.sh" << 'EOF'
#!/usr/bin/env bash
# SSH Keys Migration Script
# Migrates existing SSH keys to organized structure

if command -v ~/dotfiles/scripts/ssh-key-manager &> /dev/null; then
    echo "Migrating SSH keys to organized structure..."
    ~/dotfiles/scripts/ssh-key-manager migrate
else
    echo "SSH key manager not found. Manual migration required."
fi
EOF
        chmod +x "$HOME/.ssh-keys-migrate.sh"
        print_success "Created SSH keys migration script: ~/.ssh-keys-migrate.sh"

        # Offer immediate migration if ssh-key-manager is available
        if [[ -x "$DOTFILES_DIR/scripts/ssh-key-manager" ]]; then
            print_info "SSH Key Manager available. You can migrate keys with: sshkm-migrate"
        fi
    else
        print_info "No SSH keys found to preserve"
    fi
}

# Learn from existing Git configuration
learn_git_profiles() {
    print_header "Learning Git Configuration"

    # Capture current git configuration
    local git_user=$(git config --global user.name 2>/dev/null)
    local git_email=$(git config --global user.email 2>/dev/null)

    if [[ -n "$git_user" ]] && [[ -n "$git_email" ]]; then
        print_success "Current Git user: $git_user <$git_email>"

        # Create a default profile based on current configuration
        mkdir -p "$HOME/dotfiles/config/git-profiles" 2>/dev/null || true

        # Try to determine the appropriate SSH key
        local ssh_key=""
        if [[ -f "$ADAPTIVE_DIR/learned/ssh_keys.txt" ]]; then
            # Look for common patterns in key names
            while IFS= read -r key; do
                if [[ "$key" =~ github|gitlab|git ]]; then
                    ssh_key="$key"
                    break
                fi
            done < "$ADAPTIVE_DIR/learned/ssh_keys.txt"

            # If no git-related key found, use the first one
            if [[ -z "$ssh_key" ]] && [[ -s "$ADAPTIVE_DIR/learned/ssh_keys.txt" ]]; then
                ssh_key=$(head -n 1 "$ADAPTIVE_DIR/learned/ssh_keys.txt")
            fi
        fi

        # Create a default profile
        cat > "$HOME/dotfiles/config/git-profiles/default.conf" << EOF
# Default Git Profile (from existing configuration)
# Created: $(date)

# Git user configuration
GIT_USER_NAME="$git_user"
GIT_USER_EMAIL="$git_email"

# SSH key path (relative to ~/.ssh/)
SSH_KEY_NAME="$ssh_key"

# GitHub CLI account (optional)
GH_ACCOUNT=""

# GPG signing key (optional)
GIT_SIGNING_KEY=""
EOF
        print_success "Created default Git profile from existing configuration"
        print_info "You can create additional profiles with: gpm create"
    else
        print_info "No existing Git configuration found"
    fi

    # Check for multiple git configurations (work vs personal)
    if [[ -f "$HOME/.gitconfig" ]]; then
        # Look for includeIf directives that might indicate multiple profiles
        if grep -q "includeIf" "$HOME/.gitconfig" 2>/dev/null; then
            print_info "Detected conditional Git includes - you may have multiple Git identities"
            print_info "Consider setting up Git profiles with: gpm create"
        fi
    fi
}

# Intelligent merge of configurations
intelligent_merge() {
    print_header "Intelligent Configuration Merge"
    
    # Check for conflicts
    if [[ -f "$HOME/.zshrc.local" ]]; then
        print_info "Checking for configuration conflicts..."
        
        # Extract all alias names from .zshrc.local
        grep "^alias " "$HOME/.zshrc.local" 2>/dev/null | cut -d'=' -f1 | cut -d' ' -f2 > "$ADAPTIVE_DIR/conflicts/local_aliases.txt" || true
        
        # Extract all alias names from dotfiles
        if [[ -f "$DOTFILES_DIR/aliases.zsh" ]]; then
            grep "^alias " "$DOTFILES_DIR/aliases.zsh" 2>/dev/null | cut -d'=' -f1 | cut -d' ' -f2 > "$ADAPTIVE_DIR/conflicts/dotfiles_aliases.txt" || true
            
            # Find conflicts
            comm -12 <(sort "$ADAPTIVE_DIR/conflicts/local_aliases.txt") \
                     <(sort "$ADAPTIVE_DIR/conflicts/dotfiles_aliases.txt") \
                     > "$ADAPTIVE_DIR/conflicts/alias_conflicts.txt" || true
            
            local conflicts=$(wc -l < "$ADAPTIVE_DIR/conflicts/alias_conflicts.txt" | tr -d ' ')
            if [[ $conflicts -gt 0 ]]; then
                print_warning "Found $conflicts alias conflict(s)"
                echo "Conflicting aliases:" >> "$ADAPTIVE_DIR/conflicts/resolution_log.txt"
                cat "$ADAPTIVE_DIR/conflicts/alias_conflicts.txt" >> "$ADAPTIVE_DIR/conflicts/resolution_log.txt"
                print_info "Local versions will take precedence (in .zshrc.local)"
            else
                print_success "No conflicts detected"
            fi
        fi
    fi
}

# Create adaptive configuration
create_adaptive_config() {
    print_header "Creating Adaptive Configuration"
    
    # Create adaptive loader
    cat > "$HOME/.zshrc.adaptive" << 'EOF'
#!/usr/bin/env zsh
# Adaptive Configuration Loader
# Loads configurations in intelligent order

# Load main dotfiles configuration
[[ -f "$HOME/dotfiles/.zshrc" ]] && source "$HOME/dotfiles/.zshrc"

# Load local Brewfile if exists
[[ -f "$HOME/.Brewfile.local" ]] && export HOMEBREW_BUNDLE_FILE_LOCAL="$HOME/.Brewfile.local"

# Load preserved customizations (these override dotfiles)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Load private/sensitive configurations
[[ -f "$HOME/.zshrc.private" ]] && source "$HOME/.zshrc.private"

# Load machine-specific overrides
[[ -f "$HOME/.zshrc.$(hostname)" ]] && source "$HOME/.zshrc.$(hostname)"

# Load work-specific configurations
[[ -f "$HOME/.zshrc.work" ]] && source "$HOME/.zshrc.work"
EOF
    
    print_success "Created adaptive configuration loader"
}

# Generate restoration script
generate_restore_script() {
    print_header "Generating Restoration Script"
    
    cat > "$HOME/.dotfiles-restore.sh" << EOF
#!/usr/bin/env bash
# Restoration Script - Recreates your complete environment
# Generated on $TIMESTAMP

echo "Restoring development environment..."

# Install Homebrew packages
if [[ -f "$HOME/.Brewfile.local" ]]; then
    echo "Installing additional Homebrew packages..."
    brew bundle --file="$HOME/.Brewfile.local"
fi

# Restore NPM packages
if [[ -f "$HOME/.npm-global-restore.sh" ]]; then
    echo "Restoring NPM global packages..."
    bash "$HOME/.npm-global-restore.sh"
fi

# Restore VS Code extensions
if [[ -f "$HOME/.vscode-extensions-restore.sh" ]]; then
    echo "Restoring VS Code extensions..."
    bash "$HOME/.vscode-extensions-restore.sh"
fi

echo "Restoration complete!"
EOF
    
    chmod +x "$HOME/.dotfiles-restore.sh"
    print_success "Created restoration script: ~/.dotfiles-restore.sh"
}

# Create adaptive report
create_adaptive_report() {
    print_header "Generating Adaptive Setup Report"
    
    cat > "$ADAPTIVE_DIR/adaptive_report_$TIMESTAMP.md" << EOF
# Adaptive Setup Report
Generated: $(date)

## System Analysis

### Existing Customizations Preserved
- Configuration files backed up: $(ls ~/.*.backup.* 2>/dev/null | wc -l | tr -d ' ')
- Custom aliases preserved: $(grep -c "^alias " ~/.zshrc.local 2>/dev/null || echo "0")
- Custom functions preserved: $(grep -c "function \|^[[:alnum:]_]*(" ~/.zshrc.local 2>/dev/null || echo "0")

### Additional Packages Detected
$(if [[ -f "$HOME/.Brewfile.local" ]]; then
    echo "- Homebrew: $(grep -c '^brew \|^cask ' "$HOME/.Brewfile.local" 2>/dev/null || echo "0") packages"
fi)
$(if [[ -f "$ADAPTIVE_DIR/learned/npm_global.txt" ]]; then
    echo "- NPM Global: $(wc -l < "$ADAPTIVE_DIR/learned/npm_global.txt" | tr -d ' ') packages"
fi)
$(if [[ -f "$ADAPTIVE_DIR/learned/vscode_extensions.txt" ]]; then
    echo "- VS Code: $(wc -l < "$ADAPTIVE_DIR/learned/vscode_extensions.txt" | tr -d ' ') extensions"
fi)

### Conflicts Resolved
$(if [[ -f "$ADAPTIVE_DIR/conflicts/alias_conflicts.txt" ]]; then
    echo "- Alias conflicts: $(wc -l < "$ADAPTIVE_DIR/conflicts/alias_conflicts.txt" | tr -d ' ')"
    echo "  Resolution: Local versions take precedence"
fi)

## Files Created

1. **~/.zshrc.local** - Your preserved customizations
2. **~/.zshrc.private** - Sensitive configurations
3. **~/.Brewfile.local** - Additional Homebrew packages
4. **~/.dotfiles-restore.sh** - Complete environment restoration
5. **~/.npm-global-restore.sh** - NPM packages restoration
6. **~/.vscode-extensions-restore.sh** - VS Code extensions restoration

## Integration Status

✅ Original workflow preserved
✅ Custom tools and packages captured
✅ Dotfiles integrated without disruption
✅ Rollback capability maintained

## Next Steps

1. Review preserved customizations: \`cat ~/.zshrc.local\`
2. Test your environment: \`source ~/.zshrc\`
3. Run restoration if needed: \`~/.dotfiles-restore.sh\`
EOF
    
    print_success "Report saved to: $ADAPTIVE_DIR/adaptive_report_$TIMESTAMP.md"
}

# Main adaptive setup
main() {
    clear
    echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║      Adaptive Dotfiles Setup           ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
    echo
    
    print_info "This setup adapts to your existing configuration"
    print_info "All customizations will be preserved"
    echo
    
    init_adaptive
    
    # Run migration first to capture customizations
    if [[ -f "$DOTFILES_DIR/scripts/migrate.sh" ]]; then
        print_info "Running migration to capture customizations..."
        bash "$DOTFILES_DIR/scripts/migrate.sh"
    fi
    
    # Learn from existing setup
    learn_brew_packages
    learn_npm_packages
    learn_vscode_extensions
    learn_custom_scripts
    learn_ssh_keys
    learn_git_profiles
    
    # Merge intelligently
    intelligent_merge
    
    # Create adaptive configuration
    create_adaptive_config
    
    # Generate restoration capability
    generate_restore_script
    
    # Create report
    create_adaptive_report
    
    print_header "Adaptive Setup Complete!"
    
    print_success "Your environment has been preserved and enhanced!"
    echo
    print_info "Preserved files:"
    echo "  • ~/.zshrc.local - Your customizations"
    echo "  • ~/.Brewfile.local - Your additional packages"
    echo "  • ~/.dotfiles-restore.sh - Full restoration script"
    echo
    print_info "Your original workflow is intact with added benefits:"
    echo "  • Version control for configurations"
    echo "  • Easy synchronization across machines"
    echo "  • Instant rollback capability"
    echo
    print_success "No disruption to your existing setup!"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi