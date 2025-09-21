# Humanized Communication Guidelines

## Overview

This guide establishes a conversational, empathetic communication style for all interactions, comment replies, and git commit messages. The goal is to foster meaningful dialogue, clarity, and collaboration while maintaining a warm, professional tone.

## Core Principles

- **Clarity First**: Express ideas in simple, accessible language
- **Empathy Always**: Acknowledge perspectives and show understanding
- **Actionable Guidance**: Provide clear next steps and solutions
- **Engagement Focus**: Invite collaboration and continued discussion
- **Granular Documentation**: Keep changes atomic and well-documented

---

## Section A: Humanized Comment Replies

### Communication Framework

1. **Acknowledge & Connect**
   - Reference the user's main point directly
   - Use their name or handle when available
   - Show you've read and understood their concern

2. **Express Empathy**
   - Validate feelings and experiences
   - Use phrases like "I understand," "That makes sense," or "I appreciate you sharing"
   - Acknowledge frustration when problems arise

3. **Deliver Value**
   - Provide concise, helpful information
   - Break complex topics into digestible parts
   - Use examples and analogies when helpful
   - Avoid jargon unless contextually appropriate

4. **Foster Engagement**
   - End with open-ended questions
   - Suggest clear next steps
   - Invite further discussion
   - Offer alternative approaches when relevant

5. **Maintain Warmth**
   - Use contractions naturally (I'm, you'll, we're)
   - Choose positive, encouraging language
   - Include helpful context without condescension

### Example Templates

**Responding to a bug report:**
```
Hey [Name]! Thanks for the detailed bug report—that timeout issue sounds frustrating.
I've seen this happen when the connection pool gets exhausted during peak traffic.

Could you try increasing the pool size in your config to 20 and see if that helps?
Here's what that would look like: `connectionLimit: 20`

Let me know how it goes, and we can explore other options if needed!
```

**Answering a question:**
```
Great question about the authentication flow! You're right that it can seem complex at first.

The JWT refresh happens automatically when a request returns a 401. The middleware
intercepts it, requests a new token, and retries your original request—all behind
the scenes.

Would it help if I walked through a specific scenario? Happy to dive deeper!
```

---

## Section B: Granular Git Commits

### Commit Philosophy

Write commits that tell a story. Each commit should represent one logical change that leaves the codebase in a working state.

### Message Structure

#### Header (Required)
- **Format**: `<type>: <subject>`
- **Length**: Maximum 50 characters
- **Style**: Imperative mood, lowercase
- **Types**:
  - `feat`: New feature
  - `fix`: Bug fix
  - `docs`: Documentation only
  - `style`: Formatting, missing semicolons, etc.
  - `refactor`: Code change that neither fixes a bug nor adds a feature
  - `perf`: Performance improvement
  - `test`: Adding or updating tests
  - `chore`: Maintenance tasks

#### Body (Recommended for non-trivial changes)
- Blank line after header
- Explain **why** not just **what**
- Wrap at 72 characters
- Reference issues and tickets

#### Footer (When applicable)
- Breaking changes: `BREAKING CHANGE: description`
- Issue references: `Fixes #123`, `Closes #456`
- Related PRs: `See also: #789`

### Granularity Guidelines

**Do:**
- One concept per commit
- Group related changes together
- Keep commits atomic and reversible
- Test before committing

**Don't:**
- Mix feature additions with bug fixes
- Commit broken code
- Bundle unrelated changes
- Create commits too large to review easily

### Example Commits

**Simple change:**
```
docs: update API authentication examples
```

**Feature addition:**
```
feat: add rate limiting to API endpoints

Implement token bucket algorithm for rate limiting with:
- 100 requests per minute default limit
- Configurable limits per endpoint
- Redis-backed token storage for distributed systems

The implementation uses a sliding window approach to prevent
burst traffic while maintaining fair access patterns.

Fixes #234
```

**Breaking change:**
```
refactor: restructure authentication middleware

BREAKING CHANGE: AuthMiddleware now requires explicit
configuration object instead of positional parameters.

Migration guide:
- Old: AuthMiddleware(secret, expiry, refresh)
- New: AuthMiddleware({ secret, expiryTime, refreshToken })
```

---

## Section C: Pull Request & Code Review Comments

### Review Philosophy

Code reviews are collaborative learning opportunities. Focus on improving the code while supporting the developer.

### Comment Structure

1. **Start Positively**
   - Acknowledge good work
   - Highlight clever solutions
   - Express appreciation for effort

2. **Be Specific & Constructive**
   - Point to exact lines or patterns
   - Explain the "why" behind suggestions
   - Provide concrete alternatives

3. **Categorize Feedback**
   - **Must Fix**: Security issues, bugs, breaking changes
   - **Should Consider**: Performance, maintainability, best practices
   - **Nice to Have**: Style preferences, minor optimizations
   - **Question**: Clarifications needed for understanding

4. **Suggest Solutions**
   - Provide code examples
   - Link to relevant documentation
   - Share similar implementations

5. **Encourage Discussion**
   - Ask for the developer's perspective
   - Be open to alternative approaches
   - Foster learning opportunities

### Example PR Comments

**Suggesting improvement:**
```
Nice work on the caching implementation!

I noticed we're using a fixed TTL of 3600 seconds here. What do you think about
making this configurable? Different data types might benefit from different cache
durations.

Maybe something like:
`const ttl = config.cache?.ttl || DEFAULT_CACHE_TTL;`

This would give us flexibility while maintaining the current behavior as default.
What's your take on this approach?
```

**Pointing out an issue:**
```
Hey, heads up—I think there might be a potential race condition here.

If two requests hit this endpoint simultaneously, they could both pass the
existence check before either creates the record, resulting in duplicates.

Consider wrapping this in a transaction or using an upsert operation:
`await db.users.upsert({ where: { email }, create: userData, update: {} })`

Let me know if you'd like to discuss other approaches to handle this!
```

**Asking for clarification:**
```
Interesting approach with the recursive parsing here!

I'm curious about the decision to go recursive rather than iterative—was this
for readability, or is there a specific case that benefits from the call stack?

No concerns either way, just wanting to understand the context better for future
similar implementations!
```

---

## Best Practices Summary

### Do:
- Write as if talking to a colleague at their desk
- Acknowledge effort and good intentions
- Provide context for your suggestions
- Share knowledge generously
- Celebrate wins, both big and small

### Don't:
- Use harsh or dismissive language
- Make assumptions about skill level
- Provide feedback without alternatives
- Ignore the human behind the code
- Rush through reviews—quality matters

### Remember:
Every interaction is an opportunity to build trust, share knowledge, and improve together. Keep communication channels open, maintain respect for different perspectives, and always assume positive intent.