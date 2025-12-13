#!/usr/bin/env bash
set -euo pipefail

# Project Bootstrap Skill - Next.js Initialization
# Usage: ./init-nextjs.sh <project-name> [target-directory]

PROJECT_NAME="${1:-}"
TARGET_DIR="${2:-$(pwd)}"

if [[ -z "$PROJECT_NAME" ]]; then
    echo "Usage: $0 <project-name> [target-directory]"
    echo ""
    echo "Example:"
    echo "  $0 my-app"
    echo "  $0 my-app ~/projects/"
    exit 1
fi

echo "==> Initializing Next.js project: $PROJECT_NAME"

# Navigate to target directory
cd "$TARGET_DIR"

# Create Next.js project with TypeScript, Tailwind, ESLint, and App Router
echo "==> Creating Next.js project with TypeScript, Tailwind CSS, and App Router..."
npx create-next-app@latest "$PROJECT_NAME" \
    --typescript \
    --tailwind \
    --eslint \
    --app \
    --src-dir \
    --import-alias "@/*" \
    --use-npm

cd "$PROJECT_NAME"

# Install additional development dependencies
echo "==> Installing additional dependencies..."
npm install -D prettier prettier-plugin-tailwindcss

# Create Prettier config
echo "==> Creating Prettier configuration..."
cat > .prettierrc.json << 'EOF'
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "plugins": ["prettier-plugin-tailwindcss"]
}
EOF

# Create additional directories
echo "==> Creating standard directory structure..."
mkdir -p src/components
mkdir -p src/hooks
mkdir -p src/lib
mkdir -p src/services
mkdir -p src/types

# Copy templates if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

if [[ -f "$TEMPLATE_DIR/README.template.md" ]]; then
    echo "==> Copying README template..."
    cp "$TEMPLATE_DIR/README.template.md" README.md
    sed -i.bak "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" README.md
    rm -f README.md.bak
fi

# Initialize git (if not already done by create-next-app)
if [[ ! -d .git ]]; then
    echo "==> Initializing git repository..."
    git init
fi

git add .
git commit -m "Initial Next.js project setup with TypeScript and Tailwind"

echo ""
echo "==> Next.js project '$PROJECT_NAME' initialized successfully!"
echo ""
echo "Next steps:"
echo "  cd $TARGET_DIR/$PROJECT_NAME"
echo "  npm run dev"
