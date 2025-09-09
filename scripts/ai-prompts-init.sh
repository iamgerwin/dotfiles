#!/usr/bin/env bash
# Initialize AI Prompts Structure
# Sets up organized directory structure for AI prompts management

set -e

# Configuration
AI_PROMPTS_DIR="${AI_PROMPTS_DIR:-$HOME/ai-prompts}"
DOTFILES_DIR="$HOME/dotfiles"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Create directory structure
create_structure() {
    print_header "Creating AI Prompts Structure"
    
    # Main directories
    mkdir -p "$AI_PROMPTS_DIR"
    mkdir -p "$AI_PROMPTS_DIR/common/development"
    mkdir -p "$AI_PROMPTS_DIR/common/documentation"
    mkdir -p "$AI_PROMPTS_DIR/common/testing"
    mkdir -p "$AI_PROMPTS_DIR/common/utilities"
    mkdir -p "$AI_PROMPTS_DIR/common/devops"
    mkdir -p "$AI_PROMPTS_DIR/common/data"
    
    # Companies directory
    mkdir -p "$AI_PROMPTS_DIR/companies/template"
    
    # Scripts directory
    mkdir -p "$AI_PROMPTS_DIR/scripts"
    
    # Secrets directory (gitignored)
    mkdir -p "$AI_PROMPTS_DIR/.secrets"
    
    print_success "Created directory structure"
}

# Create template files
create_templates() {
    print_header "Creating Template Files"
    
    # Company template README
    cat > "$AI_PROMPTS_DIR/companies/template/README.md" << 'EOF'
# [Company Name] AI Prompts

## Overview
Company-specific AI prompts and context for [Company Name].

## Structure
- `workflows/` - Company-specific workflows
- `context/` - Business context and domain knowledge
- `integrations/` - Integration-specific prompts
- `standards/` - Company coding standards and guidelines

## Usage
Update this README with company-specific information when setting up.
EOF
    
    # Common prompt examples
    cat > "$AI_PROMPTS_DIR/common/development/code-review.md" << 'EOF'
# Code Review Prompt

Review the following code for:
1. Best practices and design patterns
2. Potential bugs or issues
3. Performance optimizations
4. Security vulnerabilities
5. Code clarity and maintainability

Provide specific suggestions for improvement with examples.

## Context
[Add specific context about the codebase, language, framework]

## Code to Review
```
[Paste code here]
```
EOF
    
    cat > "$AI_PROMPTS_DIR/common/documentation/readme-generator.md" << 'EOF'
# README Generator Prompt

Create a comprehensive README.md for the following project:

## Project Information
- Name: [Project Name]
- Type: [Web App/CLI Tool/Library/etc.]
- Language: [Primary Language]
- Framework: [If applicable]

## Features
[List main features]

## Target Audience
[Describe who will use this]

Include sections for:
1. Overview
2. Features
3. Installation
4. Usage with examples
5. Configuration
6. API Reference (if applicable)
7. Contributing
8. License

Make it clear, professional, and developer-friendly.
EOF
    
    cat > "$AI_PROMPTS_DIR/common/testing/unit-test-generator.md" << 'EOF'
# Unit Test Generator Prompt

Generate comprehensive unit tests for the following code:

## Testing Framework
[Specify: Jest/PHPUnit/Pytest/etc.]

## Code to Test
```
[Paste code here]
```

Include:
1. Happy path tests
2. Edge cases
3. Error handling
4. Boundary conditions
5. Mock external dependencies

Follow testing best practices and include descriptive test names.
EOF
    
    print_success "Created template files"
}

# Create gitignore
create_gitignore() {
    print_header "Setting Up Git Configuration"
    
    cat > "$AI_PROMPTS_DIR/.gitignore" << 'EOF'
# Secrets and sensitive data
.secrets/
*.key
*.token
*.secret
*-secret.*
.env
.env.local
.env.*.local

# Private company data
companies/*/private/
companies/*/.env
companies/*/secrets/

# OS files
.DS_Store
Thumbs.db

# Editor files
*.swp
*.swo
*~
.idea/
.vscode/

# Temporary files
*.tmp
*.temp
*.log

# Backup files
*.backup
*.bak
EOF
    
    print_success "Created .gitignore"
}

# Create secrets template
create_secrets_template() {
    print_header "Creating Secrets Template"
    
    cat > "$AI_PROMPTS_DIR/.secrets/api-keys.env.example" << 'EOF'
# API Keys and Tokens
# Copy this file to api-keys.env and add your actual keys
# NEVER commit the actual api-keys.env file

# OpenAI
OPENAI_API_KEY=sk-...

# Anthropic
ANTHROPIC_API_KEY=sk-ant-...

# GitHub
GITHUB_TOKEN=ghp_...

# ClickUp
CLICKUP_API_KEY=pk_...

# Company-specific keys
SHAKEWELL_API_KEY=...
COMPANY_B_API_KEY=...

# Database URLs (if needed)
DATABASE_URL=...

# Other services
SLACK_TOKEN=...
NOTION_TOKEN=...
LINEAR_API_KEY=...
EOF
    
    # Copy to actual file if doesn't exist
    if [[ ! -f "$AI_PROMPTS_DIR/.secrets/api-keys.env" ]]; then
        cp "$AI_PROMPTS_DIR/.secrets/api-keys.env.example" "$AI_PROMPTS_DIR/.secrets/api-keys.env"
        print_info "Created api-keys.env - add your actual keys"
    fi
    
    print_success "Created secrets template"
}

# Create helper scripts
create_helper_scripts() {
    print_header "Creating Helper Scripts"
    
    # Load secrets script
    cat > "$AI_PROMPTS_DIR/scripts/load-secrets.sh" << 'EOF'
#!/usr/bin/env bash
# Load API keys and secrets into environment

SECRETS_FILE="$HOME/ai-prompts/.secrets/api-keys.env"

if [[ -f "$SECRETS_FILE" ]]; then
    export $(grep -v '^#' "$SECRETS_FILE" | xargs)
    echo "✓ Loaded secrets from $SECRETS_FILE"
else
    echo "✗ Secrets file not found: $SECRETS_FILE"
    exit 1
fi
EOF
    chmod +x "$AI_PROMPTS_DIR/scripts/load-secrets.sh"
    
    print_success "Created helper scripts"
}

# Import existing prompts
import_existing() {
    print_header "Importing Existing Prompts"
    
    # Check for existing ai_scripts directories
    local existing_dirs=(
        "$HOME/ai_scripts_shakewell"
        "$HOME/ai_scripts"
    )
    
    for dir in "${existing_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local company_name=$(basename "$dir" | sed 's/ai_scripts_//')
            if [[ "$company_name" == "ai_scripts" ]]; then
                company_name="imported"
            fi
            
            print_info "Found existing prompts: $dir"
            read -p "Import to companies/$company_name? (y/n) " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                mkdir -p "$AI_PROMPTS_DIR/companies/$company_name"
                cp -r "$dir"/* "$AI_PROMPTS_DIR/companies/$company_name/" 2>/dev/null || true
                print_success "Imported to companies/$company_name"
            fi
        fi
    done
}

# Setup git repository
setup_git() {
    print_header "Setting Up Git Repository"
    
    cd "$AI_PROMPTS_DIR"
    
    if [[ ! -d ".git" ]]; then
        git init
        git add .
        git commit -m "Initial AI prompts structure"
        print_success "Initialized git repository"
    else
        print_info "Git repository already exists"
    fi
}

# Create shell alias
create_alias() {
    print_header "Creating Shell Alias"
    
    # Add to .zshrc.local
    if ! grep -q "alias ai-prompt=" "$HOME/.zshrc.local" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc.local"
        echo "# AI Prompt Management" >> "$HOME/.zshrc.local"
        echo "alias ai-prompt='$DOTFILES_DIR/scripts/ai-prompt'" >> "$HOME/.zshrc.local"
        echo "export AI_PROMPTS_DIR='$AI_PROMPTS_DIR'" >> "$HOME/.zshrc.local"
        print_success "Added ai-prompt alias to ~/.zshrc.local"
        print_info "Run 'source ~/.zshrc' to activate"
    else
        print_info "Alias already exists"
    fi
}

# Main initialization
main() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    AI Prompts Structure Setup          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo
    
    print_info "This will set up AI prompts management at: $AI_PROMPTS_DIR"
    echo
    
    if [[ -d "$AI_PROMPTS_DIR" ]]; then
        print_warning "Directory already exists: $AI_PROMPTS_DIR"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Setup cancelled"
            exit 0
        fi
    fi
    
    create_structure
    create_templates
    create_gitignore
    create_secrets_template
    create_helper_scripts
    import_existing
    setup_git
    create_alias
    
    print_header "Setup Complete!"
    
    print_success "AI prompts structure initialized at: $AI_PROMPTS_DIR"
    echo
    print_info "Next steps:"
    echo "  1. Add your API keys to: $AI_PROMPTS_DIR/.secrets/api-keys.env"
    echo "  2. Import existing prompts: ai-prompt import <path>"
    echo "  3. List available prompts: ai-prompt list"
    echo "  4. Add new prompts: ai-prompt add <category>/<name>.md"
    echo
    print_info "For full documentation, see: $AI_PROMPTS_DIR/README.md"
}

# Run main
main "$@"