# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- Python Development section in README.md with pyenv usage examples

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
