# Code Review Checklist

Review the changes on `@branch`:

- Think through how data flows in the app. Explain new patterns if they exist and why.
- Were there any changes that could affect infrastructure?
- Consider empty, loading, error, and offline states.
- Review frontend changes for accessibility (a11y): keyboard navigation, focus management, ARIA roles, color contrast.
- If public APIs have changed, ensure backwards compatibility (or increment API version).
- Did we add any unnecessary dependencies? If there's a heavy dependency, could we inline a more minimal version?
- Did we add quality tests? Prefer fewer, high-quality tests. Prefer integration tests for user flows.
- Were there schema changes which could require a database migration?
- Changes to auth flows or permissions? Run `/security-review`.
- If feature flags are set up, does this change require adding a new one?
- If i18n is set up, are the strings added localized and new routes internationalized?
- Are there places we should use caching?
- Are we missing critical observability or logging on backend changes?

# Additional Best Practices for Code Reviews

- **Focus on the goal, not the style:** Ensure the code solves the problem effectively rather than nitpicking style issues (which can be addressed by automated linters).
- **Review in small chunks:** Smaller PRs are easier and faster to review, reducing cognitive load and speeding feedback.
- **Verify code readability and maintainability:** Is the code easy to understand by others? Are function and variable names clear?
- **Check for security vulnerabilities:** Validate input sanitization, authentication, and permission checks.
- **Ensure performance considerations:** Identify potential bottlenecks or inefficient algorithms.
- **Test coverage:** Confirm critical paths are tested; missing tests should be flagged.
- **Provide constructive, actionable feedback:** Focus on describing the issue and suggesting improvements, not just pointing out problems.
- **Be cautious for code deletion:** If you delete code, make sure it's not being used by other parts of the codebase.
- **Never edit any migration file:** If you need to make changes to a migration file, create a new one and run the migration.
- **Keep on eye for sharing secrets / tokens / keys / credentials / passwords:** Never share secrets or any sensitive information that's not needed.
- **Don't let any bad code / patterns / practices slip through:** If you find any bad code, flag it and suggest improvements.
- **Use checklists:** Consistent checklists reduce missed steps and streamline the review process.
- **Collaborate and communicate:** Engage in discussions openly when clarifying intentions or proposing alternative approaches.
- **Respect the author:** Keep comments respectful and supportive, acknowledging good work to foster positive team dynamics.
- **Align Documentation:** Ensure that the code aligns with the project's documentation and that the documentation is updated accordingly.

# Summary

Code reviews are crucial for maintaining code quality, security, and team knowledge sharing. A systematic, empathetic approach supported by checklists and best practices makes reviews efficient and valuable.
