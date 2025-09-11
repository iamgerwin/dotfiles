#!/usr/bin/env bash
# Configure terminal fonts for iTerm2 and Terminal.app
# This script attempts to automatically set MesloLGS NF as the default font

set -e

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

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is intended for macOS only"
    exit 1
fi

print_info "Configuring terminal fonts for optimal Powerlevel10k display..."

# Check if MesloLGS NF font is installed
FONT_INSTALLED=false
if ls ~/Library/Fonts 2>/dev/null | grep -qi "meslo.*nerd" || \
   ls /Library/Fonts 2>/dev/null | grep -qi "meslo.*nerd" || \
   ls /System/Library/Fonts 2>/dev/null | grep -qi "meslo.*nerd"; then
    FONT_INSTALLED=true
    print_success "MesloLGS NF font found in system"
else
    print_warning "MesloLGS NF font not found. Installing..."
    if command -v brew &> /dev/null; then
        brew install --cask font-meslo-lg-nerd-font font-meslo-for-powerlevel10k
        FONT_INSTALLED=true
        print_success "Fonts installed via Homebrew"
    else
        print_error "Homebrew not found. Please install fonts manually:"
        echo "  brew install --cask font-meslo-lg-nerd-font font-meslo-for-powerlevel10k"
        exit 1
    fi
fi

if [[ "$FONT_INSTALLED" == "true" ]]; then
    # Configure iTerm2
    if [[ -d "/Applications/iTerm.app" ]]; then
        print_info "Configuring iTerm2 font settings..."
        
        # Set iTerm2 font using defaults (this affects the Default profile)
        defaults write com.googlecode.iterm2 "New Bookmarks" -array-add '{
            "Name" = "Powerlevel10k Profile";
            "Normal Font" = "MesloLGS-NF-Regular 12";
            "Non Ascii Font" = "MesloLGS-NF-Regular 12";
        }'
        
        # Also set for the default profile
        defaults write com.googlecode.iterm2 "Normal Font" "MesloLGS-NF-Regular 12"
        defaults write com.googlecode.iterm2 "Non Ascii Font" "MesloLGS-NF-Regular 12"
        
        print_success "iTerm2 font configured (restart iTerm2 to apply)"
    else
        print_info "iTerm2 not found, skipping configuration"
    fi
    
    # Configure Terminal.app
    print_info "Configuring Terminal.app font settings..."
    
    # Create a custom Terminal profile with the correct font
    osascript <<EOF 2>/dev/null || print_warning "Could not automatically configure Terminal.app"
tell application "Terminal"
    try
        -- Create new settings set
        set newProfile to (make new settings set with properties {name:"Powerlevel10k"})
        
        -- Set font properties
        set font name of newProfile to "MesloLGS NF"
        set font size of newProfile to 12
        
        -- Set as default
        set default settings to newProfile
        
        -- Also set for startup
        set startup settings to newProfile
        
    on error
        -- Profile might already exist, try to modify it
        try
            set existingProfile to settings set "Powerlevel10k"
            set font name of existingProfile to "MesloLGS NF"
            set font size of existingProfile to 12
            set default settings to existingProfile
            set startup settings to existingProfile
        end try
    end try
end tell
EOF
    
    print_success "Terminal.app font configured"
    
    # Configure Warp terminal if present
    if [[ -d "/Applications/Warp.app" ]]; then
        print_info "Configuring Warp terminal font settings..."
        
        # Create Warp config directory if it doesn't exist
        mkdir -p ~/.warp/themes
        
        # Create a custom theme with MesloLGS NF font
        cat > ~/.warp/themes/powerlevel10k.yaml <<EOF
name: Powerlevel10k
details:
  author: Dotfiles
  description: Optimized for Powerlevel10k theme
font:
  name: MesloLGS NF
  size: 12
EOF
        print_success "Warp terminal theme created (apply manually in settings)"
    fi
    
    echo
    print_success "Terminal font configuration completed!"
    echo
    print_info "Next steps:"
    echo "  1. Restart your terminal applications"
    echo "  2. For iTerm2: Check Preferences > Profiles > Text"
    echo "  3. For Terminal.app: The 'Powerlevel10k' profile should be set as default"
    echo "  4. For Warp: Go to Settings > Appearance > Theme and select 'powerlevel10k'"
    echo "  5. Run 'p10k configure' to set up your prompt"
    
else
    print_error "Font installation failed. Please install manually and rerun this script."
fi