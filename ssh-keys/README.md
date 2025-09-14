# SSH Keys Directory

This directory is for storing SSH keys used by the Git Profile Management system.

⚠️ **IMPORTANT**: This directory and its contents are gitignored for security.

## Structure

Place your SSH keys here with meaningful names:
```
ssh-keys/
├── README.md           (this file - committed)
├── github-personal     (private key - gitignored)
├── github-personal.pub (public key - gitignored)
├── github-work        (private key - gitignored)
├── github-work.pub    (public key - gitignored)
└── ...
```

## Setup Instructions

1. Generate new SSH keys here:
```bash
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/dotfiles/ssh-keys/github-personal
```

2. Create symlinks to ~/.ssh for SSH to find them:
```bash
ln -sf ~/dotfiles/ssh-keys/github-personal ~/.ssh/github-personal
ln -sf ~/dotfiles/ssh-keys/github-personal.pub ~/.ssh/github-personal.pub
```

3. Add to ssh-agent:
```bash
ssh-add ~/dotfiles/ssh-keys/github-personal
```

4. Reference in your git profiles using just the filename:
```
SSH_KEY_NAME="github-personal"
```

## Security Notes

- Never commit actual SSH keys to version control
- This entire directory (except README.md) is gitignored
- Keys are referenced by name in profile configurations
- Use descriptive names for your keys (github-personal, gitlab-work, etc.)