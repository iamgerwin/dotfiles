#!/usr/bin/env bash
# Parse a GitHub issue reference into OWNER, REPO and NUMBER as KEY=VALUE lines.
# Accepts https://github.com/<owner>/<repo>/issues/<n> (query/fragment allowed)
# or the short form <owner>/<repo>#<n>.
set -euo pipefail

usage() {
    echo "Usage: $(basename "$0") <issue-url | owner/repo#number>" >&2
}

if [[ $# -ne 1 || -z "$1" ]]; then
    usage
    exit 2
fi

ref="$1"
url_re='^https?://(www\.)?github\.com/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)/issues/([0-9]+)/?([?#].*)?$'
short_re='^([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)#([0-9]+)$'

if [[ "$ref" =~ $url_re ]]; then
    owner="${BASH_REMATCH[2]}"
    repo="${BASH_REMATCH[3]}"
    number="${BASH_REMATCH[4]}"
elif [[ "$ref" =~ $short_re ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    number="${BASH_REMATCH[3]}"
else
    echo "Error: not a GitHub issue reference: $ref" >&2
    usage
    exit 1
fi

printf 'OWNER=%s\nREPO=%s\nNUMBER=%s\n' "$owner" "$repo" "$number"
