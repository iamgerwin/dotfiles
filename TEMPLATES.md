# 📋 Prompt Templates Quick Reference

Quick access to all development prompt templates. Use `pc <template>` to copy any template to clipboard.

## 🚀 Quick Copy Commands

```bash
pc list                  # Show all available templates
pc create-ticket         # ClickUp ticket creation
pc laravel              # Laravel backend workflow
pc bug                  # Bug investigation template
pc feature              # Feature implementation
pc api                  # API endpoint development
pc deployment           # Deployment checklist
```

## 📂 Available Templates

### ClickUp Templates
| Command | Template | Description |
|---------|----------|-------------|
| `pc create-ticket` | ClickUp Ticket Creation | Complete ticket structure with all sections |
| `pct` | Quick Ticket | Alias for create-ticket |

### Developer Workflows
| Command | Template | Description |
|---------|----------|-------------|
| `pc laravel-backend` | Laravel Backend Developer | Full workflow from ticket to PR |
| `pcl` | Laravel Quick | Alias for laravel-backend |
| `pc usisa-laravel` | USISA Project Workflow | Project-specific Laravel workflow |

### Development Templates
| Command | Template | Description |
|---------|----------|-------------|
| `pc feature` | Feature Implementation | Complete feature planning and implementation |
| `pcf` | Feature Quick | Alias for feature |
| `pc api-endpoint` | API Endpoint | REST API development template |
| `pca` | API Quick | Alias for api-endpoint |
| `pc database-migration` | Database Migration | Schema changes and migrations |

### Testing Templates
| Command | Template | Description |
|---------|----------|-------------|
| `pc test-strategy` | Testing Strategy | Comprehensive testing approach |
| `pc comprehensive-test` | Full Testing Examples | Complete testing with code examples |

### Debugging Templates
| Command | Template | Description |
|---------|----------|-------------|
| `pc bug-investigation` | Bug Investigation | Systematic debugging process |
| `pcb` | Bug Quick | Alias for bug |
| `pc performance` | Performance Optimization | Performance analysis and optimization |

### DevOps Templates
| Command | Template | Description |
|---------|----------|-------------|
| `pc deployment` | Deployment Checklist | Complete deployment process |
| `pcd` | Deploy Quick | Alias for deployment |

### Code Review
| Command | Template | Description |
|---------|----------|-------------|
| `pc code-review` | Code Review Checklist | Comprehensive review template |
| `pc refactor-plan` | Refactoring Plan | Code refactoring strategy |

## 💡 Usage Examples

### Creating a ClickUp Ticket
```bash
# Copy the template
pc create-ticket

# Paste in your LLM
# Fill in the placeholders:
# - [Insert task/bug/feature/refactor/issue here]
# - [real title here]
# - [real description here]
# The LLM will generate a complete, well-structured ticket
```

### Starting Laravel Development
```bash
# Copy the Laravel workflow
pcl

# Paste in your LLM with:
# - The ClickUp ticket URL
# - Any specific requirements
# The LLM will guide you through the entire development process
```

### Investigating a Bug
```bash
# Copy bug investigation template
pcb

# Paste in your LLM with:
# - Bug description
# - Steps to reproduce
# - Error messages
# The LLM will help systematically debug the issue
```

### Planning a Feature
```bash
# Copy feature template
pcf

# Paste in your LLM with:
# - Feature requirements
# - Technical constraints
# The LLM will create a complete implementation plan
```

## 🔧 Template Locations

Templates are stored in two locations:

1. **Dotfiles Templates** (`~/dotfiles/templates/`)
   - Version controlled templates
   - Comprehensive examples with code
   - Full workflows and processes

2. **AI Prompts Templates** (`~/ai-prompts/templates/`)
   - Quick reference templates
   - Project-agnostic prompts
   - Initialized via `ai-prompts-init.sh`

## 📝 Adding Custom Templates

### Add to Dotfiles (Version Controlled)
```bash
# Create new template
vim ~/dotfiles/templates/category/my-template.md

# Update prompt-copy script to include it
vim ~/dotfiles/scripts/prompt-copy

# Add alias for quick access
echo "alias pcm='prompt-copy my-template'" >> ~/dotfiles/aliases.zsh
```

### Add to AI Prompts (Local)
```bash
# Use the ai-prompt CLI
aipa templates/category/my-template.md

# Or directly create
vim ~/ai-prompts/templates/category/my-template.md
```

## 🏗️ Project-Specific Templates

Set your current project for context-aware templates:

```bash
# Set project context
export AI_PROMPT_PROJECT=myproject

# Add to .zshrc.local for persistence
echo "export AI_PROMPT_PROJECT=myproject" >> ~/.zshrc.local

# Copy project-specific templates
pc usisa-laravel  # For USISA project
```

## 🔑 API Keys Configuration

Templates use environment variables for API keys:

```bash
# Edit your API keys
vim ~/ai-prompts/.secrets/api-keys.env

# Add required keys:
CLICKUP_API_KEY=pk_...
GITHUB_TOKEN=ghp_...
SLACK_WEBHOOK=https://hooks.slack.com/...

# Load keys when needed
source ~/ai-prompts/.secrets/api-keys.env
```

## 🎯 Best Practices

1. **Fill Placeholders Carefully**: Templates have `[placeholders]` - replace with actual content
2. **Keep Context**: Provide full context when using workflow templates
3. **Use Aliases**: Leverage quick aliases (`pct`, `pcl`, `pcb`) for frequently used templates
4. **Customize**: Modify templates for your specific needs
5. **Version Control**: Keep custom templates in dotfiles for team sharing

## 📚 Template Categories

### By Task Type
- **Planning**: Feature implementation, refactoring plans
- **Development**: API endpoints, database migrations, features
- **Testing**: Unit tests, integration tests, E2E tests
- **Debugging**: Bug investigation, performance optimization
- **Operations**: Deployment, monitoring, infrastructure
- **Review**: Code reviews, architecture reviews

### By Project Phase
- **Discovery**: Requirements gathering, technical research
- **Implementation**: Coding templates, patterns
- **Verification**: Testing strategies, review checklists
- **Deployment**: Release processes, rollback plans
- **Maintenance**: Bug fixes, performance tuning

## 🛠️ Troubleshooting

### Template Not Found
```bash
# List all available templates
pc list

# Check template locations
ls ~/dotfiles/templates/
ls ~/ai-prompts/templates/
```

### Clipboard Not Working
```bash
# On macOS, ensure pbcopy is available
which pbcopy

# Alternative: view the template file directly
cat ~/dotfiles/templates/clickup/create-ticket-full.md
```

### Missing Templates After Setup
```bash
# Initialize AI prompts structure
~/dotfiles/scripts/ai-prompts-init.sh

# This creates all template directories and base templates
```

## 🚦 Quick Start Workflow

1. **Pick a Task**: Identify what you need to do
2. **Copy Template**: Use `pc <template>` to copy
3. **Paste in LLM**: Open your preferred LLM
4. **Fill Details**: Replace placeholders with actual information
5. **Execute**: Follow the generated plan/code

---

Remember: Templates are starting points. Customize them for your specific needs and workflow.