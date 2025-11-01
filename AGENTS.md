# AI Agent CLI Tools Best Practices

## Overview

AI Agent CLI tools (Codex, Claude, Gemini, etc.) leverage powerful language models to generate, explain, and debug code directly from natural language descriptions. These tools transform the development workflow by enabling developers to describe what they want in plain English and receive functional code snippets, making programming more accessible and efficient for both experienced developers and newcomers.

## Supported Tools

### Available CLI Tools

- **Codex CLI (OpenAI)**: Code generation using GPT models
- **Claude CLI (Anthropic)**: Code assistance with Claude models
- **Gemini CLI (Google)**: AI-powered development with Gemini models

### Installation

```bash
# Install via Homebrew
brew install gemini-cli

# Or use the installation script
~/dotfiles/scripts/install-brew.sh
```

## Use Cases

### Optimal Scenarios
- **Rapid Prototyping**: Generate boilerplate code and initial implementations quickly
- **Learning New Languages**: Get syntax-correct code in unfamiliar programming languages
- **Code Translation**: Convert code between different programming languages
- **Documentation Generation**: Create comprehensive documentation from existing code
- **Unit Test Creation**: Generate test cases based on function specifications
- **Regex Pattern Building**: Construct complex regular expressions from descriptions
- **SQL Query Generation**: Build database queries from natural language requirements
- **Algorithm Implementation**: Transform algorithmic descriptions into working code
- **Code Review**: Get suggestions for code improvements and best practices
- **Debugging Assistance**: Identify and fix bugs with AI-powered analysis

### When to Avoid
- Mission-critical production code without thorough review
- Security-sensitive implementations requiring cryptographic expertise
- Highly optimized performance-critical sections
- Proprietary business logic that shouldn't be exposed to third-party services

## Pros and Cons

### Pros
- Accelerates development speed by 30-50% for routine tasks
- Reduces cognitive load when switching between languages
- Provides instant code examples and patterns
- Helps overcome blank page syndrome
- Supports multiple programming languages seamlessly
- Facilitates learning through generated examples
- Reduces boilerplate code writing time
- Available 24/7 for instant assistance

### Cons
- Generated code may contain subtle bugs or inefficiencies
- Dependency on internet connection and API availability
- Cost considerations for high-volume usage
- Potential for generating outdated patterns
- Risk of intellectual property concerns
- May encourage over-reliance on automation
- Limited understanding of complex business requirements

## Implementation Patterns

### Standard Integration Workflow

```bash
# Basic usage pattern (Gemini CLI example)
gemini generate "Create a Python function that validates email addresses"

# With context specification
gemini generate --language javascript --context "React component" \
  "Create a form input component with validation"

# Interactive mode
gemini chat
```

### Configuration Structure

```yaml
# .ai-cli-config.yaml
api:
  key: ${GEMINI_API_KEY}  # or OPENAI_API_KEY, ANTHROPIC_API_KEY
  model: gemini-pro       # or gpt-4, claude-3-sonnet
  max_tokens: 2048
  temperature: 0.2

defaults:
  language: python
  style: pep8
  documentation: docstring

security:
  mask_secrets: true
  validate_output: true

output:
  format: annotated
  save_history: true
  review_required: true
```

### Environment Setup

Add to your `.zshrc` or `.zshrc.local`:

```bash
# AI Agent CLI Configuration
export GEMINI_API_KEY="your-api-key-here"
export OPENAI_API_KEY="your-api-key-here"
export ANTHROPIC_API_KEY="your-api-key-here"
export CLAUDE_API_KEY="your-api-key-here"  # Alternative naming

# Tool-specific aliases for co-existence
# Gemini (Google)
alias gm="gemini"
alias gmgen="gemini generate"
alias gmchat="gemini chat"
alias gmexp="gemini explain"

# Claude (Anthropic)
alias cl="claude"
alias clgen="claude generate"
alias clchat="claude chat"
alias clrev="claude review"

# Codex (OpenAI)
alias cx="codex"
alias cxgen="codex generate"
alias cxchat="codex chat"

# Generic AI aliases (default to your preferred tool)
alias ai="gemini"          # Change to your preferred default
alias aigen="gemini generate"
alias aichat="gemini chat"
alias aicode="gemini code"

# Task-specific aliases (use each tool's strength)
alias ai-analyze="claude analyze"    # Claude for analysis
alias ai-review="claude review"       # Claude for code review
alias ai-generate="gemini generate"   # Gemini for quick generation
alias ai-refine="codex refine"        # Codex for production code
```

## Security Considerations

### Critical Security Measures

1. **API Key Management**
   - Store API keys in environment variables, never in code
   - Use secret management systems (HashiCorp Vault, AWS Secrets Manager)
   - Rotate API keys regularly (every 90 days minimum)
   - Implement key usage monitoring and alerting

2. **Input Sanitization**
   - Never include sensitive data in prompts
   - Filter out credentials, PII, and proprietary information
   - Implement prompt injection prevention
   - Validate prompt length and complexity

3. **Output Validation**
   - Always review generated code before execution
   - Run static analysis tools on generated code
   - Test in isolated environments first
   - Implement automated security scanning

4. **Data Privacy**
   - Understand each provider's data retention policies
   - Avoid sending proprietary algorithms or trade secrets
   - Implement local caching to minimize API calls
   - Use enterprise agreements for sensitive workloads

### Vulnerability Mitigation

```bash
# Security scanning workflow
gemini generate "function to process user input" | \
  bandit --stdin | \
  semgrep --config=auto --lang=python
```

## Common Pitfalls

### Pitfall 1: Blind Trust in Generated Code
**Problem**: Accepting generated code without review
**Solution**: Implement mandatory code review process and automated testing

### Pitfall 2: Exposing Sensitive Information
**Problem**: Including API keys or passwords in prompts
**Solution**: Use environment variables and secret management tools

### Pitfall 3: Over-Engineering Simple Solutions
**Problem**: Using AI for trivial tasks that don't require assistance
**Solution**: Define clear criteria for when to use AI vs. manual coding

### Pitfall 4: Ignoring Rate Limits
**Problem**: Hitting API rate limits during critical development
**Solution**: Implement caching, queuing, and rate limit monitoring

### Pitfall 5: Version Compatibility Issues
**Problem**: Generated code uses deprecated or incompatible libraries
**Solution**: Specify version requirements in prompts and validate dependencies

### Pitfall 6: License Compliance Violations
**Problem**: Generated code may inadvertently violate licenses
**Solution**: Implement license scanning and attribution tracking

## Best Practices Summary

- [ ] Store API keys securely using environment variables or secret managers
- [ ] Implement comprehensive input sanitization before sending prompts
- [ ] Always review and test generated code before production deployment
- [ ] Use version control to track all generated code
- [ ] Implement rate limiting and caching mechanisms
- [ ] Maintain audit logs of all AI interactions
- [ ] Establish clear guidelines for appropriate use cases
- [ ] Run security scans on all generated code
- [ ] Document the AI-assisted portions of your codebase
- [ ] Implement fallback mechanisms for API unavailability
- [ ] Regular training for team members on secure usage
- [ ] Monitor API usage and costs continuously
- [ ] Validate generated code against coding standards
- [ ] Use specific, detailed prompts for better results
- [ ] Implement automated testing for generated functions

## Workflow Integration

### Daily Development Workflow

1. **Code Generation**: Use AI to generate boilerplate and initial implementations
2. **Code Review**: Review generated code for correctness and security
3. **Testing**: Write and run tests for AI-generated code
4. **Refinement**: Iterate on generated code based on requirements
5. **Documentation**: Use AI to generate documentation and comments

### Project Setup

```bash
# Initialize AI configuration
mkdir -p ~/.config/ai-cli
touch ~/.config/ai-cli/config.yaml

# Set up API keys
echo "export GEMINI_API_KEY='your-key-here'" >> ~/.zshrc.local
source ~/.zshrc

# Test installation
gemini --version
```

## Co-Existence Strategy

### Running Multiple AI CLIs Together

All three AI CLI tools can coexist on your system. Each has unique strengths:

**Gemini CLI (Google)**
- ✨ Strengths: Multi-modal capabilities, fast responses, generous free tier
- 🎯 Best for: Quick code generation, image analysis, rapid prototyping
- 💰 Cost: Free tier available

**Claude CLI (Anthropic)**
- ✨ Strengths: Excellent reasoning, safety features, large context windows (200K tokens)
- 🎯 Best for: Code review, architecture decisions, documentation, complex analysis
- 💰 Cost: Subscription or API-based

**Codex CLI (OpenAI)**
- ✨ Strengths: High accuracy, proven track record, production-ready code
- 🎯 Best for: Production code generation, established patterns, critical systems
- 💰 Cost: Pay-per-token

### Strategic Tool Selection

Create a wrapper function to intelligently route tasks:

```bash
# Add to ~/.zshrc.local
ai_smart() {
  case $1 in
    analyze|review|audit|docs)
      # Claude for analysis and reasoning
      claude "${@:2}"
      ;;
    generate|quick|prototype)
      # Gemini for quick generation
      gemini "${@:2}"
      ;;
    production|deploy|refine)
      # Codex for production code
      codex "${@:2}"
      ;;
    vision|image|diagram)
      # Gemini for multi-modal tasks
      gemini "${@:2}"
      ;;
    *)
      echo "Usage: ai_smart {analyze|review|generate|quick|production|vision} [args]"
      ;;
  esac
}
```

### Ensemble Approach

Get multiple perspectives on the same problem:

```bash
ai_ensemble() {
  local prompt="$1"
  echo "\n=== Claude's Analysis ==="
  claude analyze "$prompt"
  echo "\n=== Gemini's Suggestion ==="
  gemini generate "$prompt"
  echo "\n=== Codex's Implementation ==="
  codex generate "$prompt"
}
```

## Tool-Specific Documentation

For detailed information on specific tools:
- **Gemini CLI**: See [docs/best-practices/ai-tools/gemini-cli.md](docs/best-practices/ai-tools/gemini-cli.md)
- **Claude CLI**: See [docs/best-practices/ai-tools/claude-cli.md](docs/best-practices/ai-tools/claude-cli.md)
- **OpenAI Codex**: See [docs/best-practices/ai-tools/codex-cli.md](docs/best-practices/ai-tools/codex-cli.md)

## Troubleshooting

### Common Issues

**API Key Not Found**
```bash
# Verify environment variable is set
echo $GEMINI_API_KEY

# Add to shell profile if missing
echo "export GEMINI_API_KEY='your-key'" >> ~/.zshrc.local
source ~/.zshrc
```

**Rate Limit Exceeded**
```bash
# Check API usage
gemini usage --show-limits

# Implement caching to reduce calls
gemini config set cache.enabled true
```

**Connection Errors**
```bash
# Test network connectivity
curl -I https://api.google.com

# Check proxy settings if behind corporate firewall
gemini config set proxy.url "http://proxy:8080"
```

## Conclusion

AI Agent CLI tools represent a paradigm shift in software development, offering unprecedented speed and accessibility for code generation. However, their power demands responsible usage with robust security measures, thorough validation processes, and clear operational guidelines.

**When to use AI Agent CLIs:**
- Accelerating development of standard patterns and boilerplate
- Learning new technologies or languages
- Generating initial implementations for further refinement
- Creating comprehensive test suites
- Building proof-of-concepts rapidly

**When to seek alternatives:**
- High-security applications requiring cryptographic expertise
- Performance-critical system components
- Highly specialized domain-specific algorithms
- Situations requiring deep understanding of complex business logic
- When API costs exceed development time savings

The key to successful AI CLI adoption lies in treating it as a powerful assistant rather than a replacement for developer expertise. By implementing the security measures, validation processes, and best practices outlined in this guide, teams can harness the efficiency gains while maintaining code quality and security standards.

Remember: Generated code is a starting point, not a destination. Always review, test, and refine before production deployment.

## Related Documentation

- [Main README](README.md) - Dotfiles documentation
- [Installation Guide](INSTALLATION.md) - Setup instructions
- [AI Prompts Management](AI_PROMPTS.md) - AI prompts system
- [Codex CLI Best Practices](docs/best-practices/ai-tools/codex-cli.md) - Detailed Codex guide
