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
├── common/                 # Shared prompts for all projects
│   ├── development/       # Code generation, reviews, refactoring
│   ├── documentation/     # README, API docs, comments
│   ├── testing/          # Unit tests, integration tests
│   ├── utilities/        # Data processing, formatting
│   ├── devops/          # CI/CD, deployment, infrastructure
│   └── data/            # Data analysis, processing
├── companies/            # Company-specific prompts
│   ├── shakewell/       # Shakewell-specific workflows
│   ├── [company-name]/  # Other companies
│   └── template/        # Template for new companies
├── scripts/             # Helper scripts
└── .secrets/           # API keys and tokens (gitignored)
    └── api-keys.env    # Never committed to git
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

## Company Management

### Add New Company

```bash
# Create company structure
mkdir -p ~/ai-prompts/companies/new-company

# Copy template
cp -r ~/ai-prompts/companies/template/* ~/ai-prompts/companies/new-company/

# Set as current company
export AI_PROMPT_COMPANY=new-company
```

### Share Prompts Between Companies

```bash
# Share a prompt from current company to another
ai-prompt share workflows/deploy-process.md other-company

# Share from common to company
ai-prompt share common/development/code-review.md shakewell
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

## Categories Guide

### Development (`common/development/`)
- Code generation and scaffolding
- Code reviews and refactoring
- Debugging and troubleshooting
- Performance optimization
- Security audits

### Documentation (`common/documentation/`)
- README generators
- API documentation
- Code comments
- User guides
- Technical specifications

### Testing (`common/testing/`)
- Unit test generation
- Integration test scenarios
- E2E test scripts
- Test data generation
- QA checklists

### Utilities (`common/utilities/`)
- Data formatting and conversion
- Text processing
- File operations
- Automation scripts
- Analysis tools

### DevOps (`common/devops/`)
- CI/CD pipelines
- Deployment scripts
- Infrastructure as Code
- Monitoring and logging
- Container configurations

### Data (`common/data/`)
- Data analysis prompts
- ETL processes
- Database queries
- Data visualization
- Report generation

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
# Set default company
export AI_PROMPT_COMPANY=shakewell

# Set custom prompts directory
export AI_PROMPTS_DIR=~/custom-prompts

# Add to ~/.zshrc.local for persistence
echo "export AI_PROMPT_COMPANY=shakewell" >> ~/.zshrc.local
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