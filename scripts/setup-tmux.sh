#!/usr/bin/env bash
# Tmux Setup Script
# Installs and configures tmux with plugins

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

print_info "Setting up tmux configuration..."

# Create backup directory with timestamp
BACKUP_DIR="$HOME/.dotfiles-backup/tmux-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
print_info "Creating backups in $BACKUP_DIR"

# Backup existing tmux configuration files if they exist
if [ -f "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
    cp -P "$HOME/.tmux.conf" "$BACKUP_DIR/.tmux.conf.backup" 2>/dev/null || true
    print_success "Backed up existing .tmux.conf"
fi

if [ -d "$HOME/.tmux" ]; then
    cp -r "$HOME/.tmux" "$BACKUP_DIR/.tmux.backup" 2>/dev/null || true
    print_success "Backed up existing .tmux directory"
fi

# Create backup manifest
cat > "$BACKUP_DIR/manifest.json" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "type": "tmux-setup",
  "files_backed_up": [
    ".tmux.conf",
    ".tmux/"
  ],
  "restore_command": "~/dotfiles/scripts/uninstall.sh restore-tmux $BACKUP_DIR"
}
EOF
print_success "Created backup manifest"

# Create tmux config directory if it doesn't exist
if [ ! -d "$HOME/.tmux" ]; then
    mkdir -p "$HOME/.tmux"
    print_success "Created ~/.tmux directory"
fi

# Create plugins directory
if [ ! -d "$HOME/.tmux/plugins" ]; then
    mkdir -p "$HOME/.tmux/plugins"
    print_success "Created ~/.tmux/plugins directory"
fi

# Create layouts directory for saved layouts
if [ ! -d "$HOME/.tmux/layouts" ]; then
    mkdir -p "$HOME/.tmux/layouts"
    print_success "Created ~/.tmux/layouts directory"
fi

# Create scripts directory for tmux scripts
if [ ! -d "$HOME/.tmux/scripts" ]; then
    mkdir -p "$HOME/.tmux/scripts"
    print_success "Created ~/.tmux/scripts directory"
fi

# Backup existing tmux.conf if it exists and is not a symlink
if [ -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
    backup_file="$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)"
    mv "$HOME/.tmux.conf" "$backup_file"
    print_success "Backed up existing .tmux.conf to $backup_file"
fi

# Create symlink to tmux.conf
DOTFILES_DIR="$HOME/dotfiles"
if [ -f "$DOTFILES_DIR/tmux.conf" ]; then
    ln -sf "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
    print_success "Created symlink for .tmux.conf"
else
    print_error "tmux.conf not found in $DOTFILES_DIR"
    exit 1
fi

# Install Tmux Plugin Manager (TPM) if not already installed
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    print_info "Installing Tmux Plugin Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    print_success "TPM installed successfully"
else
    print_success "TPM is already installed"
    # Update TPM
    print_info "Updating TPM..."
    cd "$TPM_DIR" && git pull
    print_success "TPM updated"
fi

# Create development session script
cat > "$HOME/.tmux/scripts/dev-session.sh" << 'EOF'
#!/bin/bash
# Development session with predefined layout

SESSION_NAME="dev"

# Check if session exists
tmux has-session -t $SESSION_NAME 2>/dev/null

if [ $? != 0 ]; then
    # Create new session
    tmux new-session -d -s $SESSION_NAME -n editor
    
    # Window 1: Editor
    tmux send-keys -t $SESSION_NAME:editor "cd ~/projects && vim" C-m
    
    # Window 2: Server
    tmux new-window -t $SESSION_NAME -n server
    tmux send-keys -t $SESSION_NAME:server "cd ~/projects" C-m
    
    # Window 3: Git
    tmux new-window -t $SESSION_NAME -n git
    tmux send-keys -t $SESSION_NAME:git "cd ~/projects && git status" C-m
    
    # Window 4: Docker
    tmux new-window -t $SESSION_NAME -n docker
    tmux split-window -h -t $SESSION_NAME:docker
    tmux send-keys -t $SESSION_NAME:docker.0 "docker ps" C-m
    
    # Select default window
    tmux select-window -t $SESSION_NAME:editor
fi

# Attach to session
tmux attach-session -t $SESSION_NAME
EOF

chmod +x "$HOME/.tmux/scripts/dev-session.sh"
print_success "Created development session script"

# Create project launcher script
cat > "$HOME/.tmux/scripts/project-launcher.sh" << 'EOF'
#!/bin/bash
# Launch project-specific tmux sessions

launch_project() {
    local project_name=$1
    local project_path=$2
    
    tmux new-session -d -s $project_name -c $project_path
    
    # Main editor window
    tmux rename-window -t $project_name:1 'editor'
    tmux send-keys -t $project_name:editor "vim ." C-m
    
    # Terminal window
    tmux new-window -t $project_name -n 'terminal' -c $project_path
    
    # Tests window
    tmux new-window -t $project_name -n 'tests' -c $project_path
    
    # Logs window
    tmux new-window -t $project_name -n 'logs' -c $project_path
    tmux split-window -h -t $project_name:logs
    
    tmux select-window -t $project_name:editor
}

# Usage
case $1 in
    *)
        if [ -z "$1" ] || [ -z "$2" ]; then
            echo "Usage: $0 <project-name> <project-path>"
            exit 1
        fi
        launch_project "$1" "$2"
        tmux attach-session -t $1
        ;;
esac
EOF

chmod +x "$HOME/.tmux/scripts/project-launcher.sh"
print_success "Created project launcher script"

# Add tmux aliases to aliases.zsh if not already present
ALIASES_FILE="$DOTFILES_DIR/aliases.zsh"
if [ -f "$ALIASES_FILE" ]; then
    # Check if tmux aliases section exists
    if ! grep -q "# Tmux aliases" "$ALIASES_FILE"; then
        echo "" >> "$ALIASES_FILE"
        echo "# Tmux aliases" >> "$ALIASES_FILE"
        echo "alias ta='tmux attach -t'" >> "$ALIASES_FILE"
        echo "alias tad='tmux attach -d -t'" >> "$ALIASES_FILE"
        echo "alias ts='tmux new-session -s'" >> "$ALIASES_FILE"
        echo "alias tl='tmux list-sessions'" >> "$ALIASES_FILE"
        echo "alias tksv='tmux kill-server'" >> "$ALIASES_FILE"
        echo "alias tkss='tmux kill-session -t'" >> "$ALIASES_FILE"
        echo "alias tmuxconf='$EDITOR ~/.tmux.conf'" >> "$ALIASES_FILE"
        echo "alias tdev='~/.tmux/scripts/dev-session.sh'" >> "$ALIASES_FILE"
        echo "alias tproject='~/.tmux/scripts/project-launcher.sh'" >> "$ALIASES_FILE"
        print_success "Added tmux aliases to aliases.zsh"
    else
        print_info "Tmux aliases already exist in aliases.zsh"
    fi
fi

# Check if tmux is installed
if command -v tmux &> /dev/null; then
    print_success "Tmux is installed (version: $(tmux -V))"
    
    # Install plugins if tmux is running
    print_info "Installing tmux plugins..."
    print_info "Start tmux and press 'Prefix + I' (Ctrl-a then Shift-i) to install plugins"
    
    # Try to install plugins automatically if tmux server is not running
    if ! tmux list-sessions &> /dev/null; then
        tmux new-session -d -s temp
        sleep 2
        tmux send-keys -t temp "~/.tmux/plugins/tpm/bin/install_plugins" C-m
        sleep 5
        tmux kill-session -t temp
        print_success "Attempted automatic plugin installation"
    fi
else
    print_error "Tmux is not installed. Run 'brew install tmux' first"
    exit 1
fi

echo ""
print_success "Tmux setup complete!"
echo ""
print_info "Next steps:"
echo "  1. Start a new tmux session: tmux new -s main"
echo "  2. Install plugins manually: Press Ctrl-a then Shift-i"
echo "  3. Try the dev session: tdev"
echo "  4. Create a project session: tproject <name> <path>"
echo "  5. List sessions: tmux ls"
echo ""
print_info "Quick shortcuts:"
echo "  • Prefix key: Ctrl-a"
echo "  • Split horizontal: Ctrl-a |"
echo "  • Split vertical: Ctrl-a -"
echo "  • Navigate panes: Ctrl-a h/j/k/l"
echo "  • Zoom pane: Ctrl-a z"
echo "  • Reload config: Ctrl-a r"