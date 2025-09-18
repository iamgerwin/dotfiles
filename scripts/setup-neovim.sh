#!/usr/bin/env bash
# Neovim Setup Script
# Non-destructive installation with backup mechanism

set -e

# Configuration
NVIM_CONFIG_DIR="$HOME/.config/nvim"
DOTFILES_DIR="$HOME/dotfiles"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.config/nvim.backup.$TIMESTAMP"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Functions
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

print_header() {
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

# Check for Neovim installation
check_neovim() {
    print_header "Checking Neovim Installation"

    if command -v nvim &> /dev/null; then
        local nvim_version=$(nvim --version | head -n1)
        print_success "Neovim found: $nvim_version"

        # Check version (require 0.9.0+)
        local version=$(nvim --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        local major=$(echo "$version" | cut -d. -f1)
        local minor=$(echo "$version" | cut -d. -f2)

        if [[ "$major" -eq 0 ]] && [[ "$minor" -lt 9 ]]; then
            print_warning "Neovim version 0.9.0+ recommended (found: $version)"
            echo "Some features may not work properly with older versions"
            read -p "Continue anyway? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                return 1
            fi
        fi
    else
        print_error "Neovim not found!"
        echo "Install Neovim first:"
        echo "  brew install neovim"
        echo "  or visit: https://neovim.io/doc/user/quickstart.html"
        return 1
    fi
}

# Backup existing configuration
backup_existing() {
    print_header "Backing Up Existing Configuration"

    if [[ -d "$NVIM_CONFIG_DIR" ]] || [[ -L "$NVIM_CONFIG_DIR" ]]; then
        print_info "Found existing Neovim configuration"

        # Check if it's already a symlink to our config
        if [[ -L "$NVIM_CONFIG_DIR" ]]; then
            local link_target=$(readlink "$NVIM_CONFIG_DIR")
            if [[ "$link_target" == "$DOTFILES_DIR/nvim" ]]; then
                print_success "Already using dotfiles configuration"
                return 0
            fi
        fi

        # Analyze existing configuration
        local file_count=0
        local has_init_vim=false
        local has_init_lua=false
        local has_plugins=false

        if [[ -d "$NVIM_CONFIG_DIR" ]]; then
            file_count=$(find "$NVIM_CONFIG_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
            [[ -f "$NVIM_CONFIG_DIR/init.vim" ]] && has_init_vim=true
            [[ -f "$NVIM_CONFIG_DIR/init.lua" ]] && has_init_lua=true
            [[ -d "$NVIM_CONFIG_DIR/lua" ]] && has_plugins=true
        fi

        echo "Configuration analysis:"
        echo "  • Files found: $file_count"
        [[ "$has_init_vim" == "true" ]] && echo "  • VimScript config detected (init.vim)"
        [[ "$has_init_lua" == "true" ]] && echo "  • Lua config detected (init.lua)"
        [[ "$has_plugins" == "true" ]] && echo "  • Plugin configuration detected"

        echo
        echo "Options:"
        echo "  1) Backup and replace (recommended for clean setup)"
        echo "  2) Merge configurations (experimental)"
        echo "  3) View existing config first"
        echo "  4) Cancel installation"
        echo
        read -p "Enter choice [1-4]: " choice

        case $choice in
            1)
                print_info "Creating backup at: $BACKUP_DIR"
                mv "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
                print_success "Backup created successfully"

                # Create restore script
                cat > "$BACKUP_DIR/restore.sh" << EOF
#!/usr/bin/env bash
# Restore script for Neovim configuration
# Created: $(date)

echo "Restoring Neovim configuration from backup..."
if [[ -d "$NVIM_CONFIG_DIR" ]] || [[ -L "$NVIM_CONFIG_DIR" ]]; then
    rm -rf "$NVIM_CONFIG_DIR"
fi
cp -r "$BACKUP_DIR" "$NVIM_CONFIG_DIR"
echo "Configuration restored!"
EOF
                chmod +x "$BACKUP_DIR/restore.sh"
                print_success "Created restore script: $BACKUP_DIR/restore.sh"
                ;;
            2)
                print_info "Attempting to merge configurations..."
                merge_configurations
                ;;
            3)
                echo "Current configuration structure:"
                tree -L 2 "$NVIM_CONFIG_DIR" 2>/dev/null || ls -la "$NVIM_CONFIG_DIR"
                echo
                read -p "Continue with installation? (y/n) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    return 1
                fi
                backup_existing
                ;;
            4)
                print_info "Installation cancelled"
                return 1
                ;;
            *)
                print_error "Invalid choice"
                return 1
                ;;
        esac
    else
        print_success "No existing configuration found"
    fi
}

# Merge existing configuration with new one
merge_configurations() {
    print_info "Creating merged configuration..."

    # Backup existing config
    cp -r "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
    print_success "Backup created at: $BACKUP_DIR"

    # Create user customizations directory
    mkdir -p "$DOTFILES_DIR/nvim/lua/user"

    # Preserve user's init.lua customizations if they exist
    if [[ -f "$NVIM_CONFIG_DIR/init.lua" ]]; then
        print_info "Preserving init.lua customizations..."
        cp "$NVIM_CONFIG_DIR/init.lua" "$DOTFILES_DIR/nvim/lua/user/init.lua.preserved"

        # Add loader for preserved config
        cat >> "$DOTFILES_DIR/nvim/init.lua" << 'EOF'

-- Load preserved user configuration
local user_config = vim.fn.stdpath("config") .. "/lua/user/init.lua.preserved"
if vim.fn.filereadable(user_config) == 1 then
  dofile(user_config)
end
EOF
    fi

    # Preserve custom plugins
    if [[ -d "$NVIM_CONFIG_DIR/lua" ]]; then
        print_info "Preserving custom plugins and configurations..."
        cp -r "$NVIM_CONFIG_DIR/lua/"* "$DOTFILES_DIR/nvim/lua/user/" 2>/dev/null || true
    fi

    print_success "Configurations merged"
}

# Install Neovim configuration
install_config() {
    print_header "Installing Neovim Configuration"

    # Ensure .config directory exists
    mkdir -p "$HOME/.config"

    # Create symlink to dotfiles nvim config
    if [[ -d "$DOTFILES_DIR/nvim" ]]; then
        ln -sf "$DOTFILES_DIR/nvim" "$NVIM_CONFIG_DIR"
        print_success "Linked Neovim configuration"
    else
        print_error "Neovim configuration not found in dotfiles"
        return 1
    fi

    # Create necessary directories
    mkdir -p "$HOME/.local/share/nvim/undo"
    mkdir -p "$HOME/.vim/undodir"
    print_success "Created necessary directories"
}

# Install plugin dependencies
install_dependencies() {
    print_header "Installing Dependencies"

    # Check for required tools
    local missing_deps=()

    # Git (required for plugin manager)
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    # Node.js (for many LSP servers and copilot)
    if ! command -v node &> /dev/null; then
        missing_deps+=("node")
    fi

    # Ripgrep (for Telescope)
    if ! command -v rg &> /dev/null; then
        missing_deps+=("ripgrep")
    fi

    # fd (for Telescope file finder)
    if ! command -v fd &> /dev/null; then
        missing_deps+=("fd")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_warning "Missing optional dependencies: ${missing_deps[*]}"
        echo "Install them for full functionality:"
        echo "  brew install ${missing_deps[*]}"
        echo
        read -p "Install missing dependencies now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for dep in "${missing_deps[@]}"; do
                print_info "Installing $dep..."
                brew install "$dep" || print_warning "Failed to install $dep"
            done
        fi
    else
        print_success "All dependencies installed"
    fi

    # Language servers (optional)
    print_info "Language servers provide IDE features (autocomplete, diagnostics, etc.)"
    echo "Common language servers to install:"
    echo "  • TypeScript/JavaScript: npm install -g typescript typescript-language-server"
    echo "  • Python: pip install python-lsp-server"
    echo "  • Lua: brew install lua-language-server"
    echo "  • Rust: rustup component add rust-analyzer"
    echo "  • Go: go install golang.org/x/tools/gopls@latest"
    echo
    echo "Language servers will be automatically configured when installed"
}

# Initialize plugins
init_plugins() {
    print_header "Initializing Plugins"

    print_info "Launching Neovim to install plugins..."
    echo "This may take a minute on first run..."
    echo

    # Install plugins headlessly
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

    print_success "Plugins initialized"
    print_info "Run 'nvim' and use :Lazy to manage plugins"
}

# Generate help documentation
generate_docs() {
    print_header "Generating Documentation"

    cat > "$DOTFILES_DIR/nvim/KEYBINDINGS.md" << 'EOF'
# Neovim Keybindings Reference

## Leader Key
- **Space** - Leader key for custom commands

## General
- `<leader>nh` - Clear search highlights
- `<C-s>` - Save file (normal and insert mode)
- `<leader>qq` - Quit all
- `<leader>fm` - Format file with LSP

## Window Management
- `<leader>sv` - Split window vertically
- `<leader>sh` - Split window horizontally
- `<leader>se` - Make splits equal size
- `<leader>sx` - Close current split
- `<C-h/j/k/l>` - Navigate between windows
- `<C-Up/Down/Left/Right>` - Resize windows

## Buffer Navigation
- `<S-h>` - Previous buffer
- `<S-l>` - Next buffer
- `<leader>bd` - Delete buffer

## Tab Management
- `<leader>to` - Open new tab
- `<leader>tx` - Close current tab
- `<leader>tn` - Next tab
- `<leader>tp` - Previous tab
- `<leader>tf` - Open current buffer in new tab

## File Explorer (Neo-tree)
- `<leader>e` - Toggle file explorer
- `<leader>o` - Focus file explorer
- `a` - Add file/directory
- `d` - Delete
- `r` - Rename
- `y` - Copy
- `x` - Cut
- `p` - Paste

## Fuzzy Finding (Telescope)
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>fb` - Browse buffers
- `<leader>fh` - Help tags
- `<leader>fr` - Recent files
- `<leader>fc` - Find in current buffer

## LSP Features
- `gd` - Go to definition
- `gD` - Go to declaration
- `gi` - Go to implementation
- `gr` - Go to references
- `K` - Hover documentation
- `<leader>ca` - Code actions
- `<leader>rn` - Rename symbol
- `[d` - Previous diagnostic
- `]d` - Next diagnostic
- `<leader>e` - Show diagnostic message
- `<leader>q` - Diagnostic list

## Completion (in insert mode)
- `<C-Space>` - Trigger completion
- `<C-e>` - Abort completion
- `<Tab>` - Next item
- `<S-Tab>` - Previous item
- `<CR>` - Confirm selection

## Git Integration
- `<leader>gg` - Open lazygit
- `<leader>gb` - Git blame
- `<leader>gd` - Git diff

## Text Manipulation
- `<A-j>` - Move line down
- `<A-k>` - Move line up
- `<` / `>` - Indent/outdent (visual mode)
- `p` - Better paste (visual mode)

## Search and Replace
- `/` - Search forward
- `?` - Search backward
- `n` - Next match
- `N` - Previous match
- `*` - Search word under cursor

## Quick Fix
- `<leader>xn` - Next quickfix item
- `<leader>xp` - Previous quickfix item

EOF
    print_success "Created KEYBINDINGS.md"
}

# Post-installation setup
post_install() {
    print_header "Post-Installation Setup"

    echo "Neovim is ready! Next steps:"
    echo
    echo "1. Start Neovim:"
    echo "   nvim"
    echo
    echo "2. Check plugin status:"
    echo "   :Lazy"
    echo
    echo "3. Install/update language servers:"
    echo "   :Mason"
    echo
    echo "4. View keybindings:"
    echo "   cat $DOTFILES_DIR/nvim/KEYBINDINGS.md"
    echo
    echo "5. Customize further:"
    echo "   • User config: ~/.config/nvim/lua/user/"
    echo "   • Local overrides: ~/.config/nvim/init.lua.local"
    echo

    if [[ -d "$BACKUP_DIR" ]]; then
        print_info "Your original configuration is backed up at:"
        echo "  $BACKUP_DIR"
        echo "  Restore with: $BACKUP_DIR/restore.sh"
    fi
}

# Main installation
main() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        Neovim Setup Installation       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo

    print_info "This will set up a modern Neovim configuration with:"
    echo "  • LSP support for intelligent code completion"
    echo "  • Treesitter for syntax highlighting"
    echo "  • Telescope for fuzzy finding"
    echo "  • Neo-tree for file exploration"
    echo "  • Auto-completion and snippets"
    echo "  • Git integration"
    echo

    check_neovim || exit 1
    backup_existing || exit 1
    install_config || exit 1
    install_dependencies
    init_plugins
    generate_docs
    post_install

    print_success "Neovim setup complete! 🚀"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi