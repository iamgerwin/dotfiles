# Raycast Setup and Usage Guide

Raycast is a productivity launcher app that boosts efficiency for macOS users. This guide covers installation, initial setup, and recommended configurations.

## Installation

Raycast is installed automatically via Homebrew when running the dotfiles setup:

```bash
# Install via Homebrew (included in Brewfile)
brew install --cask raycast

# Or run the full dotfiles setup
cd ~/dotfiles
brew bundle install
```

## Initial Setup

### Basic Settings (Settings → General)

#### 1. Set the Hotkey

Set the shortcut key to launch Raycast.

- **Location**: Settings → General → Hotkey
- **Recommended**: `^ ^` (Press Control twice)

> **Tip**: Many users set this to `⌘ + Space` when using it as a Spotlight alternative

#### 2. Show in Menu Bar

Keep the Raycast icon in the menu bar for quick access.

- **Location**: Settings → General → Enable "Show Raycast in menu bar"

## Extension Hotkey Settings (Settings → Extensions)

Assign shortcuts to frequently used features for instant access.

| Function | Recommended Hotkeys | Purpose |
| --- | --- | --- |
| **Raycast Notes** | `⇧ + ⌘ + S` | Temporary notes for commands, branch names, quick reminders |
| **Clipboard History** | `⇧ + ⌘ + V` | Search through clipboard history with keywords |

> **Tip**: Clipboard History is incredibly useful because you can search its history. You can find previously copied text using keywords.

## Quick Links

Register frequently visited URLs or web services with hotkeys for instant access.

### Example Settings

| Name | URL/App | Alias | Hotkey |
| --- | --- | --- | --- |
| AI Feedback Form | Feedback URL | | `⇧ + ⌘ + F` |
| Open GitHub PR | `https://github.com/org/repo/pull/{Query}` | `pr` | |

### Setup Method

1. Open Raycast and search for "Create Quicklink"
2. Enter the name and URL
3. Assign a hotkey (optional)
4. Use `{Query}` placeholder for dynamic values (e.g., PR numbers)

## Window Management

Raycast includes built-in window management features for screen splitting and organization.

- **Half Screen**: Move windows to left/right/top/bottom half
- **Quarters**: Snap windows to screen corners
- **Maximize**: Full screen without entering macOS full screen mode
- **Center**: Center the active window

> **Tip**: Enable window management in Settings → Extensions → Window Management

## Fallback Commands (Settings → Manage Fallback Command)

Configure what happens when Raycast doesn't find a match for your query.

**Recommendations:**
- Set a web search as fallback (Google, DuckDuckGo, etc.)
- Uncheck "Enabled" for extensions you don't use to reduce noise

## Raycast AI

Raycast includes AI features for quick consultations and custom commands.

### Ask AI

Quickly consult AI via the tab key in Raycast.

### Custom AI Commands

Create personalized AI commands for repetitive tasks:

| Command | Prompt |
| --- | --- |
| **Branch Naming** | Generate a Git branch name from the following description. Choose a format below and convert to concise English kebab case: `feature/xxx-xxx`, `fix/xxx-xxx`, `chore/xxx-xxx`, `docs/xxx-xxx`, `refactor/xxx-xxx`. Description: `{argument}`. Output only the Git branch name. |
| **Translation** | Translate the following text. If Japanese, translate to English. If English, translate to Japanese. Output only the translated text. `{selection}` |
| **Word Definition** | Explain the meaning of the following word or phrase concisely. If technical, include software development context. Respond in Japanese. `{selection}` |

> **Note**: AI features require a Raycast Pro subscription or API key configuration. Anthropic's Haiku model is recommended for cost-effective usage (several hundred yen per month).

## Recommended Extensions

Install these extensions from the Raycast Store for enhanced productivity.

### UUID Generator

- **Purpose**: Generate random UUIDs
- **Use Cases**:
  - Generating IDs for test accounts
  - Creating test data identifiers

### Notion

- **Purpose**: Add data directly from Raycast to Notion
- **Use Cases**:
  - Instantly save ideas to a database
  - Quickly add tasks

### Other Useful Extensions

| Extension | Description |
| --- | --- |
| **GitHub** | Manage repositories, PRs, and issues |
| **Visual Studio Code** | Open recent projects and files |
| **Slack** | Search messages and set status |
| **1Password/LastPass** | Quick password lookup |
| **Brew** | Manage Homebrew packages |
| **Kill Process** | Quickly terminate unresponsive apps |
| **System Preferences** | Jump to specific preference panes |
| **Color Picker** | Pick colors from anywhere on screen |
| **Calculate** | Advanced calculations and conversions |

## Developer Extensions

For developers, these extensions integrate well with the dotfiles workflow:

| Extension | Description |
| --- | --- |
| **Docker** | Manage containers and images |
| **Homebrew** | Search and install packages |
| **npm** | Search npm packages |
| **Git Repos** | Quick access to local repositories |
| **SSH Connections** | Manage SSH connections |
| **JSON Format** | Format and validate JSON |
| **Base64** | Encode/decode Base64 strings |
| **Regex Tester** | Test regular expressions |

## Keyboard Shortcuts Reference

| Shortcut | Action |
| --- | --- |
| `⌘ + ,` | Open Raycast Settings |
| `⌘ + K` | Show available actions |
| `Tab` | Auto-complete / AI Chat |
| `⌘ + Enter` | Run in background |
| `⌘ + Shift + Enter` | Open in new window |
| `Esc` | Close Raycast |
| `⌘ + [` | Go back |

## Syncing Settings

Raycast Pro users can sync settings across machines:

1. Go to Settings → Advanced
2. Enable "Sync Settings"
3. Sign in with your Raycast account

For non-Pro users, consider exporting your configuration:
- Settings → Advanced → Export Settings

## Troubleshooting

### Raycast Not Launching

```bash
# Reinstall Raycast
brew reinstall raycast
```

### Hotkey Conflicts

If your hotkey doesn't work:
1. Check System Preferences → Keyboard → Shortcuts for conflicts
2. Disable conflicting Spotlight shortcut if using `⌘ + Space`

### Extensions Not Loading

```bash
# Clear Raycast cache
rm -rf ~/Library/Caches/com.raycast.macos
```

## Resources

- [Raycast Documentation](https://developers.raycast.com/)
- [Raycast Store](https://www.raycast.com/store)
- [Raycast Community](https://www.raycast.com/community)
- [Raycast GitHub](https://github.com/raycast)

## See Also

- [Brewfile](../Brewfile) - Package management including Raycast
- [README.md](../README.md) - Main dotfiles documentation
- [INSTALLATION.md](../INSTALLATION.md) - Full installation guide
