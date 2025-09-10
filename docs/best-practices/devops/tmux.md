# Tmux Best Practices

## Overview
Tmux (Terminal Multiplexer) is a powerful tool that enables multiple terminal sessions within a single window. These best practices help maximize productivity, maintain persistent sessions, and create efficient development workflows.

## Configuration

### Basic Tmux Configuration
```bash
# ~/.tmux.conf

# Set prefix to Ctrl-a (easier to reach than Ctrl-b)
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Enable 256 colors and true color support
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Set scrollback buffer size
set -g history-limit 50000

# Enable mouse support
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Set escape time (for vim)
set -sg escape-time 0

# Enable vi mode
setw -g mode-keys vi

# Status bar update interval
set -g status-interval 5

# Enable focus events
set -g focus-events on

# Aggressive resize
setw -g aggressive-resize on

# Set terminal title
set -g set-titles on
set -g set-titles-string '#H:#S.#I.#P #W #T'

# Activity monitoring
setw -g monitor-activity on
set -g visual-activity off
```

### Key Bindings
```bash
# ~/.tmux.conf - Key bindings section

# Reload configuration
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Split panes using | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Navigate panes with vim-like keys
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Resize panes with vim-like keys
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Quick pane cycling
bind -r Tab select-pane -t :.+

# Window navigation
bind -r C-h select-window -t :-
bind -r C-l select-window -t :+

# Move windows left/right
bind -r < swap-window -t -1 \; select-window -t -1
bind -r > swap-window -t +1 \; select-window -t +1

# Synchronize panes
bind S setw synchronize-panes

# Copy mode bindings (vi-style)
bind Enter copy-mode
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
bind -T copy-mode-vi r send-keys -X rectangle-toggle

# Paste buffer
bind p paste-buffer
bind P choose-buffer

# Clear history
bind -n C-k clear-history

# Layout shortcuts
bind M-1 select-layout main-horizontal
bind M-2 select-layout main-vertical
bind M-3 select-layout even-horizontal
bind M-4 select-layout even-vertical
bind M-5 select-layout tiled

# Toggle pane zoom
bind z resize-pane -Z

# Break pane into window
bind b break-pane -d

# Join pane from window
bind-key j command-prompt -p "join pane from:"  "join-pane -s '%%'"
bind-key s command-prompt -p "send pane to:"  "join-pane -t '%%'"
```

## Status Bar Customization

### Enhanced Status Bar
```bash
# ~/.tmux.conf - Status bar configuration

# Status bar position
set -g status-position bottom

# Status bar colors
set -g status-style 'bg=#1e2030 fg=#82aaff'

# Status left
set -g status-left-length 50
set -g status-left '#[fg=#c3e88d,bold] #S #[fg=#82aaff]#I:#P '

# Status right
set -g status-right-length 100
set -g status-right '#[fg=#ffcb6b] %a %Y-%m-%d #[fg=#c3e88d] %H:%M:%S #[fg=#82aaff]#(whoami)@#H '

# Window status
setw -g window-status-format '#[fg=#585b70] #I:#W#F '
setw -g window-status-current-format '#[fg=#f38ba8,bold] #I:#W#F '

# Message style
set -g message-style 'fg=#c3e88d bg=#1e2030 bold'

# Pane borders
set -g pane-border-style 'fg=#585b70'
set -g pane-active-border-style 'fg=#82aaff'

# Display panes
set -g display-panes-active-colour '#c3e88d'
set -g display-panes-colour '#585b70'
```

### Status Bar with System Information
```bash
# Advanced status bar with system info
set -g status-right '#[fg=#ffcb6b]CPU: #(top -l 1 | grep "CPU usage" | awk "{print $3}") \
#[fg=#c3e88d]MEM: #(top -l 1 | grep "PhysMem" | awk "{print $2}") \
#[fg=#89ddff]LOAD: #(uptime | rev | cut -d":" -f1 | rev | sed "s/, / /g") \
#[fg=#f38ba8]%H:%M '
```

## Session Management

### Session Scripts
```bash
#!/bin/bash
# ~/.tmux/scripts/dev-session.sh
# Create a development session with predefined layout

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
    tmux send-keys -t $SESSION_NAME:server "cd ~/projects && npm run dev" C-m
    
    # Window 3: Git
    tmux new-window -t $SESSION_NAME -n git
    tmux send-keys -t $SESSION_NAME:git "cd ~/projects && git status" C-m
    
    # Window 4: Docker
    tmux new-window -t $SESSION_NAME -n docker
    tmux split-window -h -t $SESSION_NAME:docker
    tmux send-keys -t $SESSION_NAME:docker.0 "docker ps" C-m
    tmux send-keys -t $SESSION_NAME:docker.1 "docker logs -f app" C-m
    
    # Window 5: Monitoring
    tmux new-window -t $SESSION_NAME -n monitor
    tmux split-window -h -t $SESSION_NAME:monitor
    tmux split-window -v -t $SESSION_NAME:monitor.0
    tmux send-keys -t $SESSION_NAME:monitor.0 "htop" C-m
    tmux send-keys -t $SESSION_NAME:monitor.1 "watch -n 1 'netstat -an | grep ESTABLISHED | wc -l'" C-m
    tmux send-keys -t $SESSION_NAME:monitor.2 "tail -f /var/log/system.log" C-m
    
    # Select default window
    tmux select-window -t $SESSION_NAME:editor
fi

# Attach to session
tmux attach-session -t $SESSION_NAME
```

### Project-Specific Sessions
```bash
#!/bin/bash
# ~/.tmux/scripts/project-launcher.sh
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
    tmux send-keys -t $project_name:tests "npm test -- --watch" C-m
    
    # Logs window
    tmux new-window -t $project_name -n 'logs' -c $project_path
    tmux split-window -h -t $project_name:logs
    
    # Database window (if applicable)
    if [ -f "$project_path/docker-compose.yml" ]; then
        tmux new-window -t $project_name -n 'database' -c $project_path
        tmux send-keys -t $project_name:database "docker-compose up -d && docker-compose logs -f db" C-m
    fi
    
    tmux select-window -t $project_name:editor
}

# Usage
case $1 in
    frontend)
        launch_project "frontend" "~/projects/frontend"
        ;;
    backend)
        launch_project "backend" "~/projects/backend"
        ;;
    fullstack)
        launch_project "fullstack" "~/projects/fullstack"
        ;;
    *)
        echo "Usage: $0 {frontend|backend|fullstack}"
        exit 1
        ;;
esac

tmux attach-session -t $1
```

## Pane Management

### Layout Templates
```bash
# ~/.tmux/layouts/development.sh
#!/bin/bash
# Create a development layout

# Create main horizontal split
tmux split-window -h -p 30

# Create bottom pane on the right
tmux split-window -v -p 30

# Select main pane
tmux select-pane -t 0

# Set pane titles
tmux select-pane -t 0 -T "Editor"
tmux select-pane -t 1 -T "Terminal"
tmux select-pane -t 2 -T "Logs"

# Enable pane borders with titles
tmux set -g pane-border-status top
tmux set -g pane-border-format "#{pane_index}: #{pane_title}"
```

### Smart Pane Navigation
```bash
# ~/.tmux.conf - Smart pane switching with awareness of Vim splits

# Smart pane switching with awareness of Vim splits
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"

bind-key -n C-h if-shell "$is_vim" "send-keys C-h"  "select-pane -L"
bind-key -n C-j if-shell "$is_vim" "send-keys C-j"  "select-pane -D"
bind-key -n C-k if-shell "$is_vim" "send-keys C-k"  "select-pane -U"
bind-key -n C-l if-shell "$is_vim" "send-keys C-l"  "select-pane -R"
```

## Copy Mode and Clipboard

### System Clipboard Integration
```bash
# ~/.tmux.conf - macOS clipboard integration

# Copy to system clipboard
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

# Linux clipboard integration (requires xclip)
# bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"

# Windows WSL clipboard integration
# bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "clip.exe"
```

### Enhanced Copy Mode
```bash
# ~/.tmux.conf - Enhanced copy mode

# Enter copy mode with Prefix + [
bind [ copy-mode

# Search in copy mode
bind / copy-mode \; send-keys ?

# Quick scrolling
bind -T copy-mode-vi C-u send-keys -X halfpage-up
bind -T copy-mode-vi C-d send-keys -X halfpage-down

# Select entire line
bind -T copy-mode-vi V send-keys -X select-line

# Copy current command line
bind Y run-shell "tmux show-buffer | pbcopy" \; display-message "Copied to clipboard"
```

## Plugins

### Tmux Plugin Manager (TPM)
```bash
# ~/.tmux.conf - Plugin configuration

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-copycat'
set -g @plugin 'tmux-plugins/tmux-open'
set -g @plugin 'tmux-plugins/tmux-pain-control'
set -g @plugin 'christoomey/vim-tmux-navigator'
set -g @plugin 'tmux-plugins/tmux-battery'
set -g @plugin 'tmux-plugins/tmux-cpu'
set -g @plugin 'tmux-plugins/tmux-prefix-highlight'

# Plugin configurations
set -g @resurrect-save 'S'
set -g @resurrect-restore 'R'
set -g @resurrect-strategy-vim 'session'
set -g @resurrect-capture-pane-contents 'on'

set -g @continuum-restore 'on'
set -g @continuum-boot 'on'
set -g @continuum-save-interval '15'

set -g @prefix_highlight_show_copy_mode 'on'
set -g @prefix_highlight_show_sync_mode 'on'

# Initialize TMUX plugin manager
run '~/.tmux/plugins/tpm/tpm'
```

### Install TPM
```bash
# Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install plugins (inside tmux)
# Press prefix + I
```

## Remote Development

### SSH and Tmux
```bash
#!/bin/bash
# ~/.local/bin/ssh-tmux
# Automatically attach to tmux session on SSH

ssh_tmux() {
    local host=$1
    shift
    ssh -t $host "tmux attach-session -t main || tmux new-session -s main" $@
}

# Usage: ssh-tmux user@host
ssh_tmux $@
```

### Nested Tmux Sessions
```bash
# ~/.tmux.conf - Handle nested tmux sessions

# Toggle on/off all keybindings (for nested tmux)
bind -T root F12  \
  set prefix None \;\
  set key-table off \;\
  set status-style "fg=colour245,bg=colour238" \;\
  if -F '#{pane_in_mode}' 'send-keys -X cancel' \;\
  refresh-client -S \;\

bind -T off F12 \
  set -u prefix \;\
  set -u key-table \;\
  set -u status-style \;\
  refresh-client -S
```

## Automation and Scripting

### Tmux Scripting Functions
```bash
# ~/.bashrc or ~/.zshrc - Tmux helper functions

# Kill all tmux sessions except the current one
tmux-kill-all-but-current() {
    tmux list-sessions | grep -v attached | cut -d: -f1 | xargs -I {} tmux kill-session -t {}
}

# Save tmux history to file
tmux-save-history() {
    local pane=${1:-0}
    local file=${2:-~/tmux-history-$(date +%Y%m%d-%H%M%S).txt}
    tmux capture-pane -pS -1000000 -t $pane > $file
    echo "History saved to $file"
}

# Create new window with specific command
tmux-new-window() {
    local name=$1
    local cmd=$2
    tmux new-window -n "$name" "$cmd"
}

# Quick session switcher
tmux-switch() {
    local session=$(tmux list-sessions -F "#{session_name}" | fzf)
    tmux switch-client -t $session
}

# Tmux layout saver
tmux-save-layout() {
    tmux display-message -p '#{window_layout}' > ~/.tmux/layouts/$(tmux display-message -p '#S-#W').layout
}

# Tmux layout loader
tmux-load-layout() {
    local layout_file=~/.tmux/layouts/$1.layout
    if [ -f $layout_file ]; then
        tmux select-layout "$(cat $layout_file)"
    else
        echo "Layout file not found: $layout_file"
    fi
}
```

## Pair Programming

### Shared Sessions
```bash
#!/bin/bash
# Setup for pair programming

# Create a new session for pairing
tmux new-session -d -s pair

# Set more permissive socket
tmux -S /tmp/tmux-pair new -d -s pair

# Allow others to attach (set appropriate permissions)
chmod 777 /tmp/tmux-pair

# Others can attach with:
# tmux -S /tmp/tmux-pair attach -t pair
```

### Read-Only Sessions
```bash
# Create read-only session
tmux new-session -d -s main
tmux new-session -t main -s read-only -d

# Make read-only
tmux set-option -t read-only key-table off
tmux set-option -t read-only status off
```

## Monitoring and Debugging

### Session Monitoring
```bash
#!/bin/bash
# Monitor tmux sessions

monitor_sessions() {
    while true; do
        clear
        echo "=== Tmux Sessions ==="
        tmux list-sessions 2>/dev/null || echo "No sessions"
        
        echo -e "\n=== Windows ==="
        tmux list-windows -a 2>/dev/null || echo "No windows"
        
        echo -e "\n=== Panes ==="
        tmux list-panes -a 2>/dev/null || echo "No panes"
        
        sleep 5
    done
}

# Show tmux environment
show_tmux_env() {
    echo "=== Tmux Environment ==="
    tmux show-environment
    
    echo -e "\n=== Global Options ==="
    tmux show-options -g
    
    echo -e "\n=== Window Options ==="
    tmux show-window-options -g
}
```

## Performance Optimization

### Optimized Settings
```bash
# ~/.tmux.conf - Performance optimizations

# Reduce escape time
set -s escape-time 0

# Increase repeat time
set -g repeat-time 600

# Reduce display time
set -g display-time 2000
set -g display-panes-time 2000

# Optimize for fast terminals
set -g assume-paste-time 0

# Don't exit copy mode on mouse release
unbind -T copy-mode-vi MouseDragEnd1Pane

# Limit buffer size
set -g buffer-limit 20

# Set update environment
set -g update-environment "DISPLAY SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY"
```

## Troubleshooting

### Common Issues and Solutions
```bash
# Fix corrupted sessions
tmux kill-server

# Fix display issues
tmux refresh-client

# Reset tmux completely
rm -rf ~/.tmux/resurrect/*
tmux kill-server

# Debug configuration
tmux source-file ~/.tmux.conf -v

# Show current bindings
tmux list-keys

# Show current options
tmux show-options -g
```

## Best Practices Summary

1. **Use Session Names**: Always name your sessions meaningfully
2. **Persistent Sessions**: Use tmux-resurrect for session persistence
3. **Keyboard Shortcuts**: Customize shortcuts for your workflow
4. **Status Bar**: Configure informative status bar
5. **Copy Mode**: Master copy mode for efficient text manipulation
6. **Pane Layouts**: Save and reuse layouts for different tasks
7. **Automation**: Create scripts for repetitive setups
8. **Remote Work**: Use tmux for persistent remote sessions
9. **Plugins**: Leverage plugins for enhanced functionality
10. **Regular Backups**: Backup your tmux configuration

## Conclusion

Tmux is an essential tool for terminal-based development workflows. These best practices help create efficient, persistent, and customizable terminal environments that significantly boost productivity.