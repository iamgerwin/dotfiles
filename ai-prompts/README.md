# AI Prompts & Context Management

A structured system for managing, organizing, and sharing AI prompts and context scripts across different companies and projects.

## Overview

This system provides a clean, organized way to:
- Store and version control AI prompts and context
- Share common prompts between companies/projects
- Keep sensitive data secure and out of git
- Maintain company-specific customizations
- Quickly access and deploy prompts

## Directory Structure

```
~/ai-prompts/
├── common/                  # Shared prompts across all companies
│   ├── development/        # Development-related prompts
│   ├── documentation/      # Documentation prompts
│   ├── testing/           # Testing and QA prompts
│   └── utilities/         # General utility prompts
├── companies/             # Company-specific prompts
│   ├── shakewell/        # Shakewell-specific
│   ├── company-b/        # Another company
│   └── template/         # Template for new companies
├── scripts/              # Management scripts
│   ├── sync.sh          # Sync prompts
│   ├── share.sh         # Share prompts between companies
│   └── secure.sh        # Manage sensitive data
└── .secrets/            # Sensitive data (gitignored)
    └── api-keys.env     # API keys and tokens
```

## Quick Start

### Setup

1. Initialize the AI prompts structure:
```bash
~/dotfiles/scripts/ai-prompts-init.sh
```

2. Import existing prompts:
```bash
~/dotfiles/scripts/ai-prompts-import.sh ~/ai_scripts_shakewell shakewell
```

3. Configure sensitive data:
```bash
cp ~/ai-prompts/.secrets/api-keys.env.example ~/ai-prompts/.secrets/api-keys.env
# Edit with your actual API keys
```

### Daily Usage

#### Access a prompt
```bash
# List available prompts
ai-prompt list

# View a specific prompt
ai-prompt show development/laravel-migration

# Copy prompt to clipboard
ai-prompt copy testing/unit-test-generator
```

#### Add new prompt
```bash
# Add to common prompts
ai-prompt add common/development/new-feature-prompt.md

# Add company-specific prompt
ai-prompt add shakewell/specific-workflow.md
```

#### Share prompt between companies
```bash
# Share a prompt from shakewell to company-b
ai-prompt share shakewell/useful-prompt.md company-b
```

## Organization Guidelines

### Common Prompts

Store in `common/` directory, organized by category:
- **development/**: Code generation, refactoring, debugging
- **documentation/**: README, API docs, comments
- **testing/**: Test generation, QA scenarios
- **utilities/**: Data processing, formatting, analysis

### Company-Specific Prompts

Store in `companies/<company-name>/`:
- Proprietary workflows
- Company-specific context
- Custom integrations
- Team-specific standards

### Naming Convention

Use descriptive, searchable names:
- `laravel-migration-generator.md`
- `react-component-builder.md`
- `api-endpoint-documenter.md`
- `clickup-task-formatter.md`

## Security

### Sensitive Data Handling

Never commit sensitive data to git. Use the `.secrets/` directory:

```bash
# .secrets/api-keys.env (gitignored)
OPENAI_API_KEY=sk-...
GITHUB_TOKEN=ghp_...
CLICKUP_API_KEY=pk_...
```

Load secrets when needed:
```bash
source ~/ai-prompts/.secrets/api-keys.env
```

### Gitignore Pattern

The following are automatically gitignored:
- `.secrets/`
- `*.key`
- `*.token`
- `*-secret.*`
- `companies/*/private/`

## Syncing Between Machines

### Export prompts
```bash
ai-prompt export ~/Desktop/ai-prompts-backup.tar.gz
```

### Import on another machine
```bash
ai-prompt import ~/Desktop/ai-prompts-backup.tar.gz
```

### Sync via git (non-sensitive only)
```bash
cd ~/ai-prompts
git pull
git push
```

## Company Template

When starting with a new company:

1. Copy the template:
```bash
cp -r ~/ai-prompts/companies/template ~/ai-prompts/companies/new-company
```

2. Update the metadata:
```bash
echo "Company: New Company" > ~/ai-prompts/companies/new-company/README.md
```

3. Add company-specific prompts

## Best Practices

1. **Version Control**: Commit prompts regularly (except sensitive data)
2. **Documentation**: Include context and usage examples in prompts
3. **Modularity**: Keep prompts focused and reusable
4. **Organization**: Use clear directory structure and naming
5. **Security**: Never hardcode API keys or credentials
6. **Sharing**: Use common/ for universally useful prompts
7. **Testing**: Validate prompts before committing

## Command Reference

### ai-prompt CLI

```bash
# List all prompts
ai-prompt list [--company=shakewell]

# Search prompts
ai-prompt search "laravel"

# Show prompt content
ai-prompt show <prompt-path>

# Copy to clipboard
ai-prompt copy <prompt-path>

# Add new prompt
ai-prompt add <category>/<prompt-name>.md

# Share between companies
ai-prompt share <source-prompt> <target-company>

# Export/Import
ai-prompt export <backup-file>
ai-prompt import <backup-file>

# Sync with git
ai-prompt sync
```

## Troubleshooting

### Missing prompts after sync
```bash
# Ensure you're in the right directory
cd ~/ai-prompts
git status
git pull
```

### Sensitive data accidentally committed
```bash
# Remove from git history
git filter-branch --tree-filter 'rm -f path/to/sensitive-file' HEAD
# Force push (be careful!)
git push --force
```

### Prompt not found
```bash
# Rebuild index
ai-prompt reindex
```

## Contributing

1. Follow the naming convention
2. Place prompts in appropriate categories
3. Include usage examples
4. Test prompts before committing
5. Never commit sensitive data

## License

Your prompts are your intellectual property. This system is a management tool only.