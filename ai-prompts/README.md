# AI Prompts & Context Management

A structured, project-based system for managing AI prompts, templates, and workflows for efficient development.

## Overview

This system provides:
- **Ready-to-use templates** for common development tasks
- **Project-based organization** for team collaboration
- **Secure API key management** (never committed to git)
- **Quick access** via CLI commands and aliases
- **Workflow automation** for repetitive tasks

## Directory Structure

```
~/ai-prompts/
├── templates/              # Reusable prompt templates
│   ├── clickup/           # ClickUp ticket templates
│   ├── development/       # API, database, feature templates
│   ├── workflows/         # Complete developer workflows
│   ├── testing/           # Test strategies and generators
│   ├── debugging/         # Bug investigation templates
│   ├── refactoring/       # Code improvement plans
│   │── reviews/           # Code review checklists
│   └── documentation/     # Doc generation templates
├── projects/              # Project-specific content
│   ├── [project-name]/   # Your project folders
│   └── template/         # Template for new projects
├── scripts/              # Helper scripts
└── .secrets/            # API keys (gitignored)
    └── api-keys.env     # Your secret keys
```

## Key Templates Available

### 🎯 ClickUp Ticket Creation
Perfect structured tickets every time:
```bash
aipc create-ticket  # Copy template and fill in details
```

### 👨‍💻 Laravel Backend Workflow
Complete development workflow from ticket to PR:
```bash
aipc laravel-backend-developer  # Full workflow template
```

### 🐛 Bug Investigation
Systematic approach to debugging:
```bash
aipc bug-investigation  # Structured debugging process
```

### 🚀 API Endpoint Development
Consistent API implementation:
```bash
aipc api-endpoint  # REST API template with all considerations
```

### 🧪 Testing Strategy
Comprehensive test planning:
```bash
aipc test-strategy  # Testing pyramid approach
```

## Quick Start

### Setup

1. Initialize the AI prompts structure:
```bash
~/dotfiles/scripts/ai-prompts-init.sh
```

2. Configure your API keys:
```bash
vim ~/ai-prompts/.secrets/api-keys.env
# Add your ClickUp, GitHub, and other API keys
```

3. Set your current project (optional):
```bash
export AI_PROMPT_PROJECT=myproject
echo "export AI_PROMPT_PROJECT=myproject" >> ~/.zshrc.local
```

### Daily Usage

#### Access templates quickly
```bash
# List all templates
aip list                    # or ai-prompt list

# View a specific template
aip show create-ticket      # Shows ClickUp ticket template

# Copy template to clipboard (ready to paste)
aipc create-ticket          # or ai-prompt copy create-ticket
aipc laravel-backend        # Copy Laravel workflow
```

#### Add new content
```bash
# Add to templates
aipa development/new-api-template.md

# Add to current project
export AI_PROMPT_PROJECT=myproject
aipa workflows/custom-workflow.md
```

#### Share templates to projects
```bash
# Share a template to your project
ai-prompt share create-ticket myproject

# Share workflow template
ai-prompt share laravel-backend myproject
```

## Organization Guidelines

### Templates

Reusable templates in `templates/` directory:
- **clickup/**: Ticket creation and management
- **development/**: API endpoints, migrations, features
- **workflows/**: Complete developer workflows
- **testing/**: Test strategies and generators
- **debugging/**: Bug investigation processes
- **refactoring/**: Code improvement plans
- **reviews/**: Code review checklists
- **documentation/**: README and API doc generators

### Project-Specific Content

Store in `projects/<project-name>/`:
- Project-specific workflows
- Custom context and requirements
- API integrations
- Team conventions

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
- `projects/*/private/`

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

## Project Template

When starting with a new project:

1. Copy the template:
```bash
cp -r ~/ai-prompts/projects/template ~/ai-prompts/projects/new-project
```

2. Update the project README:
```bash
vim ~/ai-prompts/projects/new-project/README.md
```

3. Add project-specific content and scripts

## Best Practices

1. **Version Control**: Commit prompts regularly (except sensitive data)
2. **Documentation**: Include context and usage examples in prompts
3. **Modularity**: Keep prompts focused and reusable
4. **Organization**: Use clear directory structure and naming
5. **Security**: Never hardcode API keys or credentials
6. **Sharing**: Use templates/ for reusable prompts
7. **Testing**: Validate prompts before committing

## Command Reference

### ai-prompt CLI

```bash
# List all prompts
ai-prompt list [project-name]

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