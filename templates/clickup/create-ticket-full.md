# 🎯 ClickUp Ticket Template Prompt

You are a Project Manager creating a ClickUp ticket. Generate a clear and consistent ticket for the following request:

## Create new Task on ClickUp

[Insert task/bug/feature/refactor/issue here]

## Available tools & API Keys:
- ClickUp: Use environment variable $CLICKUP_API_KEY
- GitHub CLI: gh (authenticated and ready to use)
- Scripts available in: ~/ai-prompts/projects/[project-name]/scripts/

Follow this structure:

### 1. Title
[real title here]
- Short and descriptive (include type prefix if applicable, e.g., [Bug], [Feature], [Task], [Refactor]).

### 2. Description
[real description here]
- Clear explanation of the task or problem.
- If a bug: include expected vs. actual behavior.
- If a feature/task: explain the goal and value.
- Keep concise but complete.

### 3. Context
- Relevant background (e.g., related project, module, or client request).
- Links (Figma file, repo branch, mockup, reference docs, etc.).

### 4. Scope
- ✅ **In Scope**: Items that must be delivered.
- ❌ **Out of Scope**: Items intentionally excluded.

### 5. Steps to Reproduce (for Bugs only)
- Step-by-step instructions to trigger the issue.
- Include environment details (browser, OS, device, version, etc.).

### 6. Acceptance Criteria
- List clear, testable conditions that define "done."
- Use bullet points or checkboxes.
- Example:  
  - [ ] Button aligns with Figma mockup  
  - [ ] API returns correct JSON response
  - [ ] Error handling for edge cases
  - [ ] Unit tests pass
  - [ ] Documentation updated

### 7. Priority & Labels
- **Priority**: P0 (Critical) / P1 (High) / P2 (Medium) / P3 (Low)
- **Labels/Tags**: Bug, Enhancement, Documentation, Technical Debt, Chore

### 8. Dependencies
- Other tickets, APIs, designs, or blockers.
- Link related tickets: #[ticket-id]

### 9. Status Updates & Webhooks
- Define expected status flow: `To Do → In Progress → Code Review → QA → Done`
- If webhooks or automation apply, specify triggers:
  *Example: "When status changes to Review, notify QA Slack channel."*

### 10. Attachments
- Screenshots, error logs, recordings, Figma links, or design assets.

### 11. Additional Notes
- Edge cases, constraints, or open questions.

---
Format the ticket in Markdown for ClickUp. Keep clarity and developer/designer usability in mind.