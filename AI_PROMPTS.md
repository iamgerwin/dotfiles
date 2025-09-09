# AI Prompts Management

A comprehensive system for organizing, managing, and sharing AI prompts and context scripts across different companies and projects.

## Quick Setup

```bash
# Initialize AI prompts structure
~/dotfiles/scripts/ai-prompts-init.sh

# Import existing prompts (if you have any)
~/dotfiles/scripts/ai-prompts-init.sh
# Follow the prompts to import from existing directories
```

## Usage

### Basic Commands

```bash
# List all prompts
aip list                    # or ai-prompt list

# Search for prompts
aips "laravel"              # or ai-prompt search "laravel"

# Show prompt content
ai-prompt show development/code-review

# Copy prompt to clipboard
aipc development/code-review  # or ai-prompt copy development/code-review

# Add new prompt
aipa development/new-feature  # or ai-prompt add development/new-feature
```

### Directory Structure

```
~/ai-prompts/
├── templates/              # Reusable prompt templates
│   ├── clickup/           # ClickUp ticket management
│   ├── development/       # API endpoints, migrations
│   ├── workflows/         # Developer workflows
│   ├── testing/           # Test strategies, unit tests
│   ├── debugging/         # Bug investigation
│   ├── refactoring/       # Code refactoring plans
│   ├── reviews/           # Code review checklists
│   └── documentation/     # README, API docs
├── projects/              # Project-specific content
│   ├── shakewell/        # Shakewell project
│   ├── [project-name]/   # Other projects
│   └── template/         # Template for new projects
├── scripts/              # Helper scripts
└── .secrets/            # API keys and tokens (gitignored)
    └── api-keys.env     # Never committed to git
```

## Managing Sensitive Data

### API Keys and Secrets

Store all sensitive data in the `.secrets` directory:

```bash
# Edit your API keys (never committed to git)
vim ~/ai-prompts/.secrets/api-keys.env

# Example content:
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GITHUB_TOKEN=ghp_...
CLICKUP_API_KEY=pk_...
```

### Load Secrets

```bash
# Load API keys into environment
source ~/ai-prompts/scripts/load-secrets.sh
```

## Project Management

### Add New Project

```bash
# Create project structure
mkdir -p ~/ai-prompts/projects/new-project

# Copy template
cp -r ~/ai-prompts/projects/template/* ~/ai-prompts/projects/new-project/

# Set as current project
export AI_PROMPT_PROJECT=new-project

# Edit project README
vim ~/ai-prompts/projects/new-project/README.md
```

### Share Templates to Projects

```bash
# Share a template to a project
ai-prompt share create-ticket.md my-project

# Share workflow to project
ai-prompt share laravel-backend-developer.md shakewell

# Copy all testing templates to project
for template in ~/ai-prompts/templates/testing/*.md; do
    ai-prompt share "testing/$(basename $template)" my-project
done
```

## Syncing and Backup

### Export Prompts

```bash
# Export all prompts (excludes secrets)
ai-prompt export ~/Desktop/ai-prompts-backup.tar.gz

# Export to default location
ai-prompt export
```

### Import Prompts

```bash
# Import from backup
ai-prompt import ~/Desktop/ai-prompts-backup.tar.gz
```

### Git Synchronization

```bash
# Initialize git if not already done
cd ~/ai-prompts
git init

# Sync with git (commits and pushes changes)
ai-prompt sync

# Manual git operations
cd ~/ai-prompts
git add .
git commit -m "Update prompts"
git push
```

## Template Categories

### ClickUp (`templates/clickup/`)
- **create-ticket.md** - Comprehensive ticket creation template
- Bug reports, features, tasks, documentation tickets
- Acceptance criteria and priority setting

### Development (`templates/development/`)
- **api-endpoint.md** - REST API endpoint development
- **database-migration.md** - Database schema changes
- Model creation, service layers, controllers

### Workflows (`templates/workflows/`)
- **laravel-backend-developer.md** - Complete Laravel workflow
- Frontend developer workflows
- DevOps deployment workflows

### Testing (`templates/testing/`)
- **test-strategy.md** - Comprehensive testing approach
- Unit test generators
- Integration test scenarios
- E2E test automation

### Debugging (`templates/debugging/`)
- **bug-investigation.md** - Systematic bug analysis
- Performance troubleshooting
- Memory leak detection

### Refactoring (`templates/refactoring/`)
- **refactor-plan.md** - Code refactoring strategy
- Technical debt reduction
- Performance optimization

### Reviews (`templates/reviews/`)
- **code-review.md** - Code review checklist
- Architecture reviews
- Security audits

### Documentation (`templates/documentation/`)
- README generators
- API documentation
- Technical specifications

## Best Practices

### Prompt Organization

1. **Use Clear Names**: `laravel-migration-generator.md` not `lmg.md`
2. **Include Context**: Add usage examples and expected inputs
3. **Version Control**: Commit regularly with meaningful messages
4. **Categorize Properly**: Place prompts in appropriate directories
5. **Document Dependencies**: Note required tools or APIs

### Security

1. **Never Commit Secrets**: Use `.secrets/` directory
2. **Use Environment Variables**: Load from `api-keys.env`
3. **Gitignore Sensitive Files**: Already configured
4. **Separate Company Data**: Keep proprietary info in company folders
5. **Regular Backups**: Export prompts periodically

### Sharing

1. **Use Common for Shared**: Place reusable prompts in `common/`
2. **Company-Specific**: Keep proprietary in `companies/[name]/`
3. **Document Context**: Include company-specific context
4. **Share Selectively**: Use `ai-prompt share` command
5. **Review Before Sharing**: Check for sensitive data

## Troubleshooting

### Prompt Not Found

```bash
# Check if prompt exists
find ~/ai-prompts -name "*prompt-name*"

# List all prompts
ai-prompt list

# Search for prompt
ai-prompt search "keyword"
```

### Permission Issues

```bash
# Fix permissions
chmod -R 755 ~/ai-prompts
chmod 600 ~/ai-prompts/.secrets/api-keys.env
```

### Git Issues

```bash
# Reset git if needed
cd ~/ai-prompts
git status
git reset --hard HEAD
```

## Environment Variables

```bash
# Set default project
export AI_PROMPT_PROJECT=shakewell

# Set custom prompts directory
export AI_PROMPTS_DIR=~/custom-prompts

# Add to ~/.zshrc.local for persistence
echo "export AI_PROMPT_PROJECT=shakewell" >> ~/.zshrc.local
```

## Advanced Usage

### Custom Templates

Create custom templates for your workflow:

```bash
# Create template
cat > ~/ai-prompts/companies/shakewell/templates/feature.md << 'EOF'
# Feature: [FEATURE_NAME]

## Context
Project: [PROJECT]
Framework: Laravel/Vue
Database: PostgreSQL

## Requirements
[Paste requirements here]

## Implementation Plan
1. Database migrations
2. Model and relationships
3. API endpoints
4. Frontend components
5. Tests

## Code Generation Request
Generate the implementation following our coding standards:
- PSR-12 for PHP
- Vue 3 Composition API
- TypeScript where applicable
- Full test coverage
EOF
```

### Batch Operations

Process multiple prompts:

```bash
# Copy all development prompts to company
for prompt in ~/ai-prompts/common/development/*.md; do
    ai-prompt share "common/development/$(basename $prompt)" shakewell
done
```

### Integration with Scripts

Use prompts in automation:

```bash
#!/bin/bash
# load-and-execute.sh

# Load prompt
PROMPT=$(ai-prompt show development/code-review)

# Use with CLI tools
echo "$PROMPT" | some-ai-cli-tool

# Or copy to clipboard for manual use
echo "$PROMPT" | pbcopy
```

## Contributing

1. Follow the directory structure
2. Use meaningful names
3. Include usage examples
4. Test prompts before committing
5. Never include sensitive data

## Related Documentation

- [Main README](README.md) - Dotfiles documentation
- [Installation Guide](INSTALLATION.md) - Setup instructions
- [Terminal Setup](TERMINAL_SETUP.md) - Terminal configuration

## License

Your prompts are your intellectual property. This management system is part of the dotfiles project under MIT license.