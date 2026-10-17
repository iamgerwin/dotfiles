# Ubuntu VPS bootstrap

One script that turns a fresh Ubuntu VPS into a ready-to-use dev box: fish shell with a Powerlevel10k-style prompt, modern CLI tools, AI coding agents, and a matching Claude Code status line.

It was captured from a working Ubuntu 26.04 VPS, so a new server ends up with the same packages, shell config, and prompt.

## Quick start

On the new VPS, logged in as your normal user (not root):

```bash
curl -fsSL https://raw.githubusercontent.com/iamgerwin/dotfiles/main/ubuntu/vps-setup.sh | bash
```

Or, if you prefer to read it first:

```bash
curl -fsSLO https://raw.githubusercontent.com/iamgerwin/dotfiles/main/ubuntu/vps-setup.sh
less vps-setup.sh
bash vps-setup.sh
```

The script asks for your sudo password when needed. It is safe to re-run if something fails partway.

When it finishes:

1. Log out and back in (or reboot) so fish becomes your shell.
2. Log in to tools: `gh auth login`, `claude`, `codex`.
3. Optional: `rtk init -g` to register the rtk hook in Claude Code.

## Requirements

- Ubuntu with `apt` and `snap` (the stock Ubuntu Server image has both)
- A non-root user with sudo access
- `curl` (preinstalled on Ubuntu Server)

## What it installs

### apt packages

| Group | Packages |
|---|---|
| Shell and CLI | `fish` `eza` `zoxide` `fzf` `fd-find` `bat` `ripgrep` |
| Dev tools | `git` `gh` `curl` `wget` `vim` `jq` |
| Monitoring | `btop` `glances` |
| Languages | `cargo` `npm` `python3-pip` `python3-venv` |
| Server basics | `fail2ban` `openssh-server` `locales-all` |

Ubuntu installs `fd` and `bat` as `fdfind` and `batcat`. The script links them as `fd` and `bat` in `~/.local/bin`, which is what `fzf.fish` looks for.

### Other installers

| Source | Installs |
|---|---|
| snap | `astral-uv` (uv), `bottom`, `dust` |
| npm (user prefix `~/.npm-global`, no sudo) | `@openai/codex`, `bun`, `zai-usage` |
| cargo | `zenith` |
| uv tool | `headroom-ai` |
| curl installer | [Claude Code](https://claude.ai/install.sh), [herdr](https://herdr.dev/install.sh), [rtk](https://github.com/rtk-ai/rtk) |

### Shell setup

| zsh / Oh My Zsh equivalent | fish setup |
|---|---|
| zsh-autosuggestions, completions | Built into fish |
| Oh My Zsh (plugin manager) | [Fisher](https://github.com/jorgebucaran/fisher) |
| Powerlevel10k | [Tide v6](https://github.com/IlanCosman/tide), with the original VPS's prompt settings applied |
| Ctrl+R history / file search | [fzf.fish](https://github.com/PatrickF1/fzf.fish) |
| Auto-closing brackets and quotes | [autopair.fish](https://github.com/jorgebucaran/autopair.fish) |

`~/.config/fish/config.fish` is written with:

| Command | Runs |
|---|---|
| `ls` | `eza --color=always --group-directories-first` |
| `ll` | `ls -alF` (detailed list with hidden files) |
| `la` | `ls -A` (all files except `.` and `..`) |
| `l` | `ls -F` (compact grid) |
| `cd` | zoxide: `cd foo` jumps to your most-used folder matching `foo`; `cdi` opens a picker |

The script also adds `~/.local/bin`, `~/.npm-global/bin`, and `~/.cargo/bin` to fish's PATH (and `~/.npm-global/bin` to bash's), and sets fish as your login shell.

### Claude Code status line

The script runs [`scripts/setup-claude-statusline.sh`](../scripts/setup-claude-statusline.sh), which links `~/.claude/statusline-command.sh` to `config/claude/statusline-command.sh` and sets `statusLine` in `~/.claude/settings.json` (other settings are kept and the old file is backed up). See [the status line docs](../docs/ai-tools/INSTALLATION.md#claude-code-status-line) for what each segment shows.

The link needs a copy of this repo on the VPS:

- Run from a checkout (`bash ubuntu/vps-setup.sh`), it uses that checkout.
- Run with `curl | bash`, it clones the repo to `~/dotfiles`, or updates it with `git pull --ff-only` if it is already there. Set `DOTFILES_DIR` to use another path.

Keep `~/dotfiles` after setup: deleting it breaks the status line link. If the setup script is not found, this step is skipped with a warning and the rest of the bootstrap continues.

## Order of steps

1. apt packages and the `fd` / `bat` links
2. snaps
3. npm globals
4. cargo crates
5. uv tools
6. Claude Code, herdr, rtk
7. Dotfiles checkout and Claude Code status line
8. fish config, Fisher and plugins, Tide prompt settings
9. Set fish as the login shell

Fish becomes the login shell only at the end, after everything else has installed.

## Notes

- **Fonts are set on your computer, not the VPS.** Tide's and the status line's icons need a [Nerd Font](https://www.nerdfonts.com/) selected in your local terminal app.
- **Existing config is overwritten.** The script replaces `~/.config/fish/config.fish` and resets npm's global prefix to `~/.npm-global`. Back up anything you want to keep first.
- **`--color=always` on `ls`** keeps color codes when piping (e.g. `ls | grep`). Change it to `--color=auto` in `config.fish` if that gets in the way.
- **Not included:** SSH keys, git config, and tool logins. Set those up per machine.

## Customizing

Edit `vps-setup.sh` directly. Each section is marked with a `# ----` header (apt, snaps, npm, cargo, uv, curl installers, Claude Code status line, fish config). Remove a line to skip a tool, or add packages to the lists.

The Tide settings are the block between `TIDE_EOF` markers. To replace them with your own, run `tide configure` on a machine, then regenerate the block in fish:

```fish
for v in (set -U -n | string match "tide_*"); echo set -U $v (string escape -- $$v); end
```
