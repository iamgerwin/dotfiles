#!/usr/bin/env bash
set -euo pipefail

# sync-skills.sh - Sync Claude Skills from dotfiles to local Claude skills directory
#
# Usage:
#   sync-skills.sh              # Sync to default location (~/.claude/skills)
#   sync-skills.sh --dry-run    # Preview what would be synced
#   sync-skills.sh --target DIR # Sync to custom directory
#
# Environment:
#   CLAUDE_SKILLS_DIR - Override default target directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$DOTFILES_DIR/ai-prompts/skills"
TARGET_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --target)
            TARGET_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--target DIR]"
            echo ""
            echo "Sync Claude Skills from dotfiles to local Claude skills directory."
            echo ""
            echo "Options:"
            echo "  --dry-run     Preview what would be synced without making changes"
            echo "  --target DIR  Specify custom target directory"
            echo "  -h, --help    Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  CLAUDE_SKILLS_DIR  Override default target directory (~/.claude/skills)"
            echo ""
            echo "Source: $SOURCE_DIR"
            echo "Default Target: $TARGET_DIR"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Verify source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source directory not found: $SOURCE_DIR"
    echo "Make sure ai-prompts/skills/ exists in your dotfiles."
    exit 1
fi

# Count skills
SKILL_COUNT=$(find "$SOURCE_DIR" -maxdepth 1 -type d | wc -l)
SKILL_COUNT=$((SKILL_COUNT - 1))  # Exclude the source dir itself

echo "==> Claude Skills Sync"
echo "    Source: $SOURCE_DIR"
echo "    Target: $TARGET_DIR"
echo "    Skills: $SKILL_COUNT skill(s) found"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] Would sync the following skills:"
    echo ""
    for skill_dir in "$SOURCE_DIR"/*/; do
        if [[ -d "$skill_dir" ]]; then
            skill_name=$(basename "$skill_dir")
            echo "  - $skill_name/"
            if [[ -f "$skill_dir/SKILL.md" ]]; then
                # Extract description from frontmatter
                desc=$(grep -A1 "^description:" "$skill_dir/SKILL.md" 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//')
                if [[ -n "$desc" && "$desc" != "description:"* ]]; then
                    echo "    $desc"
                fi
            fi
        fi
    done
    echo ""
    echo "[DRY RUN] No changes made. Run without --dry-run to sync."
    exit 0
fi

# Create target directory
echo "==> Creating target directory..."
mkdir -p "$TARGET_DIR"

# Sync skills
echo "==> Syncing skills..."
rsync -av --delete "$SOURCE_DIR/" "$TARGET_DIR/"

echo ""
echo "==> Skills synced successfully!"
echo ""
echo "Skills are now available at: $TARGET_DIR"
echo ""
echo "To list available skills:"
echo "  ls $TARGET_DIR"
