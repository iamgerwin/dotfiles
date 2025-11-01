# Gemini CLI (Google) Best Practices

## Overview

Gemini CLI is Google's command-line interface for interacting with their Gemini AI models. It provides developers with powerful code generation, explanation, and debugging capabilities directly from the terminal, leveraging Google's latest generative AI technology.

## Installation

### Homebrew Installation (Recommended)

```bash
# Install Gemini CLI
brew install gemini-cli

# Verify installation
gemini --version
```

### Manual Installation

```bash
# Download from Google AI Studio
# Visit: https://ai.google.dev/

# Or use npm/pip if available
npm install -g @google/gemini-cli
# or
pip install google-generativeai
```

## Configuration

### API Key Setup

1. **Get Your API Key**
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create a new API key
   - Copy the key securely

2. **Set Environment Variable**

Add to your `.zshrc.local` or `.bashrc`:

```bash
# Gemini API Configuration
export GEMINI_API_KEY="your-api-key-here"
```

3. **Configure CLI**

```bash
# Initialize configuration
gemini config init

# Set API key
gemini config set api_key $GEMINI_API_KEY

# Set default model
gemini config set model gemini-pro

# Configure output preferences
gemini config set output_format code
gemini config set temperature 0.2
```

### Configuration File

Create `~/.config/gemini-cli/config.yaml`:

```yaml
api:
  key: ${GEMINI_API_KEY}
  endpoint: https://generativelanguage.googleapis.com
  
models:
  default: gemini-pro
  code: gemini-pro
  vision: gemini-pro-vision
  
generation:
  temperature: 0.2
  top_p: 0.8
  top_k: 40
  max_output_tokens: 2048
  
safety:
  threshold: BLOCK_MEDIUM_AND_ABOVE
  
output:
  format: markdown
  syntax_highlighting: true
  stream: true
```

## Usage Patterns

### Basic Code Generation

```bash
# Generate a function
gemini generate "Create a Python function to validate email addresses"

# With language specification
gemini generate --language javascript \
  "Create an async function to fetch user data from an API"

# With context
gemini generate --context "React TypeScript component" \
  "Create a form with validation and error handling"
```

### Interactive Mode

```bash
# Start interactive session
gemini chat

# With specific model
gemini chat --model gemini-pro

# With system prompt
gemini chat --system "You are a senior Python developer"
```

### Code Explanation

```bash
# Explain code from file
gemini explain path/to/file.py

# Explain code from stdin
cat script.py | gemini explain

# With detailed analysis
gemini explain --verbose --include-complexity path/to/file.py
```

### Code Optimization

```bash
# Optimize code
gemini optimize path/to/slow_function.py

# With specific focus
gemini optimize --focus performance path/to/file.py
gemini optimize --focus readability path/to/file.py
```

### Bug Detection

```bash
# Analyze for bugs
gemini debug path/to/buggy_code.py

# With test cases
gemini debug --with-tests path/to/file.py

# Interactive debugging
gemini debug --interactive path/to/file.py
```

## Advanced Features

### Multi-Modal Capabilities

Gemini Pro Vision supports image inputs:

```bash
# Analyze code screenshot
gemini analyze-image screenshot.png \
  --prompt "Explain this code and find potential issues"

# Generate code from diagram
gemini generate-from-image architecture-diagram.png \
  --prompt "Generate Python code implementing this architecture"
```

### Batch Processing

```bash
# Process multiple files
gemini batch generate \
  --input prompts.txt \
  --output generated/ \
  --language python

# Generate tests for all files
find src/ -name "*.py" | xargs -I {} \
  gemini generate "Create unit tests for {}"
```

### Custom Templates

Create reusable prompts:

```bash
# Save template
gemini template save api-endpoint \
  "Create a RESTful API endpoint with:
   - Route: {route}
   - Method: {method}
   - Request validation
   - Error handling
   - Documentation"

# Use template
gemini template use api-endpoint \
  --route /users --method POST
```

## Integration with Other Tools

### Git Workflow

```bash
# Generate commit messages
git diff | gemini generate "Create a conventional commit message"

# Code review assistant
git diff main...feature | gemini review \
  --checklist security,performance,style

# Generate PR description
git log main..feature --oneline | \
  gemini generate "Create a detailed PR description"
```

### CI/CD Integration

```yaml
# .github/workflows/ai-code-review.yml
name: AI Code Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Gemini CLI
        run: brew install gemini-cli
      - name: Review Code
        env:
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
        run: |
          git diff origin/main...HEAD | \
            gemini review --format github-comment > review.md
```

### Editor Integration

```bash
# Neovim integration
# Add to ~/.config/nvim/init.lua
vim.keymap.set('n', '<leader>ae', function()
  vim.cmd('!gemini explain %')
end)

# VSCode integration
# Use Gemini CLI extension or terminal integration
```

## Co-Existence with Other AI CLIs

### Tool-Specific Aliases

Add to your `.zshrc` or `.zshrc.local`:

```bash
# Gemini-specific aliases
alias gm="gemini"
alias gmgen="gemini generate"
alias gmchat="gemini chat"
alias gmexp="gemini explain"
alias gmdbg="gemini debug"
alias gmopt="gemini optimize"

# Keep other AI CLIs separate
alias cx="codex"      # OpenAI Codex
alias cl="claude"     # Anthropic Claude

# Generic AI alias (defaults to Gemini)
alias ai="gemini"
```

### Context Switching

```bash
# Use different models for different tasks
export AI_CODE_GENERATOR="gemini"      # For code generation
export AI_CODE_REVIEWER="claude"       # For code review
export AI_DOCS_WRITER="codex"          # For documentation

# Create wrapper function
ai_task() {
  case $1 in
    generate) gemini generate "${@:2}" ;;
    review) claude review "${@:2}" ;;
    docs) codex document "${@:2}" ;;
    *) gemini "$@" ;;
  esac
}
```

## Security Best Practices

### API Key Management

```bash
# Use environment variables (never hardcode)
export GEMINI_API_KEY=$(security find-generic-password \
  -a gemini-api-key -s gemini-cli -w)

# Rotate keys regularly
gemini config rotate-key

# Monitor usage
gemini usage --show-details
```

### Sensitive Data Protection

```bash
# Sanitize prompts before sending
gemini_safe() {
  local prompt="$1"
  # Remove sensitive patterns
  prompt=$(echo "$prompt" | sed 's/api[_-]key=[^ ]*/api_key=REDACTED/g')
  prompt=$(echo "$prompt" | sed 's/password=[^ ]*/password=REDACTED/g')
  gemini generate "$prompt"
}
```

### Output Validation

```bash
# Always review generated code
gemini generate "$prompt" > generated.py
python -m py_compile generated.py  # Check syntax
bandit generated.py                 # Security scan
pylint generated.py                 # Style check
```

## Performance Optimization

### Caching

```bash
# Enable response caching
gemini config set cache.enabled true
gemini config set cache.ttl 3600

# Clear cache when needed
gemini cache clear
```

### Rate Limiting

```bash
# Set request limits
export GEMINI_MAX_REQUESTS_PER_MINUTE=60
export GEMINI_MAX_TOKENS_PER_DAY=100000

# Monitor usage
gemini usage --check-limits
```

## Troubleshooting

### Common Issues

**Installation Issues**
```bash
# If Homebrew install fails
brew update
brew upgrade
brew install gemini-cli

# Check for conflicting packages
brew list | grep gemini
```

**API Key Not Found**
```bash
# Verify environment variable
echo $GEMINI_API_KEY

# Test API key validity
gemini auth test

# Re-authenticate
gemini auth login
```

**Rate Limit Errors**
```bash
# Check current usage
gemini usage

# Wait and retry with exponential backoff
for i in {1..5}; do
  gemini generate "$prompt" && break || sleep $((2**i))
done
```

**Response Quality Issues**
```bash
# Adjust temperature (lower = more deterministic)
gemini generate --temperature 0.1 "$prompt"

# Use more specific prompts
gemini generate --verbose --context "detailed context" "$prompt"

# Try different models
gemini generate --model gemini-pro-latest "$prompt"
```

## Cost Management

### Token Usage Tracking

```bash
# Check token usage
gemini usage --detailed

# Set budget alerts
gemini config set budget.daily_limit 100000
gemini config set budget.alert_threshold 0.8

# Export usage reports
gemini usage export --format csv --output usage-report.csv
```

### Optimization Strategies

```bash
# Use shorter prompts
gemini generate --concise "$prompt"

# Batch similar requests
gemini batch --optimize-tokens requests.txt

# Use caching for repeated queries
gemini config set smart_cache true
```

## Best Practices Summary

- [ ] Store API keys in secure environment variables
- [ ] Use specific, detailed prompts for better results
- [ ] Always review and test generated code
- [ ] Enable caching for frequently used prompts
- [ ] Monitor API usage and costs
- [ ] Use tool-specific aliases for co-existence
- [ ] Implement rate limiting and error handling
- [ ] Sanitize prompts to remove sensitive data
- [ ] Validate outputs with automated tools
- [ ] Document AI-assisted code sections
- [ ] Keep CLI tools updated
- [ ] Use appropriate models for different tasks
- [ ] Implement backup strategies for critical workflows

## Comparison with Other AI CLIs

| Feature | Gemini CLI | Codex CLI | Claude CLI |
|---------|-----------|-----------|------------|
| **Provider** | Google | OpenAI | Anthropic |
| **Strengths** | Multi-modal, Fast, Free tier | Proven accuracy | Safety, Context length |
| **Best For** | Vision tasks, Quick iterations | Production code | Long documents, Analysis |
| **Cost** | Free tier available | Pay per token | Subscription based |
| **Context Window** | Up to 1M tokens | Up to 128K tokens | Up to 200K tokens |

## Related Documentation

- [AI Agent CLI Tools](../../../AGENTS.md) - General best practices
- [Codex CLI Guide](codex-cli.md) - OpenAI Codex specifics
- [Claude CLI Guide](claude-cli.md) - Anthropic Claude specifics
- [Main README](../../../README.md) - Dotfiles documentation

## Additional Resources

- [Google AI Studio](https://makersuite.google.com/)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [API Pricing](https://ai.google.dev/pricing)
- [Safety Settings](https://ai.google.dev/docs/safety_setting_gemini)
- [Model Cards](https://ai.google.dev/models/gemini)
