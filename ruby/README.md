# Ruby and Rails Development Setup

Complete guide for setting up Ruby and Rails development environment using rbenv for version management.

## Quick Start

```bash
# Run automated setup
cd ~/dotfiles
./ruby/setup.sh

# Verify installation
ruby -v
rails -v
```

## Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Project Setup](#project-setup)
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

Dependencies include:
- **rbenv** - Ruby version manager
- **ruby-build** - rbenv plugin for installing Ruby versions
- **openssl@3** - SSL/TLS toolkit
- **readline** - Command-line editing library
- **libyaml** - YAML parser
- **gmp** - Multiple precision arithmetic library
- **node** - JavaScript runtime (for Rails asset pipeline)
- **yarn** - JavaScript package manager

## Installation

### Automated Installation (Recommended)

```bash
cd ~/dotfiles
./ruby/setup.sh
```

The setup script will:
1. Install all required dependencies via Homebrew
2. Configure rbenv in your shell
3. Install Ruby 3.3.6 (latest stable LTS)
4. Install Bundler gem manager
5. Install latest stable Rails version
6. Configure gem settings (.gemrc)

### Manual Installation

If you prefer manual installation:

```bash
# 1. Install rbenv and ruby-build
brew install rbenv ruby-build

# 2. Initialize rbenv in your shell
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc

# 3. Install Ruby
RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3) --with-readline-dir=$(brew --prefix readline) --with-libyaml-dir=$(brew --prefix libyaml)" rbenv install 3.3.6

# 4. Set global Ruby version
rbenv global 3.3.6
rbenv rehash

# 5. Install Bundler and Rails
gem install bundler rails
rbenv rehash
```

## Configuration

### Shell Integration

rbenv initialization is automatically added to `.zshrc` during setup:

```bash
# rbenv initialization
eval "$(rbenv init - zsh)"
```

If using a different shell (bash):

```bash
echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
source ~/.bashrc
```

### Gem Configuration (.gemrc)

The `.gemrc` file is automatically copied to `~/.gemrc` and optimizes gem installation:

```yaml
---
# Skip documentation generation (faster installs)
gem: --no-document
install: --no-document
update: --no-document

# SSL verification
:ssl_verify_mode: 1

# Concurrent downloads (faster)
:concurrent_downloads: 8
```

### Ruby Version

The default Ruby version is specified in `.ruby-version`:

```
3.3.6
```

This file ensures consistent Ruby versions across your development environment.

## Usage

### rbenv Commands

```bash
# List available Ruby versions
rbenv install --list

# Install a specific Ruby version
rbenv install 3.2.0

# List installed versions
rbenv versions

# Set global Ruby version
rbenv global 3.3.6

# Set local (project-specific) Ruby version
rbenv local 3.2.0

# Display current Ruby version
rbenv version

# Rehash after installing gems with executables
rbenv rehash
```

### Gem Management

```bash
# Update RubyGems system
gem update --system

# Install a gem
gem install gem_name

# Install gem without documentation (faster)
gem install gem_name --no-document

# List installed gems
gem list

# Uninstall a gem
gem uninstall gem_name

# Clean up old gem versions
gem cleanup
```

### Bundler

```bash
# Install project dependencies
bundle install

# Update dependencies
bundle update

# Execute command in bundle context
bundle exec rails server

# Create Gemfile
bundle init
```

## Project Setup

### Creating a New Rails Application

```bash
# Create new Rails app
rails new myapp

# Create Rails app with PostgreSQL
rails new myapp --database=postgresql

# Create API-only Rails app
rails new myapp --api

# Create Rails app with specific Ruby version
echo "3.3.6" > myapp/.ruby-version
cd myapp
bundle install
```

### Using Project-Specific Ruby Versions

```bash
# Navigate to project directory
cd ~/projects/myapp

# Set project-specific Ruby version
echo "3.2.0" > .ruby-version

# Install Ruby version if needed
rbenv install 3.2.0

# Re-enter directory to activate version
cd .

# Verify active version
ruby -v
```

### Sample Gemfile

```ruby
source 'https://rubygems.org'

ruby '3.3.6'

gem 'rails', '~> 7.2'
gem 'pg', '~> 1.5'
gem 'puma', '~> 6.0'

group :development, :test do
  gem 'debug'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end

group :development do
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
end
```

## Troubleshooting

### Rails Command Not Found

```bash
# Solution: Rehash rbenv shims
rbenv rehash

# Verify rails is in PATH
which rails  # Should show: ~/.rbenv/shims/rails
```

### Wrong Ruby Version Active

```bash
# Check current version
rbenv version

# Check .ruby-version file
cat .ruby-version

# Ensure rbenv is initialized
eval "$(rbenv init - zsh)"

# Re-enter directory
cd .
```

### Gem Installation Fails

```bash
# Update RubyGems
gem update --system

# Clear gem cache
gem cleanup

# Reinstall Ruby with proper build options
RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)" rbenv install 3.3.6 --force
```

### SSL Certificate Errors

```bash
# Update SSL certificates
brew upgrade openssl@3

# Reinstall Ruby with updated OpenSSL
RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)" rbenv install 3.3.6 --force
```

### Permission Errors

```bash
# Never use sudo with gem install
# If you get permission errors, rbenv is not properly configured

# Fix: Ensure rbenv is in PATH
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc

# Verify correct Ruby path
which ruby  # Should show: ~/.rbenv/shims/ruby
```

### Bundle Install Fails

```bash
# Update Bundler
gem update bundler

# Install with verbose output
bundle install --verbose

# Clean bundle cache
bundle clean --force
```

## Upgrading

### Upgrading Ruby

```bash
# List available versions
rbenv install --list

# Install new version
rbenv install 3.3.7

# Set as global version
rbenv global 3.3.7
rbenv rehash

# Update project .ruby-version
echo "3.3.7" > ~/dotfiles/ruby/.ruby-version
```

### Upgrading Rails

```bash
# Update Rails globally
gem update rails
rbenv rehash

# Verify new version
rails -v

# Update Rails in existing project
# Edit Gemfile and change Rails version
bundle update rails
```

### Upgrading Gems

```bash
# Update all gems
gem update

# Update RubyGems system
gem update --system

# Rehash after updates
rbenv rehash
```

## Uninstallation

### Remove Ruby Version

```bash
# Uninstall specific Ruby version
rbenv uninstall 3.2.0

# List installed versions
rbenv versions
```

### Complete Removal

```bash
# Remove all Ruby versions
rm -rf ~/.rbenv

# Remove from shell configuration
# Edit ~/.zshrc and remove: eval "$(rbenv init - zsh)"

# Remove Homebrew packages
brew uninstall rbenv ruby-build
```

## Verification

### Health Check Commands

```bash
# Verify rbenv installation
rbenv --version

# Verify Ruby installation
ruby -v

# Check Ruby path (should be rbenv shim)
which ruby

# Verify Rails
rails -v

# Verify Bundler
bundle -v

# Check gem environment
gem env

# Test Rails new project
rails new test_app --skip-bundle
cd test_app
bundle install
rails server
```

### Expected Output

```bash
$ ruby -v
ruby 3.3.6 (2024-11-05 revision 75015d4c1f) [arm64-darwin25]

$ which ruby
/Users/username/.rbenv/shims/ruby

$ rails -v
Rails 7.2.2

$ gem env home
/Users/username/.rbenv/versions/3.3.6/lib/ruby/gems/3.3.0
```

## Best Practices

### Version Management

- Use `.ruby-version` in all projects for consistency
- Keep global Ruby version updated to latest stable
- Test applications against multiple Ruby versions before upgrading

### Gem Management

- Always use `Gemfile` and `Gemfile.lock` in projects
- Commit `Gemfile.lock` to version control
- Run `bundle update` cautiously in production apps
- Use pessimistic version constraints (`~>`) in Gemfile

### Performance

- Skip documentation generation (already configured in .gemrc)
- Use `bundle install --jobs=4` for parallel gem installation
- Clean old gem versions periodically with `gem cleanup`

### Security

- Keep Ruby and Rails updated for security patches
- Run `bundle audit` to check for vulnerable dependencies
- Use Brakeman for Rails security scanning
- Review `Gemfile.lock` changes in pull requests

## Additional Resources

- **Ruby Official Site**: https://www.ruby-lang.org
- **Rails Guides**: https://guides.rubyonrails.org
- **rbenv Documentation**: https://github.com/rbenv/rbenv
- **RubyGems**: https://rubygems.org
- **Bundler**: https://bundler.io

## Support

If you encounter issues not covered in this guide:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review rbenv documentation: https://github.com/rbenv/rbenv
3. Search Rails issues: https://github.com/rails/rails/issues
4. Check Ruby version compatibility: https://www.ruby-lang.org/en/downloads/

---

**Maintained by**: Dotfiles Repository
**Last Updated**: 2025-10-04
**Ruby Version**: 3.3.6
**Rails Version**: 7.2.x
