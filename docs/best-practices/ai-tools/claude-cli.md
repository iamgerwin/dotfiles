# Claude CLI (Anthropic) Best Practices

## Overview

Claude CLI is Anthropic's command-line interface for interacting with Claude AI models. Known for its strong reasoning capabilities, safety features, and extended context windows, Claude excels at code analysis, documentation, and thoughtful technical decision-making.

## Installation

### Homebrew Installation (Recommended)

```bash
# Install Claude CLI (when available)
brew install claude-cli

# Verify installation
claude --version
```

### Alternative Installation Methods

```bash
# Via npm
npm install -g @anthropic-ai/claude-cli

# Via pip
pip install anthropic-cli

# Via official installer
curl -fsSL https://anthropic.com/install-cli.sh | sh
```

## Configuration

### API Key Setup

1. **Get Your API Key**
   - Visit [Anthropic Console](https://console.anthropic.com/)
   - Navigate to API Keys
   - Create a new API key
   - Copy and store securely

2. **Set Environment Variable**

Add to your `.zshrc.local` or `.bashrc`:

```bash
# Claude API Configuration
export ANTHROPIC_API_KEY="your-api-key-here"
export CLAUDE_API_KEY="your-api-key-here"  # Alternative naming
```

3. **Initialize CLI**

```bash
# Initialize configuration
claude init

# Authenticate
claude auth login

# Set defaults
claude config set model claude-3-sonnet
claude config set max_tokens 4096
claude config set temperature 0.2
```

### Configuration File

Create `~/.config/claude/config.yaml`:

```yaml
api:
  key: ${ANTHROPIC_API_KEY}
  endpoint: https://api.anthropic.com
  version: 2023-06-01

models:
  default: claude-3-sonnet-20240229
  fast: claude-3-haiku-20240307
  powerful: claude-3-opus-20240229

generation:
  temperature: 0.2
  max_tokens: 4096
  top_p: 0.9
  top_k: 250

safety:
  content_filter: true
  pii_detection: true

output:
  format: markdown
  streaming: true
  color: true
```

## Usage Patterns

### Basic Code Generation

```bash
# Generate code
claude generate "Create a Python function for binary search"

# With specific model
claude generate --model claude-3-opus \
  "Implement a concurrent web scraper in Python"

# With context
claude generate --context "FastAPI application" \
  "Create an authentication middleware with JWT"
```

### Interactive Mode

```bash
# Start interactive session
claude chat

# With system prompt
claude chat --system "You are a senior software architect"

# With extended context
claude chat --max-tokens 100000  # Claude supports long contexts
```

### Code Analysis

```bash
# Analyze code quality
claude analyze path/to/code.py

# Deep code review
claude review --depth comprehensive path/to/file.py

# Architecture analysis
claude analyze-architecture src/
```

### Code Refactoring

```bash
# Refactor for readability
claude refactor --focus readability path/to/legacy.py

# Modernize code
claude refactor --modernize --language python3.12 old_code.py

# Extract patterns
claude refactor --extract-patterns path/to/file.py
```

### Documentation Generation

```bash
# Generate comprehensive docs
claude document path/to/module/

# API documentation
claude document --format openapi path/to/api/

# Architecture documentation
claude document --architecture --output docs/ src/
```

## Advanced Features

### Extended Context Windows

Claude excels at processing large documents:

```bash
# Analyze entire codebase
find src/ -name "*.py" -exec cat {} \; | \
  claude analyze --context full-codebase

# Process large documents
claude process --max-tokens 200000 large_document.md

# Cross-file analysis
claude analyze-dependencies src/ --include-all-files
```

### Thoughtful Reasoning

```bash
# Step-by-step problem solving
claude solve --show-reasoning \
  "How should I architect a distributed caching system?"

# Compare approaches
claude compare "microservices vs monolith for our use case" \
  --context "E-commerce platform with 10M users"

# Design reviews
claude review-design architecture-doc.md \
  --perspective security,scalability,maintainability
```

### Safety and Ethics

```bash
# Security audit
claude audit-security codebase/

# Privacy compliance check
claude check-compliance --standard GDPR data-handling.py

# Bias detection
claude analyze-bias ml-model.py --dataset training-data.csv
```

## Integration with Other Tools

### Git Workflow Integration

```bash
# Intelligent commit messages
git --no-pager diff | claude commit-message --conventional

# PR reviews with reasoning
git --no-pager diff main...feature | \
  claude review-pr --explain-reasoning

# Refactoring suggestions
git --no-pager log --since="1 month ago" --format="%H %s" | \
  claude suggest-refactoring
```

### CI/CD Integration

```yaml
# .github/workflows/claude-review.yml
name: Claude Code Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0
      
      - name: Install Claude CLI
        run: npm install -g @anthropic-ai/claude-cli
      
      - name: Comprehensive Review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          git diff origin/main...HEAD | \
            claude review \
              --checklist security,performance,maintainability \
              --explain --output review-report.md
      
      - name: Post Review Comment
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const review = fs.readFileSync('review-report.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: review
            });
```

### Testing Integration

```bash
# Generate comprehensive tests
claude generate-tests --coverage 95 src/module.py

# Generate edge cases
claude generate-tests --focus edge-cases --fuzz src/parser.py

# Test review and improvement
claude improve-tests tests/ --suggest-additional
```

## Co-Existence with Other AI CLIs

### Tool-Specific Aliases

Add to your `.zshrc` or `.zshrc.local`:

```bash
# Claude-specific aliases
alias cl="claude"
alias clgen="claude generate"
alias clchat="claude chat"
alias clrev="claude review"
alias cldoc="claude document"
alias clref="claude refactor"

# Keep other AI CLIs separate
alias gm="gemini"       # Google Gemini
alias cx="codex"        # OpenAI Codex

# Use Claude for analysis (its strength)
alias ai-analyze="claude analyze"
alias ai-review="claude review"
```

### Strategic Tool Selection

```bash
# Use each tool for its strengths
ai_smart() {
  case $1 in
    # Claude for analysis and review
    analyze|review|audit) 
      claude "${@:2}"
      ;;
    # Gemini for quick generation
    generate|quick)
      gemini "${@:2}"
      ;;
    # Codex for production code
    production|deploy)
      codex "${@:2}"
      ;;
    *)
      echo "Usage: ai_smart {analyze|review|generate|quick|production} [args]"
      ;;
  esac
}

# Ensemble approach - get multiple perspectives
ai_ensemble() {
  local prompt="$1"
  echo "=== Claude's Perspective ==="
  claude analyze "$prompt"
  echo "\n=== Gemini's Perspective ==="
  gemini analyze "$prompt"
  echo "\n=== Codex's Perspective ==="
  codex analyze "$prompt"
}
```

### Workflow Orchestration

```bash
# Multi-stage development workflow
develop_feature() {
  local feature="$1"
  
  # 1. Claude: Architectural design
  echo "📐 Designing architecture..."
  claude design "$feature" > design.md
  
  # 2. Gemini: Initial implementation
  echo "🔨 Generating code..."
  gemini generate --from-design design.md > implementation.py
  
  # 3. Claude: Code review
  echo "🔍 Reviewing code..."
  claude review implementation.py > review.md
  
  # 4. Codex: Production refinement
  echo "✨ Refining for production..."
  codex refine --production implementation.py > final.py
  
  echo "✅ Feature development complete!"
}
```

## Security Best Practices

### API Key Management

```bash
# Secure key storage
export ANTHROPIC_API_KEY=$(security find-generic-password \
  -a anthropic-api -s claude-cli -w)

# Key rotation
claude auth rotate-key

# Usage monitoring
claude usage --detailed --alert-threshold 80%
```

### Sensitive Data Handling

```bash
# Pre-process prompts to remove sensitive data
claude_secure() {
  local prompt="$1"
  
  # Sanitize sensitive patterns
  prompt=$(echo "$prompt" | \
    sed -E 's/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/EMAIL_REDACTED/g' | \
    sed -E 's/\b[0-9]{3}-[0-9]{2}-[0-9]{4}\b/SSN_REDACTED/g' | \
    sed -E 's/(api[_-]?key|password|secret)[[:space:]]*[:=][[:space:]]*[^[:space:]]*/\1=REDACTED/gi')
  
  claude "$prompt"
}
```

### Output Validation

```bash
# Validate and review generated code
claude_validate() {
  local output_file="$1"
  
  # Run security checks
  echo "🔒 Running security scan..."
  bandit "$output_file"
  
  # Check code quality
  echo "📊 Checking code quality..."
  pylint "$output_file"
  
  # Run tests if available
  if [[ -f "test_${output_file}" ]]; then
    echo "🧪 Running tests..."
    pytest "test_${output_file}"
  fi
}
```

## Performance Optimization

### Caching Strategies

```bash
# Enable intelligent caching
claude config set cache.strategy smart
claude config set cache.ttl 7200

# Cache common patterns
claude cache warm --patterns "code review,refactoring,tests"

# Clear cache selectively
claude cache clear --older-than 7d
```

### Context Management

```bash
# Optimize context usage for long documents
claude analyze --context-strategy sliding-window large-file.py

# Progressive context building
claude chat --context-memory true  # Remembers conversation context
```

## Troubleshooting

### Common Issues

**Installation Problems**
```bash
# Check system requirements
claude doctor

# Reinstall if corrupted
npm uninstall -g @anthropic-ai/claude-cli
npm install -g @anthropic-ai/claude-cli

# Verify installation
which claude
claude --version
```

**Authentication Issues**
```bash
# Re-authenticate
claude auth logout
claude auth login

# Verify API key
claude auth test

# Check API status
curl -H "x-api-key: $ANTHROPIC_API_KEY" \
  https://api.anthropic.com/v1/messages
```

**Rate Limiting**
```bash
# Check rate limits
claude limits

# Implement exponential backoff
claude generate "$prompt" --retry-strategy exponential

# Use slower model for non-critical tasks
claude generate --model claude-3-haiku "$prompt"
```

## Best Practices Summary

- [ ] Use Claude for complex analysis and reasoning tasks
- [ ] Leverage extended context windows for large codebases
- [ ] Enable safety features for production use
- [ ] Implement proper API key rotation
- [ ] Use appropriate models (Opus for complex, Haiku for simple)
- [ ] Cache frequently used prompts and patterns
- [ ] Validate all generated code before deployment
- [ ] Monitor API usage and costs
- [ ] Use tool-specific aliases for co-existence
- [ ] Implement thoughtful code review workflows
- [ ] Document AI-assisted development decisions
- [ ] Combine with other tools strategically

## Comparison with Other AI CLIs

| Feature | Claude CLI | Gemini CLI | Codex CLI |
|---------|-----------|------------|-----------|
| **Context Window** | Up to 200K tokens | Up to 1M tokens | Up to 128K tokens |
| **Strengths** | Reasoning, Safety, Analysis | Multi-modal, Speed | Code accuracy |
| **Best For** | Reviews, Docs, Architecture | Quick tasks, Vision | Production code |
| **Safety Features** | Excellent | Good | Moderate |
| **Cost** | Subscription/API | Free tier available | Pay per token |
| **Streaming** | Yes | Yes | Yes |

## Related Documentation

- [AI Agent CLI Tools](../../../AGENTS.md) - General best practices
- [Gemini CLI Guide](gemini-cli.md) - Google Gemini specifics
- [Codex CLI Guide](codex-cli.md) - OpenAI Codex specifics
- [Main README](../../../README.md) - Dotfiles documentation

## Additional Resources

- [Anthropic Console](https://console.anthropic.com/)
- [Claude API Documentation](https://docs.anthropic.com/)
- [API Pricing](https://www.anthropic.com/pricing)
- [Safety Guidelines](https://www.anthropic.com/safety)
- [Model Cards](https://www.anthropic.com/claude)
- [Rate Limits](https://docs.anthropic.com/claude/reference/rate-limits)
