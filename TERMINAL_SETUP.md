# Terminal Setup Guide

This guide ensures your terminal displays all icons and symbols correctly with Powerlevel10k.

## Required Font

Powerlevel10k requires a Nerd Font to display icons properly. Without it, you'll see question marks or broken symbols in your prompt.

### Automatic Installation

The required font is included in the Brewfile and will be installed automatically:

```bash
brew bundle install
```

### Manual Font Installation

If you need to install the font manually:

```bash
brew install --cask font-meslo-lg-nerd-font
```

## Terminal Configuration

After installing the font, you need to configure your terminal to use it.

### iTerm2

1. Open iTerm2 Preferences (`⌘,`)
2. Go to **Profiles** → **Text**
3. Click **Change Font**
4. Select **MesloLGS NF** or **MesloLGS Nerd Font**
5. Set size to 12-14pt (adjust to preference)
6. Restart iTerm2

### Terminal.app (macOS Built-in)

1. Open Terminal Preferences (`⌘,`)
2. Go to **Profiles**
3. Select your profile and click **Font**
4. Choose **MesloLGS NF Regular**
5. Set size to 12-14pt
6. Close and reopen Terminal

### Warp

1. Open Warp Settings (`⌘,`)
2. Go to **Appearance** → **Text**
3. Under **Font**, select **MesloLGS NF**
4. Adjust size as needed
5. Changes apply immediately

### Visual Studio Code (Integrated Terminal)

Add to your VS Code settings.json:

```json
{
  "terminal.integrated.fontFamily": "MesloLGS NF",
  "terminal.integrated.fontSize": 13
}
```

Or via UI:
1. Open Settings (`⌘,`)
2. Search for "terminal font"
3. Set **Terminal › Integrated: Font Family** to `MesloLGS NF`

### Zed

1. Open Zed Settings (`⌘,`)
2. Add to your settings:

```json
{
  "terminal": {
    "font_family": "MesloLGS NF",
    "font_size": 13
  }
}
```

### Windsurf

1. Open Windsurf Settings
2. Navigate to Terminal settings
3. Set font to **MesloLGS NF**

## Verification

After configuring your terminal, verify the font is working:

```bash
echo "✓ Check ✗ Error ⚡ Power → Arrow ± Plus/Minus"
```

You should see all symbols clearly without any question marks.

## Powerlevel10k Configuration

If you haven't configured Powerlevel10k yet:

```bash
p10k configure
```

This will walk you through prompt customization. When asked about font installation, you can skip it since we've already installed MesloLGS NF.

## Troubleshooting

### Still seeing broken symbols?

1. **Verify font installation**:
   ```bash
   ls ~/Library/Fonts | grep -i meslo
   ```

2. **Restart your terminal** completely (Quit and reopen, not just close window)

3. **Clear font cache** (if needed):
   ```bash
   sudo atsutil databases -remove
   sudo atsutil server -shutdown
   sudo atsutil server -ping
   ```

4. **Check terminal encoding**: Ensure UTF-8 encoding is set in terminal preferences

### Wrong font selected?

The exact font name might vary:
- **MesloLGS NF**
- **MesloLGS Nerd Font**
- **MesloLGS NF Regular**
- **MesloLGSNerdFont-Regular**

Try different variations if one doesn't work.

### Icons too small/large?

Adjust the font size in your terminal settings. Typically 12-14pt works well, but this depends on your display and preferences.

## Alternative Fonts

If you prefer different fonts that also work with Powerlevel10k:

```bash
# JetBrains Mono
brew install --cask font-jetbrains-mono-nerd-font

# Fira Code (already in Brewfile)
brew install --cask font-fira-code-nerd-font

# Hack
brew install --cask font-hack-nerd-font
```

Just remember to configure your terminal to use the font you've installed.