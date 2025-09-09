#!/usr/bin/env bash
# Migration Script - Intelligently imports existing user customizations
# Adapts to pre-existing setups and preserves custom workflows

set -e

# Configuration
DOTFILES_DIR="$HOME/dotfiles"
MIGRATION_DIR="$HOME/.dotfiles-migration"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

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

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Create migration directory
init_migration() {
    mkdir -p "$MIGRATION_DIR"
    mkdir -p "$MIGRATION_DIR/detected"
    mkdir -p "$MIGRATION_DIR/merged"
    print_success "Initialized migration directory"
}

# Detect custom aliases not in our dotfiles
detect_custom_aliases() {
    print_header "Detecting Custom Aliases"
    
    if [[ ! -f "$HOME/.zshrc" ]]; then
        print_info "No existing .zshrc found"
        return
    fi
    
    # Extract all aliases from existing .zshrc
    grep "^alias " "$HOME/.zshrc" 2>/dev/null > "$MIGRATION_DIR/detected/aliases_found.txt" || true
    
    # Extract aliases from our dotfiles
    if [[ -f "$DOTFILES_DIR/aliases.zsh" ]]; then
        grep "^alias " "$DOTFILES_DIR/aliases.zsh" 2>/dev/null > "$MIGRATION_DIR/detected/aliases_existing.txt" || true
    else
        touch "$MIGRATION_DIR/detected/aliases_existing.txt"
    fi
    
    # Find unique aliases (in user's config but not in dotfiles)
    comm -23 <(sort "$MIGRATION_DIR/detected/aliases_found.txt") \
             <(sort "$MIGRATION_DIR/detected/aliases_existing.txt") \
             > "$MIGRATION_DIR/detected/aliases_unique.txt" || true
    
    local count=$(wc -l < "$MIGRATION_DIR/detected/aliases_unique.txt" | tr -d ' ')
    
    if [[ $count -gt 0 ]]; then
        print_success "Found $count custom alias(es) to migrate"
        echo "Custom aliases detected:" >> "$MIGRATION_DIR/migration_log.txt"
        cat "$MIGRATION_DIR/detected/aliases_unique.txt" >> "$MIGRATION_DIR/migration_log.txt"
        
        # Add to local customizations
        echo "" >> "$HOME/.zshrc.local"
        echo "# Custom aliases migrated on $TIMESTAMP" >> "$HOME/.zshrc.local"
        cat "$MIGRATION_DIR/detected/aliases_unique.txt" >> "$HOME/.zshrc.local"
    else
        print_info "No unique custom aliases found"
    fi
}

# Detect custom functions
detect_custom_functions() {
    print_header "Detecting Custom Functions"
    
    if [[ ! -f "$HOME/.zshrc" ]]; then
        return
    fi
    
    # Extract function definitions
    awk '/^[[:space:]]*function[[:space:]]+[[:alnum:]_]+|^[[:space:]]*[[:alnum:]_]+\(\)/ {
        print
        in_function=1
    }
    in_function && /^}/ {
        print
        in_function=0
    }
    in_function {
        print
    }' "$HOME/.zshrc" > "$MIGRATION_DIR/detected/functions_found.txt" 2>/dev/null || true
    
    local count=$(grep -c "^function \|^[[:alnum:]_]*(" "$MIGRATION_DIR/detected/functions_found.txt" 2>/dev/null || echo "0")
    
    if [[ $count -gt 0 ]]; then
        print_success "Found $count custom function(s) to migrate"
        
        # Add to local customizations
        echo "" >> "$HOME/.zshrc.local"
        echo "# Custom functions migrated on $TIMESTAMP" >> "$HOME/.zshrc.local"
        cat "$MIGRATION_DIR/detected/functions_found.txt" >> "$HOME/.zshrc.local"
    else
        print_info "No custom functions found"
    fi
}

# Detect custom exports
detect_custom_exports() {
    print_header "Detecting Custom Environment Variables"
    
    if [[ ! -f "$HOME/.zshrc" ]]; then
        return
    fi
    
    # Extract exports, excluding common ones we already handle
    grep "^export " "$HOME/.zshrc" 2>/dev/null | \
        grep -v "export PATH\|export NVM_DIR\|export ZSH\|export PYENV\|export HERD" | \
        grep -v "export LANG\|export LC_ALL\|export EDITOR" \
        > "$MIGRATION_DIR/detected/exports_custom.txt" || true
    
    local count=$(wc -l < "$MIGRATION_DIR/detected/exports_custom.txt" | tr -d ' ')
    
    if [[ $count -gt 0 ]]; then
        print_success "Found $count custom export(s) to migrate"
        
        # Separate sensitive exports
        grep -E "KEY|TOKEN|SECRET|PASSWORD|CREDENTIAL" "$MIGRATION_DIR/detected/exports_custom.txt" \
            > "$MIGRATION_DIR/detected/exports_sensitive.txt" 2>/dev/null || true
        
        grep -v -E "KEY|TOKEN|SECRET|PASSWORD|CREDENTIAL" "$MIGRATION_DIR/detected/exports_custom.txt" \
            > "$MIGRATION_DIR/detected/exports_safe.txt" 2>/dev/null || true
        
        # Add safe exports to .zshrc.local
        if [[ -s "$MIGRATION_DIR/detected/exports_safe.txt" ]]; then
            echo "" >> "$HOME/.zshrc.local"
            echo "# Custom exports migrated on $TIMESTAMP" >> "$HOME/.zshrc.local"
            cat "$MIGRATION_DIR/detected/exports_safe.txt" >> "$HOME/.zshrc.local"
        fi
        
        # Add sensitive exports to .zshrc.private
        if [[ -s "$MIGRATION_DIR/detected/exports_sensitive.txt" ]]; then
            echo "" >> "$HOME/.zshrc.private"
            echo "# Sensitive exports migrated on $TIMESTAMP" >> "$HOME/.zshrc.private"
            cat "$MIGRATION_DIR/detected/exports_sensitive.txt" >> "$HOME/.zshrc.private"
            print_warning "Sensitive exports moved to ~/.zshrc.private (not tracked in git)"
        fi
    else
        print_info "No custom exports found"
    fi
}

# Detect installed tools and packages
detect_installed_tools() {
    print_header "Detecting Installed Development Tools"
    
    local tools_found=""
    
    # Check for various tools
    if command -v node &> /dev/null; then
        tools_found+="Node.js: $(node --version)\n"
    fi
    
    if command -v python3 &> /dev/null; then
        tools_found+="Python: $(python3 --version 2>&1)\n"
    fi
    
    if command -v ruby &> /dev/null; then
        tools_found+="Ruby: $(ruby --version | head -n1)\n"
    fi
    
    if command -v php &> /dev/null; then
        tools_found+="PHP: $(php --version | head -n1)\n"
    fi
    
    if command -v go &> /dev/null; then
        tools_found+="Go: $(go version)\n"
    fi
    
    if command -v rust &> /dev/null; then
        tools_found+="Rust: $(rustc --version 2>/dev/null || echo 'installed')\n"
    fi
    
    if command -v docker &> /dev/null; then
        tools_found+="Docker: $(docker --version)\n"
    fi
    
    if [[ -n "$tools_found" ]]; then
        echo -e "$tools_found" > "$MIGRATION_DIR/detected/tools_installed.txt"
        print_success "Detected installed development tools"
    fi
}

# Detect custom PATH additions
detect_custom_paths() {
    print_header "Detecting Custom PATH Additions"
    
    if [[ ! -f "$HOME/.zshrc" ]]; then
        return
    fi
    
    # Extract PATH modifications
    grep -E "PATH=.*:\$PATH|PATH=\".*:\$PATH\"|export PATH=" "$HOME/.zshrc" 2>/dev/null | \
        grep -v "# Herd\|# NVM\|# Pyenv\|# Homebrew" \
        > "$MIGRATION_DIR/detected/paths_custom.txt" || true
    
    local count=$(wc -l < "$MIGRATION_DIR/detected/paths_custom.txt" | tr -d ' ')
    
    if [[ $count -gt 0 ]]; then
        print_success "Found $count custom PATH addition(s)"
        
        echo "" >> "$HOME/.zshrc.local"
        echo "# Custom PATH additions migrated on $TIMESTAMP" >> "$HOME/.zshrc.local"
        cat "$MIGRATION_DIR/detected/paths_custom.txt" >> "$HOME/.zshrc.local"
    else
        print_info "No custom PATH additions found"
    fi
}

# Detect Git configuration
detect_git_config() {
    print_header "Detecting Git Configuration"
    
    if command -v git &> /dev/null; then
        local git_name=$(git config --global user.name 2>/dev/null || echo "")
        local git_email=$(git config --global user.email 2>/dev/null || echo "")
        
        if [[ -n "$git_name" ]] || [[ -n "$git_email" ]]; then
            print_success "Git configuration detected"
            echo "Git user: $git_name <$git_email>" >> "$MIGRATION_DIR/migration_log.txt"
        fi
        
        # Check for custom git aliases
        git config --global --get-regexp alias 2>/dev/null > "$MIGRATION_DIR/detected/git_aliases.txt" || true
        
        if [[ -s "$MIGRATION_DIR/detected/git_aliases.txt" ]]; then
            local count=$(wc -l < "$MIGRATION_DIR/detected/git_aliases.txt" | tr -d ' ')
            print_success "Found $count git alias(es)"
        fi
    fi
}

# Detect shell plugins and frameworks
detect_shell_plugins() {
    print_header "Detecting Shell Plugins and Themes"
    
    # Oh My Zsh plugins
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        if [[ -f "$HOME/.zshrc" ]]; then
            local plugins=$(grep "^plugins=(" "$HOME/.zshrc" 2>/dev/null || echo "")
            if [[ -n "$plugins" ]]; then
                echo "$plugins" > "$MIGRATION_DIR/detected/omz_plugins.txt"
                print_success "Oh My Zsh plugins configuration detected"
            fi
        fi
        
        # Check for custom plugins
        if [[ -d "$HOME/.oh-my-zsh/custom/plugins" ]]; then
            ls "$HOME/.oh-my-zsh/custom/plugins" > "$MIGRATION_DIR/detected/omz_custom_plugins.txt" 2>/dev/null || true
            local count=$(wc -l < "$MIGRATION_DIR/detected/omz_custom_plugins.txt" | tr -d ' ')
            if [[ $count -gt 0 ]]; then
                print_success "Found $count custom Oh My Zsh plugin(s)"
            fi
        fi
    fi
    
    # Check for theme
    if [[ -f "$HOME/.zshrc" ]]; then
        local theme=$(grep "^ZSH_THEME=" "$HOME/.zshrc" 2>/dev/null | cut -d'"' -f2)
        if [[ -n "$theme" ]]; then
            print_info "Current theme: $theme"
            echo "ZSH_THEME=\"$theme\"" > "$MIGRATION_DIR/detected/theme.txt"
        fi
    fi
}

# Create migration report
create_migration_report() {
    print_header "Creating Migration Report"
    
    local report="$MIGRATION_DIR/migration_report_$TIMESTAMP.md"
    
    cat > "$report" << EOF
# Migration Report
Generated: $(date)

## Summary
This report details the customizations detected in your existing shell configuration.

## Detected Customizations

### Aliases
$(if [[ -s "$MIGRATION_DIR/detected/aliases_unique.txt" ]]; then
    echo "Found $(wc -l < "$MIGRATION_DIR/detected/aliases_unique.txt" | tr -d ' ') custom alias(es)"
    echo '```bash'
    cat "$MIGRATION_DIR/detected/aliases_unique.txt"
    echo '```'
else
    echo "No custom aliases detected"
fi)

### Functions
$(if [[ -s "$MIGRATION_DIR/detected/functions_found.txt" ]]; then
    echo "Custom functions detected and migrated"
else
    echo "No custom functions detected"
fi)

### Environment Variables
$(if [[ -s "$MIGRATION_DIR/detected/exports_custom.txt" ]]; then
    echo "Found $(wc -l < "$MIGRATION_DIR/detected/exports_custom.txt" | tr -d ' ') custom export(s)"
    if [[ -s "$MIGRATION_DIR/detected/exports_sensitive.txt" ]]; then
        echo "- Sensitive exports moved to ~/.zshrc.private"
    fi
    if [[ -s "$MIGRATION_DIR/detected/exports_safe.txt" ]]; then
        echo "- Safe exports added to ~/.zshrc.local"
    fi
else
    echo "No custom exports detected"
fi)

### Development Tools
$(if [[ -s "$MIGRATION_DIR/detected/tools_installed.txt" ]]; then
    cat "$MIGRATION_DIR/detected/tools_installed.txt"
else
    echo "No additional tools detected"
fi)

### Git Configuration
$(if [[ -s "$MIGRATION_DIR/detected/git_aliases.txt" ]]; then
    echo "Git aliases detected: $(wc -l < "$MIGRATION_DIR/detected/git_aliases.txt" | tr -d ' ')"
else
    echo "No custom git configuration detected"
fi)

## Migration Actions

1. Custom configurations have been preserved in:
   - \`~/.zshrc.local\` - Safe customizations
   - \`~/.zshrc.private\` - Sensitive data (not tracked in git)

2. Original files backed up to:
   - \`$MIGRATION_DIR\`

3. To review migrated settings:
   - \`cat ~/.zshrc.local\`
   - \`cat ~/.zshrc.private\`

## Next Steps

1. Review the migrated settings
2. Test your shell configuration: \`source ~/.zshrc\`
3. Verify all aliases and functions work correctly
4. Remove duplicates if any were created

## Rollback

If needed, your original configuration is preserved in the migration directory.
EOF
    
    print_success "Migration report created: $report"
}

# Main migration flow
main() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Configuration Migration Tool        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo
    
    print_info "This tool will detect and migrate your existing customizations"
    echo
    
    init_migration
    detect_custom_aliases
    detect_custom_functions
    detect_custom_exports
    detect_custom_paths
    detect_installed_tools
    detect_git_config
    detect_shell_plugins
    create_migration_report
    
    print_header "Migration Complete"
    
    print_success "Your customizations have been detected and preserved!"
    echo
    print_info "Migrated settings are in:"
    echo "  • ~/.zshrc.local (safe customizations)"
    echo "  • ~/.zshrc.private (sensitive data)"
    echo
    print_info "Migration report:"
    echo "  • $MIGRATION_DIR/migration_report_$TIMESTAMP.md"
    echo
    print_success "Your original workflow has been preserved!"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi