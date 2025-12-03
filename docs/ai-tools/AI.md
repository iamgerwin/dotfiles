# AI Coding Workflow Guidelines

## 🎯 Core Principles
- **Mental alignment**: Always seek clarification, never assume—ask even at 90% certainty
- **Incremental commits**: Granular, trackable progress with conventional commits
- **No AI attribution**: Never mention Claude/AI/co-authored in commits, PRs, or comments
- **No auto-posting**: Never comment on ClickUp unless explicitly instructed
- **Stay in Smart Zone**: Keep context <40% capacity (avoid "dumb zone" degradation)
- **Frequent Intentional Compaction**: Compress context to markdown after every phase
- **No Vibes Coding**: Research → Plan → Implement (RPI). Never skip planning
- **Trajectory Awareness**: Reset conversations showing failure patterns (yell-correct loops)
- **Specify Persona**: Identify what's the basic characteristic of agent, Senior Developer ? Backend? Frontend? UI UX? this will boost quality

## 🏗️ Branching & Commit Strategy

### For ClickUp Feature/Bugfix Tasks

1. Branch from `latest develop`: [commit-type]/[clickup-id]-[short-description]
   - commit-type: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `cherrypick`
   - Example: `feat/CU-1234-add-user-profile-api`

2. Create **TWO PR sets**:
   - **PR #1**: Feature branch → `develop`
   - **PR #2**: Cherry-pick commits → `main` (resolve conflicts, exact commits only)

## ✅ Pre-Implementation Checks

- [ ] Document only what's necessary
- [ ] No destructive changes/migrations
- [ ] Focus ONLY on required files
- [ ] Defensive coding - preserve existing behavior
- [ ] Mimic existing patterns or document best-practice deviations
- [ ] Always ask when in doubt (90% rule)
- [ ] Context size: <40% window capacity
- [ ] Compaction: Current state → tagged markdown
- [ ] Trajectory: No failure patterns in history
- [ ] Onboarding: Dynamic research (not static docs)
- [ ] Sub-agent scope: Discovery only, succinct returns

## 🔬 RPI Workflow (Research → Plan → Implement)

Store findings: `docs/plans/[ticket-id]-[short-title].md`

### RESEARCH Phase
```
File: docs/plans/[ticket]-research.md

□ Objective codebase scan (files, line numbers, flows)
□ On-demand vertical slices (no stale docs)
□ Compress truth from code itself
□ Sub-agents for scoped discovery only
□ Search for impacted files proactively
□ Zero tolerance for assumptions/hallucinations
□ Clarify requirements for mental alignment
```

### PLAN Phase
```
File: docs/plans/[ticket]-plan.md

□ Explicit steps + file paths + code snippets
□ Post-change test instructions
□ Human review REQUIRED (90% rule)
□ Sweet spot: Detailed for agents, readable for humans
□ Code snippets show exact changes
□ Test validation after each step
```

### IMPLEMENT Phase
```
□ Execute plan only - no improvisation
□ Compact prior state before next iteration
□ Fresh context window with plan only
□ Focus on files outlined in plan
```

## 💎 Coding Standards

- ✅ Use enums (avoid magic strings/numbers)
- ✅ Eliminate code smells
- ✅ New enums → respective directories
- ✅ Match existing codebase style
- ✅ Document intentional best-practice improvements

## 🚫 Anti-Slop Rules

```
❌ NEVER: "Vibe coding" without RPI
❌ NEVER: Skip human plan review
❌ NEVER: >40% context (dumb zone)
❌ NEVER: Static docs (they lie most)
❌ NEVER: Anthropomorphize sub-agents (roles)
✅ ALWAYS: Compact before reset
✅ ALWAYS: Code snippets in plans
✅ ALWAYS: Mental alignment via plan review
```

## 📋 Final Deliverables Checklist

### 1. Create Pull Request Summary

File: `docs/pullrequests/[ticket-id]-[short-title].md`

**Format:**

# [Ticket Title]

## RPI Summary
```
Research: docs/plans/[ticket]-research.md
Plan: docs/plans/[ticket]-plan.md ← HUMAN APPROVED
Implementation: Executed per plan
Context Compactions: [X] iterations
```

## PR Links
- **Develop PR**: [link]
- **Main Cherry-pick PR**: [link]

## Status
- [ ] Code Review

## Description
[Clear implementation summary]

## Files Changed
[List key files with purpose]

## Technical Details
[Bullet points on approach, decisions, tests]

## Mental Alignment Notes
[Key decisions from plan review, human sign-offs]

## Reviewers
@reviewer1 @reviewer2 [ClickUp task assignees]

### 2. Critical Features

Create: `docs/[feature-name]/[implementation|fix|improvement].md`

### 3. Git Operations

- [ ] Professional PR titles/descriptions
- [ ] Push both PRs (develop + main cherry-pick)
- [ ] Verify all commits included correctly
- [ ] Attach RPI summary/threads to PR for transparency

## 🚀 Enhanced RPI Workflow

```
1. RESEARCH → docs/plans/[ticket]-research.md (compress truth)
2. PLAN → docs/plans/[ticket]-plan.md (HUMAN REVIEW)
3. IMPLEMENT → Fresh context w/ plan only
4. COMPACT → docs/plans/[ticket]-compaction-[n].md
5. REPEAT → Stay in smart zone (<40%)
6. MENTAL ALIGNMENT → Plan review > code review
```

## 🧠 Mental Alignment Strategy

**Why it matters**: Keep the entire engineering team synchronized on how the codebase is evolving and why—not just catching bugs, but understanding intent.

**How to achieve it**:
- Human-in-loop: Review research/plans iteratively; peers approve before implementation
- Leverage compression: Detailed-but-readable plans hit the sweet spot (reliable execution + skimmable)
- Cultural shift: Share plans in PRs for transparency; prevents seniors cleaning up juniors' slop
- Catch early: One bad research line cascades to 100 bad code lines—review hierarchy matters

**Key insight**: Read plans instead of 1000+ lines of code. Leaders stay informed without drowning in diffs.

## ⚠️ "Don't Outsource the Thinking" & "This Isn't Magic"

**Core warnings**:
- AI cannot replace human judgment—it amplifies whatever you provide (garbage in = garbage out)
- No perfect prompt exists; success demands human review of research and plans
- Bad inputs cascade catastrophically: Misunderstanding flow → flawed plan → wrong execution
- Watch for tools spewing unvetted markdown—stay in the loop

**Practical application**:
- Humans drive highest-leverage steps (research validation, plan approval)
- Shift effort from code reading to oversight
- Build intuition through reps—get it wrong repeatedly
- Without discipline, teams rift: juniors vibe-code slop, seniors burn out fixing it

## 📚 Context Engineering Checklist

```
□ Context size: <40% window capacity
□ Compaction: Current state → tagged markdown
□ Trajectory: No failure patterns in conversation
□ Onboarding: Dynamic research (not stale static docs)
□ Sub-agents: Scoped discovery, succinct returns
□ Research: Grounded in code, not assumptions
□ Plans: Include code snippets, test steps
□ Implementation: Execute plan only
□ Review: Human sign-off before agent work
```

## 🎓 Learning & Iteration

- Pick one tool (Claude/Cursor) and get reps
- You will get RPI scope wrong repeatedly—that's normal
- Too much compaction = missed context; too little = dumb zone
- Find your team's sweet spot through practice
- Avoid minmaxing across multiple tools

## 🚀 Workflow Summary

1. Branch from develop → Implement incrementally (RPI)
2. Research/Plan → `docs/plans/[ticket].md` (human review)
3. Code → Match standards, enums, no destruction
4. `docs/pullrequests/[ticket].md` → Review summary with RPI
5. PR #1: develop | PR #2: main (cherry-pick)
6. ASK for clarification → Mental alignment first
7. Compact context → Prepare for next iteration

**Remember**: Precision over speed. Clarity over assumptions. Alignment over automation. Think first, ask second, code third.

Final checks:
- NEVER mention AI / Claude / 🤖 Generated with [Claude Code](https://claude.com/claude-code) / on PR, comments, commit messages
