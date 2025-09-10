#!/bin/bash

# Script to clean unwanted text from git commit messages
# This will remove Co-Authored-By lines and any anthropic references

echo "Cleaning git commit messages..."
echo "This will rewrite git history. Make sure you have a backup!"
echo ""

# Create a backup branch first
git branch backup-before-clean-$(date +%Y%m%d-%H%M%S)
echo "Created backup branch: backup-before-clean-$(date +%Y%m%d-%H%M%S)"

# Find the oldest commit that needs cleaning
OLDEST_COMMIT=$(git log --grep="Co-Authored\|anthropic" --format="%H" | tail -1)

if [ -z "$OLDEST_COMMIT" ]; then
    echo "No commits found with Co-Authored-By or anthropic references"
    exit 0
fi

# Get the parent of the oldest commit
PARENT_COMMIT=$(git rev-parse ${OLDEST_COMMIT}^)

echo "Found commits to clean. Starting from: $PARENT_COMMIT"
echo ""

# Create a filter script
cat > /tmp/filter-msg.sh << 'EOF'
#!/bin/bash
# Remove Co-Authored-By lines and anthropic references
sed '/Co-Authored-By/d' | sed '/anthropic/d' | sed '/noreply@anthropic.com/d'
EOF

chmod +x /tmp/filter-msg.sh

# Use git filter-branch to clean commit messages
echo "Cleaning commit messages..."
git filter-branch -f --msg-filter /tmp/filter-msg.sh ${PARENT_COMMIT}..HEAD

# Clean up
rm /tmp/filter-msg.sh

echo ""
echo "Commit messages cleaned successfully!"
echo "Review the changes with: git log --oneline -20"
echo ""
echo "If everything looks good, force push with:"
echo "  git push origin main --force"
echo ""
echo "If something went wrong, restore from backup:"
echo "  git reset --hard backup-before-clean-$(date +%Y%m%d)"