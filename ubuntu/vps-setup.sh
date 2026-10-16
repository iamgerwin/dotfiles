#!/usr/bin/env bash
# Bootstraps an Ubuntu VPS (captured from a 26.04 VPS) with the fish + Tide shell and dev tools. Run as your normal user (not root):
#   bash vps-setup.sh
#   or: curl -fsSL https://raw.githubusercontent.com/iamgerwin/dotfiles/main/ubuntu/vps-setup.sh | bash
# Safe to re-run. Uses sudo for apt/snap/chsh.
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then echo "Run as your normal user, not root (sudo is used where needed)." >&2; exit 1; fi

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# ---------------------------------------------------------------- apt
step "apt packages"
sudo apt update
sudo apt install -y \
  fish eza zoxide fzf fd-find bat ripgrep \
  git gh curl wget vim \
  btop glances \
  cargo npm python3-pip python3-venv \
  fail2ban openssh-server locales-all

# Ubuntu names these fdfind/batcat; fzf.fish expects fd/bat
mkdir -p "$HOME/.local/bin"
ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"

# ---------------------------------------------------------------- snaps
step "snaps"
sudo snap install astral-uv --classic
sudo snap install bottom
sudo snap install dust

# ---------------------------------------------------------------- npm globals (user prefix, no sudo)
step "npm globals"
npm config set prefix "$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
grep -q 'npm-global' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
npm install -g @openai/codex bun zai-usage

# ---------------------------------------------------------------- cargo
step "cargo crates"
cargo install zenith

# ---------------------------------------------------------------- uv tools
step "uv tools"
uv tool install headroom-ai

# ---------------------------------------------------------------- curl installers
step "Claude Code"
curl -fsSL https://claude.ai/install.sh | bash

step "herdr"
curl -fsSL https://herdr.dev/install.sh | sh

step "rtk"
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh

# ---------------------------------------------------------------- fish config
step "fish config"
mkdir -p "$HOME/.config/fish"
cat > "$HOME/.config/fish/config.fish" <<'FISH_EOF'
if status is-interactive
    # Commands to run in interactive sessions can go here

    alias ls 'eza --color=always --group-directories-first' # eza replacement for ls
    alias ll 'ls -alF'  # Detailed list with hidden files and indicators
    alias la 'ls -A'    # Show almost all files (hiding . and ..)
    alias l 'ls -F'     # Compact multi-column view (eza has no -C; grid is its default)

    zoxide init fish --cmd cd | source # cd uses zoxide (cdi for interactive picker)
end
FISH_EOF

step "fisher + plugins"
fish -c 'fish_add_path ~/.local/bin ~/.npm-global/bin ~/.cargo/bin'
fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
fish -c 'fisher install ilancosman/tide@v6 patrickf1/fzf.fish jorgebucaran/autopair.fish'

step "Tide prompt settings (copied from original VPS)"
TIDE_TMP="$(mktemp)"
cat > "$TIDE_TMP" <<'TIDE_EOF'
set -U tide_aws_bg_color FF9900
set -U tide_aws_color 232F3E
set -U tide_aws_icon 
set -U tide_bun_bg_color FBF0DF
set -U tide_bun_color 14151A
set -U tide_bun_icon 󰳓
set -U tide_character_color 5FD700
set -U tide_character_color_failure FF0000
set -U tide_character_icon ❯
set -U tide_character_vi_icon_default ❮
set -U tide_character_vi_icon_replace ▶
set -U tide_character_vi_icon_visual V
set -U tide_cmd_duration_bg_color C4A000
set -U tide_cmd_duration_color 000000
set -U tide_cmd_duration_decimals 0
set -U tide_cmd_duration_icon 
set -U tide_cmd_duration_threshold 3000
set -U tide_context_always_display false
set -U tide_context_bg_color 444444
set -U tide_context_color_default D7AF87
set -U tide_context_color_root D7AF00
set -U tide_context_color_ssh D7AF87
set -U tide_context_hostname_parts 1
set -U tide_crystal_bg_color FFFFFF
set -U tide_crystal_color 000000
set -U tide_crystal_icon 
set -U tide_direnv_bg_color D7AF00
set -U tide_direnv_bg_color_denied FF0000
set -U tide_direnv_color 000000
set -U tide_direnv_color_denied 000000
set -U tide_direnv_icon ▼
set -U tide_distrobox_bg_color FF00FF
set -U tide_distrobox_color 000000
set -U tide_distrobox_icon 󰆧
set -U tide_docker_bg_color 2496ED
set -U tide_docker_color 000000
set -U tide_docker_default_contexts default colima
set -U tide_docker_icon 
set -U tide_elixir_bg_color 4E2A8E
set -U tide_elixir_color 000000
set -U tide_elixir_icon 
set -U tide_gcloud_bg_color 4285F4
set -U tide_gcloud_color 000000
set -U tide_gcloud_icon 󰊭
set -U tide_git_bg_color 4E9A06
set -U tide_git_bg_color_unstable C4A000
set -U tide_git_bg_color_urgent CC0000
set -U tide_git_color_branch 000000
set -U tide_git_color_conflicted 000000
set -U tide_git_color_dirty 000000
set -U tide_git_color_operation 000000
set -U tide_git_color_staged 000000
set -U tide_git_color_stash 000000
set -U tide_git_color_untracked 000000
set -U tide_git_color_upstream 000000
set -U tide_git_icon 
set -U tide_git_truncation_length 24
set -U tide_git_truncation_strategy
set -U tide_go_bg_color 00ACD7
set -U tide_go_color 000000
set -U tide_go_icon 
set -U tide_java_bg_color ED8B00
set -U tide_java_color 000000
set -U tide_java_icon 
set -U tide_jobs_bg_color 444444
set -U tide_jobs_color 4E9A06
set -U tide_jobs_icon 
set -U tide_jobs_number_threshold 1000
set -U tide_kubectl_bg_color 326CE5
set -U tide_kubectl_color 000000
set -U tide_kubectl_icon 󱃾
set -U tide_left_prompt_frame_enabled true
set -U tide_left_prompt_items os pwd git newline character
set -U tide_left_prompt_prefix ''
set -U tide_left_prompt_separator_diff_color 
set -U tide_left_prompt_separator_same_color 
set -U tide_left_prompt_suffix 
set -U tide_nix_shell_bg_color 7EBAE4
set -U tide_nix_shell_color 000000
set -U tide_nix_shell_icon 
set -U tide_node_bg_color 44883E
set -U tide_node_color 000000
set -U tide_node_icon 
set -U tide_os_bg_color D4D4D4
set -U tide_os_color E95420
set -U tide_os_icon 
set -U tide_php_bg_color 617CBE
set -U tide_php_color 000000
set -U tide_php_icon 
set -U tide_private_mode_bg_color F1F3F4
set -U tide_private_mode_color 000000
set -U tide_private_mode_icon 󰗹
set -U tide_prompt_add_newline_before true
set -U tide_prompt_color_frame_and_connection 585858
set -U tide_prompt_color_separator_same_color 949494
set -U tide_prompt_icon_connection ' '
set -U tide_prompt_min_cols 34
set -U tide_prompt_pad_items true
set -U tide_prompt_transient_enabled true
set -U tide_pulumi_bg_color F7BF2A
set -U tide_pulumi_color 000000
set -U tide_pulumi_icon 
set -U tide_pwd_bg_color 3465A4
set -U tide_pwd_color_anchors E4E4E4
set -U tide_pwd_color_dirs E4E4E4
set -U tide_pwd_color_truncated_dirs BCBCBC
set -U tide_pwd_icon 
set -U tide_pwd_icon_home 
set -U tide_pwd_icon_unwritable 
set -U tide_pwd_markers .bzr .citc .git .hg .node-version .python-version .ruby-version .shorten_folder_marker .svn .terraform bun.lockb Cargo.toml composer.json CVS go.mod package.json build.zig
set -U tide_python_bg_color 444444
set -U tide_python_color 00AFAF
set -U tide_python_icon 󰌠
set -U tide_right_prompt_frame_enabled false
set -U tide_right_prompt_items status cmd_duration context jobs direnv bun node python rustc java php pulumi ruby go gcloud kubectl distrobox toolbox terraform aws nix_shell crystal elixir zig time
set -U tide_right_prompt_prefix 
set -U tide_right_prompt_separator_diff_color 
set -U tide_right_prompt_separator_same_color 
set -U tide_right_prompt_suffix ''
set -U tide_ruby_bg_color B31209
set -U tide_ruby_color 000000
set -U tide_ruby_icon 
set -U tide_rustc_bg_color F74C00
set -U tide_rustc_color 000000
set -U tide_rustc_icon 
set -U tide_shlvl_bg_color 808000
set -U tide_shlvl_color 000000
set -U tide_shlvl_icon 
set -U tide_shlvl_threshold 1
set -U tide_status_bg_color 2E3436
set -U tide_status_bg_color_failure CC0000
set -U tide_status_color 4E9A06
set -U tide_status_color_failure FFFF00
set -U tide_status_icon ✔
set -U tide_status_icon_failure ✘
set -U tide_terraform_bg_color 800080
set -U tide_terraform_color 000000
set -U tide_terraform_icon 󱁢
set -U tide_time_bg_color D3D7CF
set -U tide_time_color 000000
set -U tide_time_format '%T'
set -U tide_toolbox_bg_color 613583
set -U tide_toolbox_color 000000
set -U tide_toolbox_icon 
set -U tide_vi_mode_bg_color_default 949494
set -U tide_vi_mode_bg_color_insert 87AFAF
set -U tide_vi_mode_bg_color_replace 87AF87
set -U tide_vi_mode_bg_color_visual FF8700
set -U tide_vi_mode_color_default 000000
set -U tide_vi_mode_color_insert 000000
set -U tide_vi_mode_color_replace 000000
set -U tide_vi_mode_color_visual 000000
set -U tide_vi_mode_icon_default D
set -U tide_vi_mode_icon_insert I
set -U tide_vi_mode_icon_replace R
set -U tide_vi_mode_icon_visual V
set -U tide_zig_bg_color F7A41D
set -U tide_zig_color 000000
set -U tide_zig_icon 
TIDE_EOF
fish "$TIDE_TMP"
rm -f "$TIDE_TMP"

# ---------------------------------------------------------------- default shell
step "set fish as login shell"
sudo chsh -s /usr/bin/fish "$USER"

step "Done"
cat <<'MSG'
Next:
  1. Log out and back in (or reboot) so fish becomes your shell.
  2. Log in to tools:  gh auth login   |   claude   |   codex
  3. Optional:         rtk init -g      (Claude Code hook)
Not included (per-machine): SSH keys, git config, tool logins.
MSG
