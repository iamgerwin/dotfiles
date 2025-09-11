# Dotfiles - Personal Development Environment Configuration

A modular, maintainable approach to managing shell configurations and development environment across multiple macOS machines.

## Overview

This repository contains my personal dotfiles configuration, designed with modularity and maintainability in mind. The configuration is split into logical components, making it easy to understand, modify, and sync across different workstations.

## Features

- **Adaptive Setup**: Intelligently learns from and preserves existing user customizations
- **Zero Disruption**: Integrates with your current workflow without breaking anything
- **Modular Configuration**: Shell settings are organized into separate files by functionality
- **Cross-Machine Sync**: Easy synchronization between personal and work computers
- **Automated Setup**: One-command installation for new machines
- **Package Management**: Centralized Homebrew package management via Brewfile
- **Version Control**: All configurations tracked in Git for easy rollback and history
- **Oh My Zsh Integration**: Pre-configured with useful plugins and Powerlevel10k theme
- **Development Tools**: NVM, Pyenv, Herd PHP, and other development environment managers
- **Laravel/PHP Ready**: Aliases and tools for Laravel development workflow
- **Custom Preservation**: Automatically detects and preserves your existing aliases, functions, and tools
- **AI Prompts Management**: Organized system for managing AI prompts and context scripts by company/project
- **Best Practices Documentation**: Comprehensive guides for modern development technologies and frameworks

## Structure

```
dotfiles/
├── .zshrc              # Main configuration file that sources all modules
├── aliases.zsh         # Command shortcuts and aliases (git, Laravel, Docker)
├── exports.zsh         # Environment variables and PATH configuration
├── functions.zsh       # Custom shell functions and utilities
├── options.zsh         # Zsh shell options and settings
├── plugins.zsh         # Plugin configurations (Oh My Zsh, NVM, Pyenv)
├── keybindings.zsh     # Custom keyboard shortcuts
├── prompt.zsh          # Shell prompt appearance and behavior
├── custom.zsh          # Machine-specific configurations
├── p10k.zsh            # Powerlevel10k prompt configuration
├── tmux.conf           # Tmux configuration with best practices
├── Brewfile            # Homebrew package definitions
├── AI_PROMPTS.md       # AI prompts management documentation
├── TEMPLATES.md        # Quick reference for all prompt templates
├── setup.sh            # Automated setup script
├── docs/               # Documentation directory
│   └── best-practices/ # Comprehensive technology guides
│       ├── frontend/   # Frontend frameworks and libraries
│       ├── backend/    # Backend frameworks and APIs
│       ├── mobile/     # Mobile development platforms
│       ├── database/   # Database technologies
│       ├── devops/     # DevOps and cloud platforms
│       ├── cms/        # Content Management Systems
│       ├── enterprise/ # Enterprise software platforms
│       ├── security/   # Security frameworks and compliance
│       ├── testing/    # Testing frameworks and tools
│       ├── languages/  # Programming languages
│       ├── editors/    # Code editors and IDEs
│       ├── stacks/     # Technology stacks (LAMP, MERN, etc.)
│       ├── system-architecture/ # API design and architecture
│       ├── machine-learning/    # AI/ML best practices
│       ├── version-control/ # Git workflows and best practices
│       └── programming-principles/ # Core programming principles and patterns
├── ai-prompts/         # AI prompts management system
└── scripts/
    ├── install-brew.sh # Homebrew installation script
    ├── setup-tmux.sh   # Tmux setup and configuration script
    ├── backup.sh       # Backup management script
    ├── uninstall.sh    # Uninstall and rollback script
    ├── ai-prompt       # AI prompts CLI tool
    ├── ai-prompts-init.sh # AI prompts initialization
    └── prompt-copy     # Quick template copy to clipboard
```

## Quick Start

### 🎯 Adaptive Setup for Existing Configurations

If you already have a working .zshrc and custom setup, use our **Adaptive Setup** that preserves everything:

```bash
# Clone the repository
git clone https://github.com/iamgerwin/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run adaptive setup - learns from your existing configuration
./scripts/adaptive-setup.sh
```

This will:
- ✅ Detect and preserve all your custom aliases and functions
- ✅ Capture your installed packages (Homebrew, npm, VS Code extensions)
- ✅ Keep sensitive data separate and secure
- ✅ Create restoration scripts for your complete environment
- ✅ Integrate dotfiles without disrupting your workflow

#### Alternative: Standard Setup with Migration

```bash
# Run the main setup - it will offer adaptive mode
./setup.sh
# Choose option 1: "Adaptive setup - Preserve all customizations"
```

### 🆕 For New Mac or Fresh Installation

Run this single command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/iamgerwin/dotfiles/main/setup.sh)"
```

This will:
1. Install Homebrew (if not present)
2. Clone this repository
3. Create backups of any existing configurations
4. Install all packages from Brewfile
5. Set up symbolic links
6. Configure your shell environment
7. Prompt you to configure Powerlevel10k theme

### 🔒 Safety Features

Every installation automatically:
- **Creates timestamped backups** before making any changes
- **Stores backups** in `~/.dotfiles-backup/` with a JSON manifest
- **Preserves all original files** with timestamps
- **Provides instant rollback** capability via `uninstall.sh`
- **Never overwrites** without backing up first

### 📖 Important: Terminal Font & Theme Setup

**Powerlevel10k requires a Nerd Font** to display icons correctly. Without it, you'll see question marks in your prompt.

**After installation, complete these final steps:**

1. **Install the required font**:
   ```bash
   brew install --cask font-meslo-lg-nerd-font
   ```

2. **Set your terminal font** to **MesloLGS NF**. See [TERMINAL_SETUP.md](TERMINAL_SETUP.md) for detailed instructions.

3. **Configure your prompt theme**:
   ```bash
   p10k configure
   ```
   This interactive wizard will help you customize your prompt appearance with icons, colors, and layout options.

4. **Restart your terminal** to see the final result.

### 📖 Detailed Installation Guide

For step-by-step instructions and troubleshooting, see [INSTALLATION.md](INSTALLATION.md)

## Configuration Files

### Core Modules

- **aliases.zsh**: Command shortcuts including:
  - Git workflow aliases (gc, gpod, gdog, gclean, gdp)
  - Laravel/PHP development (art, sail, pint, pbc)
  - Docker shortcuts (dps, dpsa, di, dex)
  - System utilities (brewu, reload, dotfiles)
- **exports.zsh**: PATH and environment variables for:
  - Herd PHP configuration (multiple PHP versions)
  - NVM (Node Version Manager)
  - Pyenv (Python Version Manager)
  - Windsurf, Homebrew, and other tools
- **functions.zsh**: Reusable shell functions for productivity
- **options.zsh**: Zsh behavior settings (history, completion, etc.)
- **plugins.zsh**: Configurations for:
  - Oh My Zsh with Powerlevel10k theme
  - Development plugins (git, docker, laravel, composer)
  - Auto-suggestions and syntax highlighting
  - NVM and Pyenv initialization
- **keybindings.zsh**: Terminal keyboard shortcuts
- **prompt.zsh**: Additional prompt customization
- **custom.zsh**: Local overrides and machine-specific settings
- **p10k.zsh**: Powerlevel10k prompt configuration
- **tmux.conf**: Professional tmux configuration with:
  - Vim-style keybindings and smart pane navigation
  - Enhanced status bar with system information
  - macOS clipboard integration
  - Session persistence with tmux-resurrect
  - Optimized performance settings
  - Custom development layouts and scripts

### Package Management

The `Brewfile` contains all Homebrew packages, casks, and fonts. To manage packages:

```bash
# Install all packages
brew bundle install

# Update all packages
brew bundle update

# Check what would be cleaned up
brew bundle cleanup --dry-run

# Remove packages not in Brewfile
brew bundle cleanup
```

## Syncing Between Machines

### Pull Latest Changes

```bash
cd ~/dotfiles
git pull
brew bundle install  # Install any new packages
source ~/.zshrc      # Reload configuration
```

### Push Local Changes

```bash
cd ~/dotfiles
git add .
git commit -m "Update configurations"
git push
```

### Update All Packages

```bash
# Update Homebrew and all packages
brew update && brew upgrade && brew cleanup

# Update package list in Brewfile
brew bundle dump --force --file=~/dotfiles/Brewfile
```

## Customization

### Machine-Specific Settings

Create a `.zshrc.local` file in your home directory for machine-specific configurations that shouldn't be shared:

```bash
echo "export WORK_SPECIFIC_VAR=value" >> ~/.zshrc.local
```

### Private/Sensitive Data

Store sensitive information in `~/.zshrc.private` (not tracked by Git):

```bash
echo "export SECRET_API_KEY=xxx" >> ~/.zshrc.private
```

### AI Prompts Management

Manage AI prompts and context scripts organized by company/project:

```bash
# Initialize AI prompts system
~/dotfiles/scripts/ai-prompts-init.sh

# List available prompts
ai-prompt list

# Search for prompts
ai-prompt search "laravel"

# Copy prompt to clipboard
ai-prompt copy development/code-review
```

See [AI_PROMPTS.md](AI_PROMPTS.md) for complete documentation.

### Tmux Configuration

The dotfiles include a comprehensive tmux setup with productivity-focused features:

```bash
# Setup tmux (automatically done during installation)
~/dotfiles/scripts/setup-tmux.sh

# Quick commands
tl              # List all sessions
ts myproject    # Create new session named 'myproject'
ta myproject    # Attach to session
tdev            # Launch development session with predefined layout
tproject name ~/path  # Create project-specific session

# Key bindings (after pressing Ctrl-a)
|     # Split pane horizontally
-     # Split pane vertically
h/j/k/l  # Navigate panes (vim-style)
H/J/K/L  # Resize panes
z     # Toggle pane zoom
r     # Reload configuration
```

The configuration includes:
- **TPM (Tmux Plugin Manager)** for plugin management
- **tmux-resurrect** for session persistence across restarts
- **tmux-continuum** for automatic session saves
- **vim-tmux-navigator** for seamless vim/tmux navigation
- **Custom scripts** for development workflows

### Best Practices Documentation

Access comprehensive development guides for modern technologies:

```bash
# Browse documentation
open ~/dotfiles/docs/best-practices/

# Quick reference by category:
ls ~/dotfiles/docs/best-practices/frontend/    # React, Vue, Angular, etc.
ls ~/dotfiles/docs/best-practices/backend/     # Laravel, Django, NestJS, etc.
ls ~/dotfiles/docs/best-practices/mobile/      # Flutter, React Native, etc.
ls ~/dotfiles/docs/best-practices/devops/      # AWS, Docker, Cloudflare, etc.
```

#### Available Technologies

**Frontend & UI**
- React ecosystem (Next.js, Jotai), Vue.js (Nuxt.js v4), Vaadin
- State Management: Redux Toolkit, Zustand, MobX, Context API
- Svelte & SvelteKit with Runes reactivity system
- Authentication: Clerk, Better Auth
- UI libraries: shadcn/ui, Bootstrap, Tailwind CSS
- Animation: GSAP
- Data management: TanStack (Query, Router, Start, DB)
- Legacy: jQuery

**Backend & APIs**
- PHP: Laravel, Laravel Nova, Laravel Eloquent ORM, Laravel Filament v4, Symfony with API Platform, CodeIgniter 4
- JavaScript/TypeScript: NestJS, Hono.js, Meteor.js
- Python: Django, general Python best practices
- Ruby: Ruby on Rails
- Elixir: Ash framework
- .NET: ASP.NET Core with C#, Entity Framework Core
- Java: Modern Java features, Spring Boot integration
- BaaS: Appwrite (open-source Firebase alternative)

**Mobile Development**
- Cross-platform: Flutter, React Native, .NET MAUI
- Native: Swift (iOS), Kotlin (Android)

**Database & Storage**
- ORM: Prisma, Entity Framework Core
- Relational: PostgreSQL, Neon (serverless PostgreSQL)
- NoSQL: MongoDB, Firestore, CouchDB, DynamoDB (AWS managed NoSQL)
- Key-Value: Redis (caching, sessions, pub/sub), Valkey (open-source Redis fork)
- Analytics: DuckDB (OLAP, data analysis)
- Edge Database: Turso (libSQL/SQLite)
- Backend as a Service: Supabase, PocketBase, Appwrite
- Low-Code Database: Airtable

**DevOps & Cloud**
- Load Balancers & Proxies: Traefik, NGINX
- Containerization: Docker, Kubernetes
- CI/CD: Jenkins, CircleCI, GitHub Actions, GitLab CI
- Infrastructure as Code: Terraform, AWS CloudFormation, Ansible
- Cloud platforms: AWS, Azure, Google Cloud Platform, DigitalOcean
- Edge computing: Cloudflare (Workers, Pages, D1, R2)

**Content Management**
- WordPress: Core development, plugin development, theme development
- Drupal: Module and theme development
- SharePoint: SPFx development, REST API, PnP JS library

**Enterprise Systems**
- SAP: ABAP, SAPUI5/OpenUI5
- Integration: MuleSoft
- CRM: Salesforce Lightning, Zoho

**Security & Compliance**
- Frameworks: NIST, ISO 27001, SOC 2, HIPAA, GDPR
- Application security: OWASP Top 10, OWASP ASVS
- Payment security: PCI DSS

**Testing & Quality**
- E2E testing: Playwright, Cypress
- Performance testing: JMeter
- Code Quality: SonarQube

**System Architecture**
- API design: RESTful APIs, GraphQL, gRPC
- Documentation: OpenAPI/Swagger

**Languages**
- Systems programming: Rust, Go, Zig
- Web development: TypeScript, PHP (PSR standards, Swoole, Laravel Octane)
- Enterprise: Java (Java 8-17+ features, design patterns)

**AI & Machine Learning**
- RAG (Retrieval-Augmented Generation) best practices

**Version Control**
- Git workflows: Git worktrees for parallel development

**Programming Principles**
- SOLID Principles: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- CUPID Principles: Composable, Unix philosophy, Predictable, Idiomatic, Domain-based
- GRASP Patterns: Information Expert, Creator, Controller, Low Coupling, High Cohesion, Polymorphism, Pure Fabrication, Indirection, Protected Variations
- DRY Principle: Don't Repeat Yourself implementation strategies
- DDD: Domain-Driven Design patterns and practices
- Gang of Four Design Patterns: 23 classic object-oriented design patterns

**Project Management & Documentation**
- Diagramming: Mermaid, PlantUML, dbdiagram.io
- Architecture: C4 Model, UML diagrams, ERD tools
- Timing & Sequence: Sequence diagrams, timing diagrams, state machines
- Mind mapping and flowcharts for technical documentation

**Technology Stacks**
- Traditional: LAMP (Linux, Apache, MySQL, PHP)
- JavaScript: MERN (MongoDB, Express, React, Node.js), MEAN (Angular), MEVN (Vue)
- Modern: JAMstack (JavaScript, APIs, Markup), T3 Stack (TypeScript, Next.js, tRPC, Prisma)
- Full-Stack: PERN (PostgreSQL, Express, React, Node.js), Django Stack, Rails Stack
- Laravel: TALL Stack (Tailwind, Alpine.js, Laravel, Livewire), VILT (Vue, Inertia, Laravel, Tailwind)
- Enterprise: .NET Stack, Java Spring Stack

**Code Editors & IDEs**
- Claude Code: Anthropic's official CLI with comprehensive slash commands and AI-powered development
- Neovim: Modern vim with Lua configuration, LSP support, and extensive plugin ecosystem
- Terminal Tools: Tmux (multiplexer), Lazygit (git UI), and modern CLI replacements

**Monitoring & Observability**
- Metrics & Visualization: Prometheus, Grafana
- Log Management: ELK Stack (Elasticsearch, Logstash, Kibana)
- Application Performance Monitoring: Datadog, New Relic
- Error Tracking: Sentry, Rollbar
- Logging and Analytics: Complete monitoring stack implementation

**Security & Secrets Management**
- Secrets Management: HashiCorp Vault
- Certificate Management: Let's Encrypt, cert-manager

**Project Management & Collaboration**
- Project Management: JIRA, ClickUp
- Team Communication: Slack integrations and webhooks
- Documentation: Confluence, Notion

**SEO & Web Optimization**
- Technical SEO: Site architecture, Core Web Vitals, structured data
- Content Optimization: Keyword research, content structure
- Tools & Analytics: Google Search Console, performance monitoring

Each guide includes practical examples, project structures, common pitfalls, performance optimization, and production-ready patterns.

## Maintenance

### Adding New Packages

1. Install the package:
   ```bash
   brew install <package>
   ```

2. Update Brewfile:
   ```bash
   brew bundle dump --force --file=~/dotfiles/Brewfile
   ```

3. Commit changes:
   ```bash
   cd ~/dotfiles
   git add Brewfile
   git commit -m "Add <package> to Brewfile"
   git push
   ```

### Removing Packages

1. Edit the `Brewfile` and remove the package line
2. Run cleanup:
   ```bash
   brew bundle cleanup
   ```

## Backup and Rollback

### Viewing Backups

List all available backups:
```bash
~/dotfiles/scripts/backup.sh list
```

### Manual Backup

Create a backup of current configuration:
```bash
~/dotfiles/scripts/backup.sh
```

### Uninstalling Dotfiles

Complete removal with automatic restoration of original files:
```bash
~/dotfiles/scripts/uninstall.sh
```

This will:
1. Restore your original configuration files from backup
2. Remove all symbolic links
3. Optionally remove the dotfiles repository
4. Optionally clean up backup files

### Quick Restore

Restore configuration without full uninstall:
```bash
~/dotfiles/scripts/uninstall.sh restore
```

## Troubleshooting

### Shell Not Loading Configuration

Ensure the symbolic link is correct:
```bash
ls -la ~/.zshrc
# Should point to ~/dotfiles/.zshrc
```

### Homebrew Issues

Re-run the Homebrew installation:
```bash
~/dotfiles/scripts/install-brew.sh
```

### Permission Issues

Fix permissions on the dotfiles directory:
```bash
chmod -R 755 ~/dotfiles
```

### Backup Recovery

If something goes wrong, backups are stored in:
```bash
~/.dotfiles-backup/
```

View backup manifest:
```bash
cat ~/.dotfiles-backup/manifest.json | jq
```

## Contributing

This is a personal configuration, but feel free to fork and adapt it for your own use. If you find any issues or have suggestions, please open an issue.

## License

MIT - Feel free to use any part of this configuration for your own dotfiles.