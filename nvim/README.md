# Neovim Configuration

Modern Neovim setup with LSP support, intelligent code completion, and developer productivity features.

## Features

- **LSP Support**: Full Language Server Protocol integration for intelligent code features
- **Treesitter**: Advanced syntax highlighting and code understanding
- **Telescope**: Powerful fuzzy finder for files, text, and more
- **Neo-tree**: Modern file explorer with git integration
- **Auto-completion**: Context-aware code completion with snippets
- **Git Integration**: Inline git signs, blame, and diff views
- **Which-key**: Interactive command discovery
- **Dashboard**: Custom startup screen with quick actions

## Installation

### Quick Setup

The Neovim configuration is automatically set up when you run the main dotfiles installation:

```bash
~/dotfiles/setup.sh
```

### Manual Installation

For standalone Neovim setup:

```bash
~/dotfiles/scripts/setup-neovim.sh
```

This script will:
- Backup any existing configuration
- Create proper symlinks to the dotfiles configuration
- Install plugin dependencies
- Initialize all plugins

### Prerequisites

Required:
- Neovim 0.9.0 or higher
- Git (for plugin management)

Recommended:
- Node.js (for many LSP servers and copilot)
- Ripgrep (`brew install ripgrep`) for Telescope grep
- fd (`brew install fd`) for better file finding
- A Nerd Font for icons (automatically installed by setup script)

## Configuration Structure

```
nvim/
├── init.lua                 # Main configuration entry
├── lua/
│   ├── config/
│   │   ├── options.lua     # Editor options
│   │   ├── keymaps.lua     # Key mappings
│   │   └── autocmds.lua    # Auto commands
│   └── plugins/
│       ├── lsp.lua         # LSP configuration
│       ├── cmp.lua         # Completion setup
│       ├── treesitter.lua  # Syntax highlighting
│       ├── telescope.lua   # Fuzzy finder
│       ├── neo-tree.lua    # File explorer
│       └── extras.lua      # Additional plugins
├── README.md               # This file
└── KEYBINDINGS.md         # Complete keybindings reference
```

## Key Bindings

Leader key is set to `Space`.

### Essential Shortcuts

| Key | Description |
|-----|-------------|
| `<leader>e` | Toggle file explorer |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Browse buffers |
| `K` | Show hover documentation |
| `gd` | Go to definition |
| `<leader>ca` | Code actions |
| `<leader>fm` | Format file |

See [KEYBINDINGS.md](KEYBINDINGS.md) for the complete list.

## Language Servers

The configuration automatically sets up language servers for common languages. Install them via Mason:

```vim
:Mason
```

Supported languages out of the box:
- TypeScript/JavaScript
- Python
- Lua
- Rust
- Go
- HTML/CSS
- JSON/YAML
- Bash
- Docker

### Installing Additional Language Servers

1. Open Neovim and run `:Mason`
2. Search for your language server (press `/`)
3. Install with `i`
4. The configuration will automatically detect and use it

### Manual Language Server Installation

```bash
# TypeScript/JavaScript
npm install -g typescript typescript-language-server

# Python
pip install python-lsp-server

# Lua
brew install lua-language-server

# Rust
rustup component add rust-analyzer

# Go
go install golang.org/x/tools/gopls@latest
```

## Plugin Management

Plugins are managed by [lazy.nvim](https://github.com/folke/lazy.nvim).

### Managing Plugins

- `:Lazy` - Open plugin manager
- `:Lazy sync` - Update all plugins
- `:Lazy install` - Install new plugins
- `:Lazy clean` - Remove unused plugins

### Adding Custom Plugins

Create a new file in `lua/plugins/` or add to `extras.lua`:

```lua
return {
  "username/plugin-name",
  config = function()
    -- Plugin configuration
  end,
}
```

## Customization

### User-specific Configuration

Create custom configurations without modifying the main setup:

1. **Local overrides**: Create `~/.config/nvim/lua/user/init.lua`
2. **Custom plugins**: Add files to `~/.config/nvim/lua/user/plugins/`
3. **Machine-specific**: Use `~/.config/nvim/init.lua.local`

### Changing Colorscheme

Edit `lua/plugins/extras.lua` and modify the tokyonight configuration, or add a new colorscheme plugin.

### Modifying Keybindings

Edit `lua/config/keymaps.lua` to change or add keybindings.

## Troubleshooting

### Common Issues

**Plugins not loading:**
```vim
:Lazy sync
```

**LSP not working:**
```vim
:Mason
" Install the required language server
:LspInfo
" Check LSP status
```

**Icons not displaying:**
- Ensure you have a Nerd Font installed and configured in your terminal
- Run `~/dotfiles/scripts/configure-terminal-fonts.sh`

**Slow startup:**
```vim
:Lazy profile
```

### Health Check

Run the built-in health check:
```vim
:checkhealth
```

### Backup and Restore

Your original configuration is automatically backed up during installation:

```bash
# Location of backup
~/.config/nvim.backup.[timestamp]/

# Restore original configuration
~/.config/nvim.backup.[timestamp]/restore.sh
```

## Performance

The configuration is optimized for performance:
- Lazy loading of plugins
- Minimal startup time (typically <100ms)
- Efficient LSP configuration
- Smart completion triggers

Check startup time:
```vim
:StartupTime
```

## Updates

Update the configuration:
```bash
cd ~/dotfiles
git pull
nvim +Lazy sync +qa
```

## Contributing

Improvements are welcome! The configuration follows these principles:
- Maintain fast startup time
- Use Lua for all configuration
- Lazy load plugins when possible
- Keep default vim behavior where sensible
- Document all non-obvious settings

## Resources

- [Neovim Documentation](https://neovim.io/doc/)
- [LSP Configuration](https://github.com/neovim/nvim-lspconfig)
- [Telescope](https://github.com/nvim-telescope/telescope.nvim)
- [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [Lazy.nvim](https://github.com/folke/lazy.nvim)

## License

This configuration is part of the dotfiles repository and follows the same license.