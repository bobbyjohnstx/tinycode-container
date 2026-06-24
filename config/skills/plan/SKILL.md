---
name: plan
description: Strategic planning — read context, understand the problem, write a plan, get confirmation before executing
---

# Plan

Strategic planning skill. Creates clear, actionable work plans before any implementation begins.

## When to Use

- User wants to plan before implementing: "plan this", "plan the", "let's plan"
- Task is broad or vague and needs scoping before any code is written
- User wants structured requirements gathering for a vague idea

## When NOT to Use

- User wants to start coding immediately with a clear, specific task
- Task is a single focused fix with obvious scope
- User asks a simple question that can be answered directly

## Planning Protocol

### Step 1 — Understand the request
Classify the request:
- **Trivial/Simple**: Quick fix, single file, obvious scope
- **Scoped**: 2-5 files, clear boundaries, defined acceptance criteria
- **Complex**: Multi-system, unclear scope, needs discovery

### Step 2 — Gather context
Look up codebase facts yourself before asking the user:
- Use @explore to find relevant files and patterns
- Check existing tests, dependencies, and related code
- Never ask the user "where is X implemented?" — find it yourself

### Step 3 — Interview (for broad/vague requests)
Ask ONE focused question at a time about:
- Priorities and timelines
- Scope decisions ("include feature Y?")
- Risk tolerance
- Personal preferences

Never batch multiple questions. Never ask about codebase facts.

### Step 4 — Generate the plan (only when user requests it)
Only generate a plan when the user explicitly says "make it a plan", "generate the plan", or similar.

Plan format:
```markdown
# Plan: [Name]

## Context
[What this plan addresses and why]

## Objectives
[What success looks like]

## Guardrails
**Must have:** [non-negotiable requirements]
**Must NOT do:** [explicit exclusions]

## Steps
1. [Step description]
   - Acceptance criteria: [how to verify this is done]
   - Files affected: [list]

2. [Step description]
   - Acceptance criteria: [how to verify this is done]

## Risks
- [Risk] — Mitigation: [how to handle it]

## Verification
[How to confirm the whole plan succeeded]
```

Save plans to `.omc/plans/{name}.md`.

### Step 5 — Get confirmation
Display a summary and wait for explicit user approval:
- "proceed" — hand off to @executor
- "adjust [X]" — return to interview
- "restart" — discard and start fresh

Never begin implementation without explicit approval.

## Constraints

- Plans have 3-6 steps (not too granular, not too vague)
- Each step has testable acceptance criteria
- No vague terms without metrics ("fast" → "p99 < 200ms")
- 80%+ of claims should cite specific files/lines where applicable
- Open questions go to `.omc/plans/open-questions.md`

## Final Checklist

- [ ] User asked only about preferences (not codebase facts)
- [ ] Plan has 3-6 steps with acceptance criteria
- [ ] User explicitly requested plan generation
- [ ] User confirmed before any implementation handoff
- [ ] Plan saved to `.omc/plans/`
