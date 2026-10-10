#!/usr/bin/env bash
# Tests for skills/quick-address-issue/scripts/parse-issue-url.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/skills/quick-address-issue/scripts/parse-issue-url.sh"
failures=0

expect_ok() {
    local input=$1 expected=$2 actual
    if ! actual=$("$SCRIPT" "$input" 2>&1); then
        echo "FAIL $input (non-zero exit): $actual"
        failures=$((failures + 1))
    elif [[ "$actual" != "$expected" ]]; then
        printf 'FAIL %s\n  expected: %s\n  actual:   %s\n' "$input" "$expected" "$actual"
        failures=$((failures + 1))
    else
        echo "ok   $input"
    fi
}

expect_err() {
    if "$SCRIPT" "$@" >/dev/null 2>&1; then
        echo "FAIL expected error for: ${*:-<no args>}"
        failures=$((failures + 1))
    else
        echo "ok   rejects ${*:-<no args>}"
    fi
}

dotfiles_125=$'OWNER=iamgerwin\nREPO=dotfiles\nNUMBER=125'

expect_ok "https://github.com/iamgerwin/dotfiles/issues/125" "$dotfiles_125"
expect_ok "https://github.com/iamgerwin/dotfiles/issues/125/" "$dotfiles_125"
expect_ok "https://github.com/iamgerwin/dotfiles/issues/125#issuecomment-42" "$dotfiles_125"
expect_ok "https://github.com/iamgerwin/dotfiles/issues/125?foo=bar" "$dotfiles_125"
expect_ok "http://www.github.com/iamgerwin/dotfiles/issues/125" "$dotfiles_125"
expect_ok "iamgerwin/dotfiles#125" "$dotfiles_125"
expect_ok "https://github.com/axllent/mailpit/issues/594" $'OWNER=axllent\nREPO=mailpit\nNUMBER=594'
expect_ok "https://github.com/my-org/repo.name_v2/issues/7" $'OWNER=my-org\nREPO=repo.name_v2\nNUMBER=7'

expect_err
expect_err ""
expect_err "https://github.com/iamgerwin/dotfiles/pull/127"
expect_err "https://github.com/iamgerwin/dotfiles/issues/"
expect_err "https://github.com/iamgerwin/dotfiles/issues/abc"
expect_err "https://gitlab.com/iamgerwin/dotfiles/issues/125"
expect_err "iamgerwin/dotfiles"
expect_err "https://github.com/a/b/issues/1" "extra-arg"

if [[ $failures -gt 0 ]]; then
    echo "$failures test(s) failed"
    exit 1
fi
echo "All tests passed"
