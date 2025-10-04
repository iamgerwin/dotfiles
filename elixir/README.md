# Elixir, Phoenix, and Ash Development Setup

Complete guide for setting up Elixir development environment using asdf for version management, targeting Phoenix and Ash framework development.

## Quick Start

```bash
# Run automated setup
cd ~/dotfiles
./elixir/setup.sh

# Verify installation
elixir --version
mix phx.new --version
```

## Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Phoenix Setup](#phoenix-setup)
- [Ash Framework Setup](#ash-framework-setup)
- [Troubleshooting](#troubleshooting)
- [Upgrading](#upgrading)
- [Uninstallation](#uninstallation)

## Prerequisites

### System Requirements

- macOS (10.15 or later)
- Homebrew installed
- Xcode Command Line Tools

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify Homebrew
brew --version
```

### Required Dependencies

All dependencies are installed automatically via `setup.sh`, but you can install them manually:

```bash
cd ~/dotfiles
brew bundle --file=Brewfile
```

The Brewfile includes:
- **asdf** - Version manager for Erlang and Elixir
- **autoconf** - Required for building Erlang
- **wxwidgets** - GUI toolkit for Erlang observer
- **libxslt** - XML transformation library
- **fop** - Print formatter for Erlang documentation
- **unixodbc** - Database connectivity
- **openssl@3** - SSL/TLS toolkit

## Installation

### Automated Installation (Recommended)

The setup script handles everything automatically:

```bash
cd ~/dotfiles
./elixir/setup.sh
```

The script will:
1. Install Homebrew dependencies
2. Set up asdf version manager
3. Install asdf plugins for Erlang and Elixir
4. Install Erlang (this takes 15-30 minutes)
5. Install Elixir
6. Install Hex package manager
7. Install Phoenix framework
8. Configure global versions

### Manual Installation

If you prefer manual installation:

```bash
# Install asdf
brew install asdf

# Add asdf to your shell (already in .zshrc if using this dotfiles repo)
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc

# Restart shell or source
source ~/.zshrc

# Add plugins
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git

# Install Erlang (takes 15-30 minutes)
export KERL_CONFIGURE_OPTIONS="--without-javac --with-ssl=$(brew --prefix openssl@3)"
asdf install erlang 27.2

# Install Elixir
asdf install elixir 1.18.1-otp-27

# Set global versions
asdf global erlang 27.2
asdf global elixir 1.18.1-otp-27

# Install Hex and Phoenix
mix local.hex --force
mix local.rebar --force
mix archive.install hex phx_new --force
```

## Configuration

### Version Management

Versions are managed via `.tool-versions` file:

```bash
# Global versions (in ~/dotfiles/elixir/.tool-versions)
erlang 27.2
elixir 1.18.1-otp-27

# Project-specific versions (create in your project root)
cd ~/my-elixir-project
echo "erlang 27.2" >> .tool-versions
echo "elixir 1.18.1-otp-27" >> .tool-versions
```

When you enter a directory with a `.tool-versions` file, asdf automatically switches to those versions.

### Shell Integration

If using this dotfiles repository, asdf is already configured in `.zshrc`. Otherwise, add:

```bash
# Add to ~/.zshrc
. $(brew --prefix asdf)/libexec/asdf.sh
```

## Usage

### Version Management

```bash
# List installed versions
asdf list erlang
asdf list elixir

# List all available versions
asdf list all erlang
asdf list all elixir

# Install a specific version
asdf install erlang 27.2
asdf install elixir 1.18.1-otp-27

# Set global version (default for all projects)
asdf global erlang 27.2
asdf global elixir 1.18.1-otp-27

# Set local version (project-specific)
cd ~/my-project
asdf local erlang 27.2
asdf local elixir 1.18.1-otp-27

# Check current versions
asdf current
elixir --version
erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell
```

### Elixir Basics

```bash
# Interactive Elixir shell
iex

# Run an Elixir script
elixir script.exs

# Mix (Elixir build tool)
mix help
mix new my_app
mix compile
mix test
mix format
```

## Phoenix Setup

### Creating a New Phoenix Application

```bash
# Full Phoenix application with HTML and assets
mix phx.new myapp
cd myapp
mix deps.get
mix ecto.create
mix phx.server

# Visit http://localhost:4000

# API-only application (no HTML/assets)
mix phx.new myapp_api --no-html --no-assets

# With PostgreSQL database
mix phx.new myapp --database postgres

# With MySQL database
mix phx.new myapp --database mysql
```

### Phoenix Project Structure

```
myapp/
├── _build/          # Compiled artifacts
├── assets/          # Frontend assets (CSS, JS)
├── config/          # Application configuration
├── deps/            # Dependencies
├── lib/
│   ├── myapp/       # Business logic
│   └── myapp_web/   # Web interface (controllers, views, templates)
├── priv/            # Static files and database migrations
├── test/            # Tests
└── mix.exs          # Project configuration and dependencies
```

### Common Phoenix Commands

```bash
# Start server
mix phx.server

# Start server with interactive shell
iex -S mix phx.server

# Generate resources
mix phx.gen.html Accounts User users name:string email:string
mix phx.gen.json Accounts User users name:string email:string
mix phx.gen.context Accounts User users name:string email:string

# Database operations
mix ecto.create         # Create database
mix ecto.migrate        # Run migrations
mix ecto.rollback       # Rollback last migration
mix ecto.reset          # Drop, create, and migrate database
mix ecto.gen.migration  # Generate new migration

# Routes
mix phx.routes

# Assets
cd assets && npm install
```

## Ash Framework Setup

Ash is a declarative, resource-based framework for building robust APIs and applications.

### Adding Ash to an Existing Project

Edit `mix.exs` and add dependencies:

```elixir
defp deps do
  [
    {:ash, "~> 3.4"},
    {:ash_phoenix, "~> 2.0"},
    {:ash_postgres, "~> 2.0"},  # For PostgreSQL
    # or
    {:ash_sqlite, "~> 0.2"},     # For SQLite
  ]
end
```

Install dependencies:

```bash
mix deps.get
```

### Creating Your First Ash Resource

```elixir
# lib/myapp/accounts/user.ex
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "users"
    repo MyApp.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string do
      allow_nil? false
      public? true
    end

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:email, :name]
    end

    update :update do
      accept [:email, :name]
    end
  end
end
```

### Useful Ash Resources

- [Official Documentation](https://ash-hq.org)
- [Ash Phoenix](https://hexdocs.pm/ash_phoenix) - Phoenix integration
- [Ash Authentication](https://hexdocs.pm/ash_authentication) - User authentication
- [Ash GraphQL](https://hexdocs.pm/ash_graphql) - GraphQL API

## Troubleshooting

### asdf Command Not Found

```bash
# Restart your shell or source your config
source ~/.zshrc

# Or manually load asdf
. $(brew --prefix asdf)/libexec/asdf.sh
```

### Erlang Installation Fails

```bash
# Install additional dependencies
brew install autoconf wxwidgets libxslt fop

# Set proper OpenSSL path
export KERL_CONFIGURE_OPTIONS="--without-javac --with-ssl=$(brew --prefix openssl@3)"

# Try installing again
asdf install erlang 27.2
```

### Wrong Elixir Version

```bash
# Check current version
asdf current

# Reshim to refresh PATH
asdf reshim elixir
asdf reshim erlang

# Verify
which elixir  # Should show: ~/.asdf/shims/elixir
elixir --version
```

### Phoenix Mix Archive Issues

```bash
# Reinstall Phoenix archive
mix archive.uninstall phx_new
mix archive.install hex phx_new

# List installed archives
mix archive
```

### Database Connection Issues

```bash
# Ensure PostgreSQL is running (if using Postgres.app)
# Or install via Homebrew:
brew install postgresql@16
brew services start postgresql@16

# Update config/dev.exs with correct credentials
# Default: username: "postgres", password: "postgres"
```

### Port 4000 Already in Use

```bash
# Find process using port 4000
lsof -i :4000

# Kill the process
kill -9 <PID>

# Or use a different port
mix phx.server --port 4001
```

## Upgrading

### Upgrading Erlang/Elixir

```bash
# List latest versions
asdf list all erlang | tail -10
asdf list all elixir | tail -10

# Install new version
asdf install erlang 27.2
asdf install elixir 1.18.1-otp-27

# Update global versions
asdf global erlang 27.2
asdf global elixir 1.18.1-otp-27

# Update .tool-versions file
cd ~/dotfiles/elixir
echo "erlang 27.2" > .tool-versions
echo "elixir 1.18.1-otp-27" >> .tool-versions
```

### Upgrading Phoenix

```bash
# Update Phoenix archive
mix archive.install hex phx_new --force

# For existing projects, update mix.exs
{:phoenix, "~> 1.7"}

# Then update dependencies
mix deps.update phoenix
```

### Upgrading Ash

```bash
# Update mix.exs
{:ash, "~> 3.4"}

# Update dependencies
mix deps.update ash
```

## Uninstallation

### Remove Elixir and Erlang

```bash
# Uninstall specific versions
asdf uninstall erlang 27.2
asdf uninstall elixir 1.18.1-otp-27

# Remove plugins
asdf plugin remove erlang
asdf plugin remove elixir

# Remove asdf entirely
brew uninstall asdf
rm -rf ~/.asdf
```

### Clean Up Project Dependencies

```bash
# In a Phoenix project
mix deps.clean --all
rm -rf _build deps
```

## Additional Resources

### Official Documentation

- [Elixir Official Site](https://elixir-lang.org/)
- [Phoenix Framework](https://www.phoenixframework.org/)
- [Ash Framework](https://ash-hq.org)
- [Hex Package Manager](https://hex.pm/)
- [asdf Version Manager](https://asdf-vm.com/)

### Learning Resources

- [Elixir School](https://elixirschool.com/) - Free Elixir tutorials
- [Exercism Elixir Track](https://exercism.org/tracks/elixir) - Practice exercises
- [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html) - Official Phoenix guides
- [Ash Getting Started](https://ash-hq.org/docs/guides/ash/latest/tutorials/get-started) - Ash tutorials

### Community

- [Elixir Forum](https://elixirforum.com/)
- [Elixir Slack](https://elixir-slackin.herokuapp.com/)
- [Phoenix Forum](https://elixirforum.com/c/phoenix-forum)
- [Ash Discord](https://discord.gg/ash)

## Best Practices

### Project Setup

1. Always use `.tool-versions` for version pinning
2. Use `mix format` before committing code
3. Run `mix test` regularly
4. Keep dependencies updated with `mix hex.outdated`

### Development Workflow

```bash
# Start a new feature
git checkout -b feature/my-feature

# Development cycle
mix test --stale    # Run only affected tests
mix format          # Format code
iex -S mix          # Interactive development

# Before committing
mix test            # Run full test suite
mix credo           # Code analysis (if installed)
mix format --check-formatted  # Verify formatting
```

### Performance Tips

1. Use `mix profile.fprof` for profiling
2. Enable database query logging in development
3. Use `mix phx.gen.release` for production releases
4. Consider using LiveView for real-time features

### Security

1. Keep Erlang and Elixir updated
2. Run `mix deps.audit` to check for vulnerabilities
3. Use environment variables for secrets
4. Enable HTTPS in production
5. Configure CORS properly for APIs

## Version Information

- **Erlang/OTP**: 27.2
- **Elixir**: 1.18.1-otp-27
- **Phoenix**: Latest (installed via mix archive)
- **Ash**: 3.4+ (project dependency)

Last updated: 2025-10-05
