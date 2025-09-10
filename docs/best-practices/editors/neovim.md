# Neovim Best Practices

## Official Documentation
- **Neovim Documentation**: https://neovim.io/doc/
- **Neovim GitHub**: https://github.com/neovim/neovim
- **Vim Documentation**: https://vimhelp.org/
- **Neovim Lua Guide**: https://neovim.io/doc/user/lua-guide.html

## Installation

### macOS
```bash
# Homebrew
brew install neovim

# Required dependencies
brew install ripgrep fd lazygit
brew install node npm # For LSP servers
brew install python3 pip3 # For Python providers
```

### Linux
```bash
# Ubuntu/Debian
sudo apt install neovim

# Arch
sudo pacman -S neovim

# From source
git clone https://github.com/neovim/neovim
cd neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
```

## Configuration Structure

### Modern Lua Configuration
```
~/.config/nvim/
├── init.lua                 # Entry point
├── lazy-lock.json          # Plugin lock file
├── lua/
│   ├── config/
│   │   ├── autocmds.lua   # Auto commands
│   │   ├── keymaps.lua    # Key mappings
│   │   ├── lazy.lua       # Plugin manager setup
│   │   └── options.lua    # Editor options
│   └── plugins/
│       ├── colorscheme.lua
│       ├── lsp.lua
│       ├── completion.lua
│       ├── telescope.lua
│       ├── treesitter.lua
│       ├── git.lua
│       ├── ui.lua
│       └── tools.lua
```

## Core Configuration

### init.lua
```lua
-- ~/.config/nvim/init.lua

-- Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load core configuration
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
```

### Options Configuration
```lua
-- lua/config/options.lua

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true
opt.numberwidth = 4

-- Tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Line wrapping
opt.wrap = false
opt.linebreak = true

-- Search settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Cursor line
opt.cursorline = true
opt.cursorcolumn = false

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.colorcolumn = "80,120"
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Backspace
opt.backspace = "indent,eol,start"

-- Clipboard
opt.clipboard:append("unnamedplus")

-- Split windows
opt.splitright = true
opt.splitbelow = true

-- Backup and swap
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- Performance
opt.updatetime = 50
opt.timeoutlen = 300
opt.lazyredraw = true

-- Completion
opt.completeopt = "menuone,noselect"
opt.pumheight = 10

-- Folding
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldenable = false
opt.foldlevel = 99
```

## Essential Plugins

### Plugin Manager Setup (Lazy.nvim)
```lua
-- lua/config/lazy.lua

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = {
    colorscheme = { "tokyonight", "catppuccin" },
  },
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
```

### Essential Plugin List
```lua
-- lua/plugins/essentials.lua

return {
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme tokyonight-night]])
    end,
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 30,
          side = "left",
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = false,
        },
      })
    end,
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Explorer" },
    },
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { 
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      
      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
          },
        },
      })
      
      telescope.load_extension("fzf")
    end,
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
    },
  },

  -- Syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { 
          "lua", "vim", "vimdoc", "javascript", "typescript", 
          "python", "rust", "go", "html", "css", "json", 
          "yaml", "markdown", "markdown_inline", "bash"
        },
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },
      })
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
          section_separators = { left = "", right = "" },
          component_separators = { left = "", right = "" },
        },
      })
    end,
  },

  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "▎" },
          change = { text = "▎" },
          delete = { text = "" },
          topdelete = { text = "" },
          changedelete = { text = "▎" },
        },
      })
    end,
  },

  -- Which-key
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    config = function()
      require("which-key").setup()
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- Comment
  {
    "numToStr/Comment.nvim",
    config = true,
    keys = {
      { "gcc", desc = "Comment line" },
      { "gc", mode = "v", desc = "Comment selection" },
    },
  },

  -- Surround
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = true,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      require("ibl").setup({
        indent = { char = "┊" },
      })
    end,
  },
}
```

## LSP Configuration

### LSP Setup
```lua
-- lua/plugins/lsp.lua

return {
  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "folke/neodev.nvim",
    },
    config = function()
      require("neodev").setup()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "tsserver",
          "html",
          "cssls",
          "tailwindcss",
          "jsonls",
          "eslint",
          "pyright",
          "rust_analyzer",
          "gopls",
        },
      })

      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Lua
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      -- TypeScript/JavaScript
      lspconfig.tsserver.setup({
        capabilities = capabilities,
      })

      -- Python
      lspconfig.pyright.setup({
        capabilities = capabilities,
      })

      -- Rust
      lspconfig.rust_analyzer.setup({
        capabilities = capabilities,
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
          },
        },
      })

      -- Go
      lspconfig.gopls.setup({
        capabilities = capabilities,
      })

      -- Keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, opts)
        end,
      })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },
}
```

## Key Mappings

### Essential Keymaps
```lua
-- lua/config/keymaps.lua

local keymap = vim.keymap

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- General keymaps
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode" })
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })
keymap.set("n", "x", '"_x', { desc = "Delete without yanking" })

-- Increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" })
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

-- Window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

-- Tab management
keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })

-- Move text up and down
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move text down" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move text up" })

-- Better navigation
keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down and center" })
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up and center" })
keymap.set("n", "n", "nzzzv", { desc = "Next search result and center" })
keymap.set("n", "N", "Nzzzv", { desc = "Previous search result and center" })

-- Better indenting
keymap.set("v", "<", "<gv", { desc = "Indent left" })
keymap.set("v", ">", ">gv", { desc = "Indent right" })

-- Paste without losing register
keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })

-- Copy to system clipboard
keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy to clipboard" })
keymap.set("n", "<leader>Y", [["+Y]], { desc = "Copy line to clipboard" })

-- Delete to void register
keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to void" })

-- Quick save and quit
keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
keymap.set("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Quit all without saving" })

-- Quick fix list
keymap.set("n", "<leader>co", "<cmd>copen<CR>", { desc = "Open quickfix" })
keymap.set("n", "<leader>cc", "<cmd>cclose<CR>", { desc = "Close quickfix" })
keymap.set("n", "<leader>cn", "<cmd>cnext<CR>", { desc = "Next quickfix" })
keymap.set("n", "<leader>cp", "<cmd>cprev<CR>", { desc = "Previous quickfix" })
```

## Advanced Features

### Debugging with DAP
```lua
-- lua/plugins/dap.lua

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-telescope/telescope-dap.nvim",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- Keymaps
      vim.keymap.set("n", "<F5>", dap.continue)
      vim.keymap.set("n", "<F10>", dap.step_over)
      vim.keymap.set("n", "<F11>", dap.step_into)
      vim.keymap.set("n", "<F12>", dap.step_out)
      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
      vim.keymap.set("n", "<leader>B", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end)
    end,
  },
}
```

### Terminal Integration
```lua
-- lua/plugins/terminal.lua

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
        },
      })

      -- Terminal keymaps
      function _G.set_terminal_keymaps()
        local opts = { buffer = 0 }
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
        vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
        vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
        vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
        vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
      end

      vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

      -- Lazygit integration
      local Terminal = require("toggleterm.terminal").Terminal
      local lazygit = Terminal:new({
        cmd = "lazygit",
        dir = "git_dir",
        direction = "float",
        float_opts = {
          border = "double",
        },
      })

      function _LAZYGIT_TOGGLE()
        lazygit:toggle()
      end

      vim.api.nvim_set_keymap("n", "<leader>g", "<cmd>lua _LAZYGIT_TOGGLE()<CR>", { noremap = true, silent = true })
    end,
  },
}
```

## Workflow Tips

### 1. File Navigation
```vim
" Quick file switching
<leader>ff  - Find files
<leader>fg  - Live grep
<leader>fb  - Browse buffers
<leader>fr  - Recent files

" Jump to definition
gd          - Go to definition
gr          - Find references
gi          - Go to implementation
K           - Show hover documentation
```

### 2. Code Editing
```vim
" Multiple cursors (using visual block)
Ctrl-v      - Visual block mode
I or A      - Insert at beginning/end
Esc         - Apply to all lines

" Quick refactoring
<leader>rn  - Rename symbol
<leader>ca  - Code actions
<leader>f   - Format file

" Surround operations
cs"'        - Change surrounding " to '
ds"         - Delete surrounding "
ysiw"       - Surround word with "
```

### 3. Git Integration
```vim
" Gitsigns keymaps
]c          - Next hunk
[c          - Previous hunk
<leader>hs  - Stage hunk
<leader>hr  - Reset hunk
<leader>hS  - Stage buffer
<leader>hu  - Undo stage hunk
<leader>hp  - Preview hunk
<leader>hb  - Blame line

" Lazygit
<leader>g   - Open Lazygit
```

### 4. Search and Replace
```vim
" Project-wide search and replace
:Telescope live_grep
<C-q>       - Send results to quickfix
:cdo s/old/new/g | update

" Buffer search and replace
:%s/old/new/gc

" Visual selection replace
v           - Select text
:s/old/new/g
```

## Performance Optimization

### 1. Lazy Loading
```lua
-- Use event triggers for plugins
{
  "plugin-name",
  event = { "BufReadPre", "BufNewFile" },
  cmd = { "PluginCommand" },
  ft = { "lua", "javascript" },
  keys = {
    { "<leader>x", "<cmd>PluginCommand<cr>", desc = "Run plugin" },
  },
}
```

### 2. Disable Unused Providers
```lua
-- In options.lua
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
```

### 3. Optimize Startup Time
```bash
# Profile startup time
nvim --startuptime startup.log

# Check slow plugins
nvim --startuptime startup.log -c "q" && sort -k2 -nr startup.log | head -20
```

## Troubleshooting

### Common Issues

1. **LSP not working**
```vim
:LspInfo
:LspLog
:Mason
```

2. **Treesitter errors**
```vim
:TSUpdate
:TSInstall <language>
:checkhealth nvim-treesitter
```

3. **Plugin issues**
```vim
:Lazy sync
:Lazy clean
:Lazy restore
```

4. **Check health**
```vim
:checkhealth
:checkhealth mason
:checkhealth telescope
```

## Resources

### Learning Resources
- **Vim Tutor**: Run `vimtutor` in terminal
- **Neovim Tutorial**: `:Tutor` in Neovim
- **ThePrimeagen's Config**: https://github.com/ThePrimeagen/init.lua
- **kickstart.nvim**: https://github.com/nvim-lua/kickstart.nvim
- **LazyVim**: https://www.lazyvim.org/
- **AstroNvim**: https://astronvim.com/
- **NvChad**: https://nvchad.com/

### Plugin Ecosystems
- **Awesome Neovim**: https://github.com/rockerBOO/awesome-neovim
- **Neovim Craft**: https://neovimcraft.com/
- **This Week in Neovim**: https://this-week-in-neovim.org/

### Communities
- **r/neovim**: Reddit community
- **Neovim Discord**: Official Discord server
- **Neovim Matrix**: Matrix chat