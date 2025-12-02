# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- IT Terms & Jargons Dictionary (`docs/dictionary.md`)
  - Comprehensive glossary with 50+ IT terminology entries
  - Covers foundational concepts, system design, design patterns, and best practices
  - Categories: Frontend, Backend, DevOps, Software Engineering, System Design
  - Alphabetically organized with table of contents for quick navigation
  - Includes related terms cross-references for deeper understanding
  - Ready for continuous expansion by contributors

### Fixed
- Fixed update-all.sh script hanging on password prompts and unresponsive operations
  - Added comprehensive timeout handling for all package manager operations
  - Implemented non-interactive flags for Homebrew casks, Composer, RubyGems, and Oh My Zsh
  - Added `run_with_timeout()` function for safe command execution with fallback support
  - Changed script to continue on errors instead of stopping (removed `-e` flag)
  - Added error tracking with `HAS_ERRORS` flag for better completion reporting
  - Configurable timeout values for each package manager (60s-600s based on operation)
  - Enhanced logging to track and report script completion status

### Added
- Elixir, Phoenix, and Ash development environment setup
  - `elixir/` directory with complete Elixir development configuration
  - `elixir/setup.sh` - Automated Elixir/Phoenix/Ash installation script
  - `elixir/.tool-versions` - Default Erlang/Elixir versions (27.2/1.18.1-otp-27)
  - `elixir/README.md` - Comprehensive Elixir setup documentation
- Elixir setup installs:
  - Erlang 27.2 via asdf with optimized compilation
  - Elixir 1.18.1-otp-27 via asdf
  - Phoenix framework with mix archive
  - Hex package manager and Rebar3 build tool
  - Support for Phoenix and Ash framework development
- asdf version manager to Brewfile for multi-language version management
- Erlang build dependencies to Brewfile:
  - autoconf for configure script building
  - wxwidgets for GUI toolkit (Erlang observer)
  - libxslt for XML transformation
  - fop for documentation formatting
  - unixodbc for database connectivity

### Changed
- Removed standalone `elixir` package from Brewfile (replaced with asdf-managed installation)
- Updated main README.md with Elixir, Phoenix, and Ash Development section
- Enhanced Features list with asdf version manager support
- Updated directory structure documentation to include elixir/ setup

### Removed (Breaking Changes)
- **XAMPP** cask - Legacy Apache/MySQL/PHP package
- **MAMP** cask - Legacy web development solution
- **Opera Air** cask - Simplified browser for everyday browsing
- **python@3.13** - Development version of Python (unstable)
- **python@3.9** - End-of-life Python version (EOL October 2025)

### Changed
- Consolidated Python versions to use pyenv for version management
- Retained python@3.12 (LTS) as system fallback
- Updated README.md with Python Development section showing pyenv usage
- Added migration note for MAMP/XAMPP users to use Laravel Herd or Docker

### Migration Notes
**For MAMP/XAMPP users:**
- Consider using **Laravel Herd** for PHP development (already installed)
- Alternative: Use **Docker Desktop** (already installed) for full-stack environments
- Herd provides better performance and modern PHP version management

**For Python version management:**
- Use `pyenv install <version>` to install specific Python versions
- Use `.python-version` files in projects for automatic version switching
- System Python 3.12 remains available as fallback

### Added
- Python, FastAPI, and Django development environment setup
  - `python/` directory with complete Python development configuration
  - `python/setup.sh` - Automated Python/FastAPI/Django installation script
  - `python/.python-version` - Default Python version (3.12.8)
  - `python/README.md` - Comprehensive Python setup documentation
- Python setup installs:
  - Python 3.12.8 via pyenv
  - FastAPI with uvicorn ASGI server
  - Django with REST framework and common extensions
  - Development tools: black, flake8, mypy, pylint, poetry
  - Testing frameworks: pytest, pytest-asyncio, httpx
- Optional Python/FastAPI/Django setup prompt in `setup.sh` and `scripts/adaptive-setup.sh`
- Ruby and Rails development environment setup
  - `ruby/` directory with complete Ruby/Rails configuration
  - `ruby/setup.sh` - Automated Ruby and Rails installation script
  - `ruby/.ruby-version` - Default Ruby version (3.3.6)
  - `ruby/.gemrc` - Optimized gem configuration
  - `ruby/README.md` - Comprehensive Ruby setup documentation
- Ruby development dependencies to Brewfile:
  - rbenv for Ruby version management
  - ruby-build for installing Ruby versions
  - OpenSSL, readline, libyaml for Ruby compilation
  - Node.js and Yarn for Rails asset pipeline
- Optional Ruby/Rails setup prompt in `setup.sh` and `scripts/adaptive-setup.sh`

### Changed (Previous)
- Updated main README.md with Ruby & Rails Development section
- Enhanced Brewfile with Ruby development tools and dependencies
- Reorganized Ruby-related packages in Brewfile for better clarity
- Removed redundant ruby-install package (replaced by ruby-build)

## [2025-10-04]

### Added
- New workflow-automation category for business process management
- New rust-frameworks category for Rust web and GUI frameworks
- Comprehensive best practices documentation for 5 new technologies:
  - **Camunda** - Workflow and decision automation platform (workflow-automation/camunda.md)
  - **BPMN 2.0** - Business Process Model and Notation standard (workflow-automation/bpmn-2.0.md)
  - **PayloadCMS** - TypeScript-first headless CMS (cms/payloadcms.md)
  - **Axum** - Ergonomic Rust web framework (rust-frameworks/axum.md)
  - **Dioxus** - Cross-platform Rust GUI library (rust-frameworks/dioxus.md)
- Category README files for workflow-automation and rust-frameworks

### Changed
- Updated main README.md to include new technologies and categories
- Enhanced CMS section with PayloadCMS
- Expanded Backend section with Axum Rust framework
- Extended Frontend section with Dioxus Rust GUI framework
- Improved Automation section with workflow orchestration and process modeling tools

## [2025-10-03]

### Added
- Comprehensive best practices documentation for 8 technologies:
  - **RestAssured** - Java REST API testing library (testing/restassured.md)
  - **k6** - Modern load testing tool (testing/k6.md)
  - **Alpine.js** - Lightweight JavaScript framework (frontend/alpinejs.md)
  - **Coolify** - Self-hostable Heroku alternative (devops/coolify.md)
  - **Dokploy** - Open-source PaaS platform (devops/dokploy.md)
  - **PHPStan** - PHP static analysis tool (languages/phpstan.md)
  - **GoHighLevel** - Marketing automation and CRM platform (enterprise/gohighlevel.md)
  - **Zapier** - Workflow automation platform (enterprise/zapier.md)

### Changed
- Updated main README.md to include all new documentation entries
- Enhanced Testing section with API testing and modern load testing tools
- Expanded DevOps section with self-hosted PaaS platforms
- Extended Enterprise Systems section with marketing automation and workflow tools
- Improved Languages section with PHP static analysis coverage

## [2025-10-02]

### Fixed
- Removed deprecated exa package from Brewfile

### Added
- Terminal setup tools to Brewfile
- Tmux plugins configuration
- Humanize persona template

## [Initial Release]

### Added
- Comprehensive best practices documentation structure
- Frontend frameworks and libraries documentation
- Backend frameworks and languages documentation
- Database and ORM documentation
- DevOps and cloud platform guides
- Testing strategies and tools
- System architecture patterns
- Enterprise systems integration guides
- Security frameworks and standards
- Version control workflows
- Programming principles and design patterns
- Project management and documentation tools
