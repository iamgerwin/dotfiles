#!/usr/bin/env bash
# Initialize AI Prompts Structure
# Sets up organized directory structure for AI prompts management

set -e

# Configuration
AI_PROMPTS_DIR="${AI_PROMPTS_DIR:-$HOME/ai-prompts}"
DOTFILES_DIR="$HOME/dotfiles"
CURRENT_PROJECT="${AI_PROMPT_PROJECT:-}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Create directory structure
create_structure() {
    print_header "Creating AI Prompts Structure"
    
    # Main directories
    mkdir -p "$AI_PROMPTS_DIR"
    
    # Template directories
    mkdir -p "$AI_PROMPTS_DIR/templates/clickup"
    mkdir -p "$AI_PROMPTS_DIR/templates/development"
    mkdir -p "$AI_PROMPTS_DIR/templates/documentation"
    mkdir -p "$AI_PROMPTS_DIR/templates/testing"
    mkdir -p "$AI_PROMPTS_DIR/templates/devops"
    mkdir -p "$AI_PROMPTS_DIR/templates/workflows"
    mkdir -p "$AI_PROMPTS_DIR/templates/refactoring"
    mkdir -p "$AI_PROMPTS_DIR/templates/debugging"
    mkdir -p "$AI_PROMPTS_DIR/templates/reviews"
    
    # Projects directory
    mkdir -p "$AI_PROMPTS_DIR/projects/template"
    
    # Scripts directory
    mkdir -p "$AI_PROMPTS_DIR/scripts"
    
    # Secrets directory (gitignored)
    mkdir -p "$AI_PROMPTS_DIR/.secrets"
    
    print_success "Created directory structure"
}

# Create template files
create_templates() {
    print_header "Creating Template Files"
    
    # Project template README
    cat > "$AI_PROMPTS_DIR/projects/template/README.md" << 'EOF'
# [Project Name] Prompts & Context

## Overview
Project-specific prompts, workflows, and context for [Project Name].

## Project Details
- **Framework**: [Laravel/React/Vue/etc]
- **Database**: [PostgreSQL/MySQL/MongoDB]
- **APIs**: [REST/GraphQL]
- **Tools**: [ClickUp/Jira/GitHub]

## Structure
- `context/` - Project-specific context and requirements
- `workflows/` - Development workflows and processes
- `templates/` - Custom templates for this project
- `scripts/` - Project automation scripts

## Quick Access
- ClickUp Workspace: [URL]
- GitHub Repo: [URL]
- Staging: [URL]
- Production: [URL]

## Team Conventions
- Code Style: [PSR-12/Airbnb/etc]
- Git Flow: [feature/develop/main]
- PR Process: [review requirements]
EOF
    
    # ClickUp ticket creation template
    cat > "$AI_PROMPTS_DIR/templates/clickup/create-ticket.md" << 'EOF'
# 🎯 ClickUp Ticket Creation Template

You are a Project Manager creating a ClickUp ticket. Generate a clear and consistent ticket for the following request:

## Task Type
[Select: Bug / Feature / Task / Chore / Documentation / Infrastructure / Refactor]

## Request
[Insert detailed description of what needs to be done]

## Project Context
- **Project**: [Project Name]
- **Repository**: [GitHub URL]
- **Environment**: [Development/Staging/Production]

Available tools:
- ClickUp API: Use environment variable $CLICKUP_API_KEY
- GitHub CLI: gh (authenticated)
- Project scripts: ~/ai-prompts/projects/[project-name]/scripts/

Follow this structure:

### 1. Title
- Short and descriptive (include type prefix, e.g., [Bug], [Feature], [Task])

### 2. Description
- Clear explanation of the task or problem
- If a bug: include expected vs. actual behavior
- If a feature/task: explain the goal and value
- Keep concise but complete

### 3. Context
- Relevant background (related module, client request)
- Links (Figma, repo branch, mockup, reference docs)

### 4. Scope
- ✅ **In Scope**: Items that must be delivered
- ❌ **Out of Scope**: Items intentionally excluded

### 5. Steps to Reproduce (for Bugs only)
- Step-by-step instructions to trigger the issue
- Include environment details (browser, OS, device, version)

### 6. Acceptance Criteria
- List clear, testable conditions that define "done"
- Use checkboxes format:
  - [ ] Criteria 1
  - [ ] Criteria 2
  - [ ] Criteria 3

### 7. Priority & Labels
- **Priority**: P0 (Critical) / P1 (High) / P2 (Medium) / P3 (Low)
- **Labels**: Bug, Enhancement, Documentation, Technical Debt

### 8. Dependencies
- Other tickets, APIs, designs, or blockers
- Link related tickets: #[ticket-id]

### 9. Status Flow
- To Do → In Progress → Code Review → QA → Done
- Webhook triggers if applicable

### 10. Attachments
- Screenshots, error logs, recordings
- Figma links, design assets

### 11. Additional Notes
- Edge cases, constraints, or open questions

---
Format the ticket in Markdown for ClickUp. Keep clarity and developer usability in mind.
EOF
    
    # Laravel Backend Developer Workflow Template
    cat > "$AI_PROMPTS_DIR/templates/workflows/laravel-backend-developer.md" << 'EOF'
# 👨‍💻 Laravel Backend Developer Workflow

## Developer Context
You are a senior full-stack developer working on this ticket. Complete all work as a professional developer would.

## Ticket Information
**Ticket URL**: [Insert ClickUp/Jira ticket URL]
**Project**: [Project Name]
**Branch Base**: develop

## Available Tools
- ClickUp API: Use $CLICKUP_API_KEY environment variable
- GitHub CLI: gh (authenticated)
- Project scripts: ~/ai-prompts/projects/[project]/scripts/
- Postman CLI: Available if needed
- Slack webhook: Use $SLACK_WEBHOOK if configured

## Development Workflow

### Phase 1: Analysis & Planning
1. Retrieve complete ticket details using ClickUp API
2. Review all comments, attachments, and subtasks
3. Check existing API documentation in Postman
4. Review Figma links for design references
5. Create implementation plan:
   - Requirements breakdown
   - Technical approach
   - Task prioritization

### Phase 2: Implementation & Git Workflow
1. Update ticket status to "In Progress"
2. Git workflow:
   ```bash
   # Ensure develop is current
   git checkout develop && git pull origin develop
   
   # Create feature branch
   git checkout -b feature/ticket-[ID]-[short-description]
   
   # After implementation
   git push origin feature/ticket-[ID]-[short-description]
   
   # Create PR to develop
   gh pr create \
     --base develop \
     --title "[TICKET-ID] Brief description" \
     --body "$(cat pr_description.md)"
   ```

3. Implementation guidelines:
   - Small, focused commits
   - Comprehensive error handling
   - Update documentation
   - Create new migrations (don't modify existing)
   - Place docs in `docs/[category]/[filename].md`

4. Update ticket status to "Code Review"

### Phase 3: Documentation & Communication

#### PR Description Template
```markdown
## Summary
Implemented [feature] to address requirements in ticket [ID].

## Changes Made
- [List key changes]
- [Technical decisions]
- [Architecture updates]

## Testing
- [ ] Unit tests added/updated
- [ ] Manual testing completed
- [ ] Edge cases handled

## Deployment Notes
[Any deployment considerations]

## Ticket
[ClickUp ticket link]
```

#### ClickUp Comment Template
```markdown
## Development Complete

**Work Completed:**
- [Detailed feature list]
- [Technical approach]
- [Architecture decisions]

**Code Changes:**
- Branch: feature/ticket-[ID]
- PR: [GitHub PR link]
- Commits: [Number] focused commits

**Technical Details:**
[Summary for stakeholders]

**Status:**
Ready for code review

**Next Steps:**
- Code review
- QA testing
- [Other dependencies]
```

### Commit Message Format
- `feat: implement [feature] with error handling`
- `fix: resolve [issue] in [component]`
- `docs: update API documentation for [endpoint]`
- `refactor: improve [component] performance`
- `test: add unit tests for [feature]`
- `chore: update dependencies`

### Code Standards
- Follow PSR-12 for PHP
- Use type hints and return types
- Document complex logic
- Write self-documenting code
- Include unit tests

### Output Requirements
- Production-ready implementation
- Professional commit messages
- GitHub CLI commands for PR
- Detailed ClickUp comments
- Status updates
- Clear documentation
- Non-technical summary

---
Remember: Write as a senior developer. Focus on business value and technical excellence.
EOF
    
    # Code Review Template
    cat > "$AI_PROMPTS_DIR/templates/reviews/code-review.md" << 'EOF'
# 🔍 Code Review Template

## Review Context
**PR/Branch**: [branch-name or PR link]
**Ticket**: [ClickUp/Jira ticket]
**Type**: [Feature/Bug Fix/Refactor/Performance]

## Review Checklist

### Architecture & Design
- [ ] Follows project architecture patterns
- [ ] Appropriate abstraction levels
- [ ] SOLID principles adherence
- [ ] DRY (Don't Repeat Yourself)
- [ ] KISS (Keep It Simple)

### Code Quality
- [ ] Clear variable/function naming
- [ ] Self-documenting code
- [ ] Appropriate comments for complex logic
- [ ] No code smells
- [ ] Consistent style guide adherence

### Functionality
- [ ] Meets acceptance criteria
- [ ] Edge cases handled
- [ ] Error handling comprehensive
- [ ] Input validation present
- [ ] No breaking changes (or documented)

### Performance
- [ ] No N+1 queries
- [ ] Efficient algorithms used
- [ ] Caching implemented where appropriate
- [ ] Database queries optimized
- [ ] No memory leaks

### Security
- [ ] Input sanitization
- [ ] SQL injection prevention
- [ ] XSS protection
- [ ] CSRF protection
- [ ] Authentication/authorization correct
- [ ] No sensitive data exposed

### Testing
- [ ] Unit tests present and passing
- [ ] Test coverage adequate
- [ ] Integration tests where needed
- [ ] Edge cases tested
- [ ] Mocks used appropriately

### Documentation
- [ ] README updated if needed
- [ ] API documentation current
- [ ] Inline documentation clear
- [ ] CHANGELOG updated
- [ ] Migration guide if breaking changes

## Review Summary

### Strengths
- [What was done well]

### Suggestions
- [Improvements recommended]

### Must Fix
- [Blocking issues]

### Questions
- [Clarifications needed]

## Approval Status
- [ ] Approved
- [ ] Approved with suggestions
- [ ] Needs changes
- [ ] Rejected

---
Remember: Be constructive, specific, and provide examples when suggesting improvements.
EOF
    
    # Bug Debugging Template
    cat > "$AI_PROMPTS_DIR/templates/debugging/bug-investigation.md" << 'EOF'
# 🐛 Bug Investigation Template

## Bug Information
**Ticket**: [ClickUp/Jira link]
**Severity**: [Critical/High/Medium/Low]
**Environment**: [Production/Staging/Development]
**First Reported**: [Date]

## Problem Description
[Clear description of the issue]

## Expected Behavior
[What should happen]

## Actual Behavior
[What is happening]

## Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Investigation Process

### 1. Reproduce the Issue
- [ ] Reproduced locally
- [ ] Reproduced in staging
- [ ] Confirmed in production

### 2. Gather Information
- [ ] Error logs collected
- [ ] Stack traces analyzed
- [ ] Database state checked
- [ ] Network requests inspected
- [ ] Browser console checked

### 3. Root Cause Analysis
- [ ] Recent deployments reviewed
- [ ] Related code changes identified
- [ ] Dependencies checked
- [ ] Configuration verified
- [ ] External services status

### 4. Hypothesis
[Your theory about the cause]

### 5. Solution Approach
[Proposed fix]

### 6. Testing Plan
- [ ] Unit tests for fix
- [ ] Integration tests
- [ ] Manual testing
- [ ] Regression testing

### 7. Prevention
[How to prevent similar issues]

## Fix Implementation
```[language]
// Code fix here
```

## Verification
- [ ] Fix tested locally
- [ ] Tests passing
- [ ] No side effects
- [ ] Performance impact assessed

---
Document findings in ticket comments for future reference.
EOF

    # Refactoring Template
    cat > "$AI_PROMPTS_DIR/templates/refactoring/refactor-plan.md" << 'EOF'
# ♻️ Refactoring Plan Template

## Refactoring Context
**Component/Module**: [Name]
**Current Location**: [File paths]
**Reason**: [Performance/Maintainability/Scalability/Technical Debt]

## Current State Analysis

### Problems
1. [Issue 1]
2. [Issue 2]
3. [Issue 3]

### Code Metrics
- Lines of Code: [Number]
- Cyclomatic Complexity: [Number]
- Test Coverage: [Percentage]
- Dependencies: [Count]

## Refactoring Goals
- [ ] Improve readability
- [ ] Reduce complexity
- [ ] Enhance performance
- [ ] Increase testability
- [ ] Remove duplication
- [ ] Update to modern patterns

## Refactoring Strategy

### Phase 1: Preparation
- [ ] Add tests for current functionality
- [ ] Document current behavior
- [ ] Identify all usages
- [ ] Create backup branch

### Phase 2: Restructuring
- [ ] Extract methods/classes
- [ ] Apply design patterns
- [ ] Simplify conditionals
- [ ] Remove dead code
- [ ] Update naming conventions

### Phase 3: Optimization
- [ ] Performance improvements
- [ ] Memory optimization
- [ ] Query optimization
- [ ] Caching implementation

### Phase 4: Validation
- [ ] All tests passing
- [ ] Performance benchmarks
- [ ] Code review
- [ ] Documentation updated

## Risk Assessment
- **High Risk**: [Areas that could break]
- **Medium Risk**: [Areas needing careful attention]
- **Low Risk**: [Safe changes]

## Rollback Plan
[How to revert if issues arise]

## Success Metrics
- [ ] Reduced complexity by X%
- [ ] Improved performance by X%
- [ ] Increased test coverage to X%
- [ ] Zero regression bugs

---
Track progress with frequent commits and comprehensive testing.
EOF

    # API Endpoint Template
    cat > "$AI_PROMPTS_DIR/templates/development/api-endpoint.md" << 'EOF'
# 🚀 API Endpoint Development Template

## Endpoint Specification
**Method**: [GET/POST/PUT/PATCH/DELETE]
**Path**: `/api/v1/[resource]/[action]`
**Purpose**: [Brief description]

## Request

### Headers
```
Content-Type: application/json
Authorization: Bearer {token}
```

### Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| param1 | string | Yes | Description |
| param2 | integer | No | Description |

### Body (for POST/PUT/PATCH)
```json
{
  "field1": "value",
  "field2": 123,
  "field3": {
    "nested": "object"
  }
}
```

## Response

### Success (200/201)
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "field1": "value",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "meta": {
    "total": 100,
    "page": 1
  }
}
```

### Error (4xx/5xx)
```json
{
  "status": "error",
  "message": "Descriptive error message",
  "errors": {
    "field1": ["Validation error"]
  }
}
```

## Implementation Checklist
- [ ] Route definition
- [ ] Controller method
- [ ] Request validation
- [ ] Business logic
- [ ] Database queries optimized
- [ ] Response formatting
- [ ] Error handling
- [ ] Authentication/authorization
- [ ] Rate limiting
- [ ] Caching strategy
- [ ] API documentation
- [ ] Unit tests
- [ ] Integration tests
- [ ] Postman collection updated

## Security Considerations
- [ ] Input sanitization
- [ ] SQL injection prevention
- [ ] Rate limiting applied
- [ ] Authentication required
- [ ] Authorization checks
- [ ] CORS configured

## Performance
- [ ] Query optimization
- [ ] Eager loading
- [ ] Pagination implemented
- [ ] Caching applied
- [ ] Response time < 200ms

---
Remember to update API documentation and Postman collection.
EOF

    # Database Migration Template
    cat > "$AI_PROMPTS_DIR/templates/development/database-migration.md" << 'EOF'
# 🗄️ Database Migration Template

## Migration Details
**Purpose**: [What this migration does]
**Tables Affected**: [List tables]
**Type**: [Create/Alter/Drop/Index/Data]

## Migration Plan

### Pre-Migration Checklist
- [ ] Backup current database
- [ ] Review existing schema
- [ ] Check foreign key constraints
- [ ] Estimate migration time
- [ ] Plan rollback strategy

### Schema Changes
```sql
-- Up Migration
CREATE TABLE table_name (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    field1 VARCHAR(255) NOT NULL,
    field2 INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_field1 (field1),
    FOREIGN KEY (field2) REFERENCES other_table(id)
);

-- Down Migration
DROP TABLE IF EXISTS table_name;
```

### Data Migration (if needed)
```sql
-- Migrate existing data
INSERT INTO new_table (field1, field2)
SELECT old_field1, old_field2
FROM old_table
WHERE condition;
```

### Laravel Migration File
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('table_name', function (Blueprint $table) {
            $table->id();
            $table->string('field1');
            $table->integer('field2')->default(0);
            $table->timestamps();
            
            $table->index('field1');
            $table->foreign('field2')->references('id')->on('other_table');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('table_name');
    }
};
```

### Testing Plan
- [ ] Test migration up
- [ ] Test migration down
- [ ] Verify data integrity
- [ ] Check indexes created
- [ ] Validate constraints
- [ ] Performance testing

### Deployment Strategy
1. Run on staging first
2. Backup production database
3. Run during low-traffic period
4. Monitor for issues
5. Have rollback ready

### Post-Migration
- [ ] Verify all data migrated
- [ ] Update model relationships
- [ ] Clear caches
- [ ] Update documentation
- [ ] Monitor performance

---
Always test migrations on a copy of production data before deploying.
EOF

    # Testing Strategy Template
    cat > "$AI_PROMPTS_DIR/templates/testing/test-strategy.md" << 'EOF'
# 🧪 Testing Strategy Template

## Feature/Component
**Name**: [Feature/Component name]
**Scope**: [What needs testing]
**Priority**: [Critical/High/Medium/Low]

## Testing Pyramid

### Unit Tests (70%)
Test individual functions/methods in isolation

```php
// PHPUnit Example
public function test_user_can_be_created(): void
{
    $user = User::factory()->create([
        'email' => 'test@example.com'
    ]);
    
    $this->assertDatabaseHas('users', [
        'email' => 'test@example.com'
    ]);
}
```

**Coverage Areas:**
- [ ] Model methods
- [ ] Service classes
- [ ] Utility functions
- [ ] Validators
- [ ] Calculations

### Integration Tests (20%)
Test component interactions

```php
// Laravel Feature Test
public function test_api_endpoint_returns_user(): void
{
    $user = User::factory()->create();
    
    $response = $this->actingAs($user)
        ->getJson('/api/users/' . $user->id);
    
    $response->assertStatus(200)
        ->assertJson(['id' => $user->id]);
}
```

**Coverage Areas:**
- [ ] API endpoints
- [ ] Database interactions
- [ ] External service mocks
- [ ] Authentication flows
- [ ] File operations

### E2E Tests (10%)
Test complete user workflows

```javascript
// Cypress Example
describe('User Registration', () => {
    it('completes registration flow', () => {
        cy.visit('/register');
        cy.get('[name="email"]').type('user@example.com');
        cy.get('[name="password"]').type('password123');
        cy.get('button[type="submit"]').click();
        cy.url().should('include', '/dashboard');
    });
});
```

**Coverage Areas:**
- [ ] Critical user paths
- [ ] Payment flows
- [ ] Multi-step forms
- [ ] Cross-browser testing

## Test Cases

### Positive Tests
1. [Happy path scenario 1]
2. [Happy path scenario 2]

### Negative Tests
1. [Error scenario 1]
2. [Error scenario 2]

### Edge Cases
1. [Boundary condition 1]
2. [Boundary condition 2]

## Test Data Strategy
- [ ] Factories for test data
- [ ] Seeders for consistent state
- [ ] Cleanup after tests
- [ ] Isolated test databases

## Mocking Strategy
- External APIs: [Mock/Stub]
- Payment gateways: [Fake implementation]
- Email services: [In-memory]
- File storage: [Local disk]

## Performance Testing
- [ ] Load testing (expected users)
- [ ] Stress testing (max capacity)
- [ ] Response time benchmarks
- [ ] Database query analysis

## Security Testing
- [ ] SQL injection attempts
- [ ] XSS vulnerability checks
- [ ] Authentication bypass attempts
- [ ] Authorization validation

## Acceptance Criteria
- [ ] All tests passing
- [ ] Code coverage > 80%
- [ ] No performance regressions
- [ ] Security scan clean

---
Run tests before every commit. Maintain high coverage standards.
EOF

    print_success "Created template files"
}

# Create gitignore
create_gitignore() {
    print_header "Setting Up Git Configuration"
    
    cat > "$AI_PROMPTS_DIR/.gitignore" << 'EOF'
# Secrets and sensitive data
.secrets/
*.key
*.token
*.secret
*-secret.*
.env
.env.local
.env.*.local

# Private company data
companies/*/private/
companies/*/.env
companies/*/secrets/

# OS files
.DS_Store
Thumbs.db

# Editor files
*.swp
*.swo
*~
.idea/
.vscode/

# Temporary files
*.tmp
*.temp
*.log

# Backup files
*.backup
*.bak
EOF
    
    print_success "Created .gitignore"
}

# Create secrets template
create_secrets_template() {
    print_header "Creating Secrets Template"
    
    cat > "$AI_PROMPTS_DIR/.secrets/api-keys.env.example" << 'EOF'
# API Keys and Tokens
# Copy this file to api-keys.env and add your actual keys
# NEVER commit the actual api-keys.env file

# OpenAI
OPENAI_API_KEY=sk-...

# Anthropic
ANTHROPIC_API_KEY=sk-ant-...

# GitHub
GITHUB_TOKEN=ghp_...

# ClickUp
# Found in your ClickUp settings > Apps > API Token
CLICKUP_API_KEY=pk_...

# Slack
SLACK_TOKEN=xoxb-...
SLACK_WEBHOOK=https://hooks.slack.com/services/...

# Project Management
JIRA_API_TOKEN=...
LINEAR_API_KEY=lin_api_...
NOTION_TOKEN=secret_...
ASANA_TOKEN=...

# Cloud Providers
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
GOOGLE_APPLICATION_CREDENTIALS=...
AZURE_CLIENT_ID=...

# Monitoring & Analytics
SENTRY_DSN=...
DATADOG_API_KEY=...
NEW_RELIC_LICENSE_KEY=...

# Payment Gateways
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
PAYPAL_CLIENT_ID=...
PAYPAL_SECRET=...

# Email Services
SENDGRID_API_KEY=SG....
MAILGUN_API_KEY=...
POSTMARK_SERVER_TOKEN=...

# SMS Services
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...

# Database URLs (per project)
DATABASE_URL=...
REDIS_URL=...
MONGODB_URI=...

# Project-specific keys (add as needed)
PROJECT_A_API_KEY=...
PROJECT_B_API_KEY=...

# Other services
BUGSNAG_API_KEY=...
ALGOLIA_API_KEY=...
FIREBASE_SERVER_KEY=...
EOF
    
    # Copy to actual file if doesn't exist
    if [[ ! -f "$AI_PROMPTS_DIR/.secrets/api-keys.env" ]]; then
        cp "$AI_PROMPTS_DIR/.secrets/api-keys.env.example" "$AI_PROMPTS_DIR/.secrets/api-keys.env"
        print_info "Created api-keys.env - add your actual keys"
    fi
    
    print_success "Created secrets template"
}

# Create helper scripts
create_helper_scripts() {
    print_header "Creating Helper Scripts"
    
    # Load secrets script
    cat > "$AI_PROMPTS_DIR/scripts/load-secrets.sh" << 'EOF'
#!/usr/bin/env bash
# Load API keys and secrets into environment

SECRETS_FILE="$HOME/ai-prompts/.secrets/api-keys.env"

if [[ -f "$SECRETS_FILE" ]]; then
    export $(grep -v '^#' "$SECRETS_FILE" | xargs)
    echo "✓ Loaded secrets from $SECRETS_FILE"
else
    echo "✗ Secrets file not found: $SECRETS_FILE"
    exit 1
fi
EOF
    chmod +x "$AI_PROMPTS_DIR/scripts/load-secrets.sh"
    
    print_success "Created helper scripts"
}

# Import existing prompts
import_existing() {
    print_header "Importing Existing Prompts"
    
    # Check for existing ai_scripts directories
    local existing_dirs=(
        "$HOME/ai_scripts_shakewell"
        "$HOME/ai_scripts"
    )
    
    for dir in "${existing_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local project_name=$(basename "$dir" | sed 's/ai_scripts_//')
            if [[ "$project_name" == "ai_scripts" ]]; then
                project_name="imported"
            fi
            
            print_info "Found existing prompts: $dir"
            read -p "Import as project '$project_name'? (y/n) " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                mkdir -p "$AI_PROMPTS_DIR/projects/$project_name"
                cp -r "$dir"/* "$AI_PROMPTS_DIR/projects/$project_name/" 2>/dev/null || true
                print_success "Imported to projects/$project_name"
                
                # Create project README
                cat > "$AI_PROMPTS_DIR/projects/$project_name/README.md" << EOF
# $project_name Project

## Overview
Imported project prompts and scripts from $dir

## Quick Access
- Context files: \`context/\`
- Scripts: \`scripts/\`
- Workflows: \`workflows/\`

## Notes
Review and organize imported content as needed.
EOF
                print_info "Created project README"
            fi
        fi
    done
}

# Setup git repository
setup_git() {
    print_header "Setting Up Git Repository"
    
    cd "$AI_PROMPTS_DIR"
    
    if [[ ! -d ".git" ]]; then
        git init
        git add .
        git commit -m "Initial AI prompts structure"
        print_success "Initialized git repository"
    else
        print_info "Git repository already exists"
    fi
}

# Create shell alias
create_alias() {
    print_header "Creating Shell Alias"
    
    # Add to .zshrc.local
    if ! grep -q "alias ai-prompt=" "$HOME/.zshrc.local" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc.local"
        echo "# AI Prompt Management" >> "$HOME/.zshrc.local"
        echo "alias ai-prompt='$DOTFILES_DIR/scripts/ai-prompt'" >> "$HOME/.zshrc.local"
        echo "export AI_PROMPTS_DIR='$AI_PROMPTS_DIR'" >> "$HOME/.zshrc.local"
        print_success "Added ai-prompt alias to ~/.zshrc.local"
        print_info "Run 'source ~/.zshrc' to activate"
    else
        print_info "Alias already exists"
    fi
}

# Main initialization
main() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    AI Prompts Structure Setup          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo
    
    print_info "This will set up AI prompts management at: $AI_PROMPTS_DIR"
    echo
    
    if [[ -d "$AI_PROMPTS_DIR" ]]; then
        print_warning "Directory already exists: $AI_PROMPTS_DIR"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Setup cancelled"
            exit 0
        fi
    fi
    
    create_structure
    create_templates
    create_gitignore
    create_secrets_template
    create_helper_scripts
    import_existing
    setup_git
    create_alias
    
    print_header "Setup Complete!"
    
    print_success "AI prompts structure initialized at: $AI_PROMPTS_DIR"
    echo
    print_info "Next steps:"
    echo "  1. Add your API keys to: $AI_PROMPTS_DIR/.secrets/api-keys.env"
    echo "  2. Import existing prompts: ai-prompt import <path>"
    echo "  3. List available prompts: ai-prompt list"
    echo "  4. Add new prompts: ai-prompt add <category>/<name>.md"
    echo
    print_info "For full documentation, see: $AI_PROMPTS_DIR/README.md"
}

# Run main
main "$@"