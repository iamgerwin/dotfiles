#!/usr/bin/env zsh
# Functions - Custom shell functions

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f "$1" ] ; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick backup of a file
backup() {
    cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"
}

# Find file by name in current directory
ff() {
    find . -type f -iname "*$1*"
}

# Find directory by name in current directory
fd() {
    find . -type d -iname "*$1*"
}

# Get current git branch
git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Quick git commit with message
gcmsg_quick() {
    git commit -m "$*"
}

# Quick git add and commit
gac() {
    git add . && git commit -m "$*"
}


# Get weather
weather() {
    curl "wttr.in/${1:-}"
}

# Quick notes
note() {
    echo "$(date): $*" >> ~/notes.txt
    echo "Note added!"
}

# Show notes
notes() {
    if [ -f ~/notes.txt ]; then
        cat ~/notes.txt
    else
        echo "No notes found"
    fi
}

# Simple calculator
calc() {
    echo "scale=2; $*" | bc
}

# Get public IP
myip() {
    curl -s https://api.ipify.org
    echo
}

# Port checker
port_check() {
    lsof -i :"$1"
}

# System info
sysinfo() {
    echo "Hostname: $(hostname)"
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime)"
    echo "Memory: $(free -h 2>/dev/null || vm_stat | head -n 2)"
    echo "Disk: $(df -h / | tail -1)"
}

# Quick HTTP server
serve() {
    local port="${1:-8000}"
    python3 -m http.server "$port"
}

# Show most used commands
most_used() {
    history | awk '{print $2}' | sort | uniq -c | sort -rn | head -20
}

# Repo-specific gh account: pick the gh login from the origin remote's SSH host alias.
# Add a pair per alias in ~/.ssh/config (or in custom.zsh: GH_HOST_ACCOUNTS[alias]=login).
# An explicit GH_TOKEN, GH_REPO or -R/--repo skips the mapping and uses the active account.
typeset -gA GH_HOST_ACCOUNTS=(
    github.com-iamgerwin iamgerwin
)
gh() {
    # Keep the token out of xtrace/verbose output; options revert when the function returns.
    setopt localoptions noxtrace noverbose
    local arg
    for arg in "$@"; do
        if [[ $arg == -R || $arg == --repo || $arg == --repo=* || $arg == -R?* ]]; then
            command gh "$@"
            return
        fi
    done
    if [[ -z "${GH_TOKEN:-}${GH_REPO:-}" ]]; then
        local url host user token
        url=$(command git remote get-url origin 2>/dev/null)
        host=${url#*://}; host=${host#*@}; host=${host%%[:/]*}
        user=${GH_HOST_ACCOUNTS[$host]:-}
        if [[ -n "$user" ]]; then
            if token=$(command gh auth token -u "$user" 2>/dev/null) && [[ -n "$token" ]]; then
                GH_TOKEN="$token" command gh "$@"
                return
            fi
            print -u2 -- "gh: no token for $user (gh auth login); using the active account"
        fi
    fi
    command gh "$@"
}
