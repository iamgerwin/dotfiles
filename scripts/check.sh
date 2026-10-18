#!/usr/bin/env bash
# Same safe regression checks locally and on both CI platforms.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PYTHONDONTWRITEBYTECODE=1
export BASH_UNDER_TEST=/bin/bash

for tool in python3 jq git zsh; do
    command -v "$tool" >/dev/null || { echo "Required test dependency: $tool" >&2; exit 1; }
done

python3 scripts/check-repo.py "$@"
python3 -m unittest discover -s tests -p '*_test.py' -v
/bin/bash tests/claude/statusline.test.sh
/bin/bash tests/skills/parse-issue-url.test.sh
/bin/bash tests/skills/validate-skills.sh
