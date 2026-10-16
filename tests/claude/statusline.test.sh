#!/usr/bin/env bash
# Tests for config/claude/statusline-command.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/config/claude/statusline-command.sh"
failures=0

render() {
    printf '%s' "$1" | bash "$SCRIPT" | sed 's/\x1b\[[0-9;]*m//g'
}

expect_contains() {
    local name=$1 json=$2 expected=$3 actual
    actual=$(render "$json")
    if [[ "$actual" == *"$expected"* ]]; then
        echo "ok   $name"
    else
        printf 'FAIL %s\n  expected to contain: %s\n  actual: %s\n' "$name" "$expected" "$actual"
        failures=$((failures + 1))
    fi
}

expect_missing() {
    local name=$1 json=$2 unexpected=$3 actual
    actual=$(render "$json")
    if [[ "$actual" != *"$unexpected"* ]]; then
        echo "ok   $name"
    else
        printf 'FAIL %s\n  expected not to contain: %s\n  actual: %s\n' "$name" "$unexpected" "$actual"
        failures=$((failures + 1))
    fi
}

expect_color() {
    local name=$1 json=$2 rgb=$3
    if printf '%s' "$json" | bash "$SCRIPT" | grep -q "48;2;${rgb}m"; then
        echo "ok   $name"
    else
        echo "FAIL $name (background $rgb not found)"
        failures=$((failures + 1))
    fi
}

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

base='"cwd":"'"$dir"'","model":{"display_name":"Opus"}'

expect_contains "shows cwd" "{$base}" "$dir"
expect_contains "shows model" "{$base}" "Opus"
expect_contains "uses used_percentage" \
    "{$base,\"context_window\":{\"context_window_size\":200000,\"used_percentage\":42,\"current_usage\":{\"input_tokens\":84000}}}" \
    "42% used · 116k left"
expect_contains "computes percentage from current_usage" \
    "{$base,\"context_window\":{\"context_window_size\":1000000,\"current_usage\":{\"input_tokens\":800000,\"cache_read_input_tokens\":50000}}}" \
    "85% used · 150k left"
expect_contains "formats millions" \
    "{$base,\"context_window\":{\"context_window_size\":2000000,\"current_usage\":{\"input_tokens\":500000}}}" \
    "1.5M left"
expect_missing "hides context before first call" \
    "{$base,\"context_window\":{\"context_window_size\":200000,\"current_usage\":null,\"used_percentage\":null}}" \
    "used"
expect_missing "hides context without context_window" "{$base}" "used"
expect_color "green under 50%" "{$base,\"context_window\":{\"context_window_size\":200000,\"used_percentage\":10}}" "78;154;6"
expect_color "yellow from 50%" "{$base,\"context_window\":{\"context_window_size\":200000,\"used_percentage\":60}}" "196;160;0"
expect_color "red above 80%" "{$base,\"context_window\":{\"context_window_size\":200000,\"used_percentage\":90}}" "204;0;0"

git -C "$dir" init -q -b demo
expect_contains "shows git branch" "{$base}" "demo"
touch "$dir/new.txt"
expect_contains "counts untracked files" "{$base}" "demo ?1"

if (( failures > 0 )); then
    echo "$failures test(s) failed"
    exit 1
fi
echo "All tests passed"
