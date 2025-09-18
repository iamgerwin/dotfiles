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

