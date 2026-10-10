#!/usr/bin/env bash
set -euo pipefail

# Project Bootstrap Skill - Laravel Initialization
# Usage: ./init-laravel.sh <project-name> [target-directory]

PROJECT_NAME="${1:-}"
TARGET_DIR="${2:-$(pwd)}"

if [[ -z "$PROJECT_NAME" ]]; then
    echo "Usage: $0 <project-name> [target-directory]"
    echo ""
    echo "Example:"
    echo "  $0 my-api"
    echo "  $0 my-api ~/projects/"
    exit 1
fi

echo "==> Initializing Laravel project: $PROJECT_NAME"

# Navigate to target directory
cd "$TARGET_DIR"

# Create Laravel project
echo "==> Creating Laravel project..."
composer create-project laravel/laravel "$PROJECT_NAME"

cd "$PROJECT_NAME"

# Install development dependencies
echo "==> Installing Pest for testing..."
composer require pestphp/pest --dev --with-all-dependencies
php artisan pest:install

echo "==> Installing Laravel Pint for code style..."
composer require laravel/pint --dev

# Create additional directories
echo "==> Creating standard directory structure..."
mkdir -p app/Actions
mkdir -p app/DTOs
mkdir -p app/Enums
mkdir -p app/Services
mkdir -p app/Repositories

# Initialize git
echo "==> Initializing git repository..."
git init
git add .
git commit -m "Initial Laravel project setup"

# Copy templates if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

if [[ -f "$TEMPLATE_DIR/README.template.md" ]]; then
    echo "==> Copying README template..."
    cp "$TEMPLATE_DIR/README.template.md" README.md
    sed -i.bak "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" README.md
    rm -f README.md.bak
fi

echo ""
echo "==> Laravel project '$PROJECT_NAME' initialized successfully!"
echo ""
echo "Next steps:"
echo "  cd $TARGET_DIR/$PROJECT_NAME"
echo "  cp .env.example .env"
echo "  php artisan key:generate"
echo "  php artisan serve"
