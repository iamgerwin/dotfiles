#!/usr/bin/env bash
# Validate every skill under skills/ against the expected layout:
#   skills/<name>/SKILL.md (+ optional scripts/, references/, assets/)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILLS_DIR="$ROOT/skills"
errors=0
count=0

error() {
    echo "  FAIL $1"
    errors=$((errors + 1))
}

frontmatter_value() {
    # Print the value of a top-level key from the YAML frontmatter block.
    awk -v key="$2" '
        NR == 1 && $0 != "---" { exit }
        NR > 1 && $0 == "---" { exit }
        NR > 1 && index($0, key ":") == 1 { sub("^" key ":[[:space:]]*", ""); print; exit }
    ' "$1"
}

for dir in "$SKILLS_DIR"/*/; do
    dir="${dir%/}"
    name="$(basename "$dir")"
    skill="$dir/SKILL.md"
    count=$((count + 1))
    echo "$name"

    if [[ ! -f "$skill" ]]; then
        error "missing SKILL.md"
        continue
    fi

    if [[ "$(head -1 "$skill")" != "---" ]] || [[ $(grep -c '^---$' "$skill") -lt 2 ]]; then
        error "SKILL.md must start with a --- delimited frontmatter block"
        continue
    fi

    fm_name="$(frontmatter_value "$skill" name)"
    if [[ "$fm_name" != "$name" ]]; then
        error "frontmatter name '$fm_name' does not match directory '$name'"
    fi
    if ! [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || [[ ${#name} -gt 64 ]]; then
        error "name must be lowercase kebab-case, max 64 chars"
    fi

    description="$(frontmatter_value "$skill" description)"
    if [[ -z "$description" ]]; then
        error "frontmatter description is empty"
    elif [[ ${#description} -gt 1024 ]]; then
        error "description is longer than 1024 chars"
    fi

    # Every scripts/, references/ or assets/ path mentioned in SKILL.md must exist.
    while IFS= read -r ref; do
        [[ -z "$ref" ]] && continue
        [[ -e "$dir/$ref" ]] || error "SKILL.md references missing file: $ref"
    done < <(grep -oE '(^|[[:space:]`(])(scripts|references|assets)/[A-Za-z0-9._/-]*[A-Za-z0-9_-]' "$skill" \
        | sed -E 's/^[[:space:]`(]//' | sort -u)

    if [[ -d "$dir/scripts" ]]; then
        while IFS= read -r script; do
            [[ -x "$script" ]] || error "script is not executable: ${script#"$dir"/}"
        done < <(find "$dir/scripts" -type f \( -name '*.sh' -o -name '*.py' \))
    fi
done

echo ""
if [[ $count -eq 0 ]]; then
    echo "No skills found in $SKILLS_DIR"
    exit 1
fi
if [[ $errors -gt 0 ]]; then
    echo "$errors problem(s) found across $count skill(s)"
    exit 1
fi
echo "All $count skill(s) valid"
