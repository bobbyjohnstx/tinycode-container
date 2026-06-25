---
name: debug
description: Isolate a single most-likely root cause for a known failure — reproduce narrowly, gather concrete evidence, recommend the smallest next fix. For competing hypotheses that need ranking, use trace instead.
---

# Debug

Use this skill when a specific thing is broken and you need to find the root cause fast.

## When to Use

Use this skill when:
- The user says "debug", "why is this failing", "what broke", "X errors at runtime", or "this isn't working"
- A command, test, or hook is producing an error or unexpected output
- Session or orchestration behavior diverges from expectation in a reproducible way
- The user wants a diagnosis and next-step recommendation, not a broad investigation

## When Not to Use

- The root cause is genuinely ambiguous with two or more competing explanations that need ranking — use `trace`
- The task is to confirm a fix works, not to find the cause — use `verify`
- The user wants broad cleanup or refactoring — use `ai-slop-cleaner` or `code-reviewer`
- The user already knows the cause and wants it implemented — use `executor`

## Examples

**Good:** "The pre-commit hook fired but didn't block the commit — debug why"
→ Inspect hook output, reproduce with a test commit, identify the misconfigured condition.

**Bad:** "Why is auth slow sometimes but not always? Could be the DB, the cache, or a race condition"
→ That needs competing hypotheses ranked with evidence. Use `trace`.

**Bad:** "Verify the auth fix worked"
→ Use `verify`.

## Goal
Find the real failure signal quickly and explain the next corrective step.

## Workflow
1. Read the user's issue description carefully.
2. Inspect the most relevant local evidence first:
   - failing tests or commands
   - logs and traces
   - relevant state or config files
3. Attempt a narrow reproduction. If reproduction is not possible, state explicitly why and what evidence substitutes for it — do not proceed to a hypothesis without either a reproduction or a stated substitute.
4. Distinguish symptoms from root cause.
5. Recommend the smallest next fix or verification step.

## Rules
- Prefer real evidence over guesses.
- When the issue involves orchestration, hooks, or agent flow, inspect logs, hook output, and config files first.
- If the issue is actually a product/runtime bug rather than app code, say so plainly.
- Do not prescribe broad rewrites before isolating the failure.

## Output Contract

Every debug run must report:
- **Observed failure:** what the user sees / the error message
- **Root-cause hypothesis:** the single most likely cause
- **Evidence:** concrete proof — log excerpt, failing command output, or file:line reference. Do not restate the hypothesis as evidence. If evidence is not yet gathered, state what probe would produce it.
- **Confidence:** reproduced (confirmed) / inferred (unconfirmed — state what would confirm it)
- **Smallest next action:** one specific step to fix or confirm

A hypothesis labeled "confirmed" must have been reproduced. If not reproduced, label it "unconfirmed" and give the discriminating check.
