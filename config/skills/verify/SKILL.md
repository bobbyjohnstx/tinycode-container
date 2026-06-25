---
name: verify
description: Confirm a change works before claiming completion — runs a tiered evidence ladder (existing tests → build → narrow commands → manual) and reports only what was actually proven, never bluffs completion
---

# Verify

Use this skill when the user wants concrete evidence that a recent change works — not a guess, not a summary, but proven output.

## When to Use

Use this skill when:
- The user says "verify", "confirm it works", "check before I push", "validate this PR", or "does this actually work"
- An implementation, fix, or refactor just finished and a completion check is needed before claiming done
- The user wants proof of correct behavior, not an explanation of why it should work

## When Not to Use

- The task is to *write* new test coverage from scratch — use the `test-engineer` agent or TDD workflow
- The goal is to *diagnose why* something fails — use `trace` (competing hypotheses) or `debug` (single root cause)
- The task is to *fix* a defect — verify reports status, it does not edit code
- A broad multi-surface QA sweep is needed — use `ultraqa`
- The change was just made and is obviously broken — fix it first, then verify

## Examples

**Good:** "Verify the auth refactor still logs users in correctly"
→ Runs existing auth tests, checks build, reports VERIFIED with evidence.

**Bad:** "The login test is failing, fix it"
→ That is a fix task. Fix the code first, then invoke verify.

**Bad:** "Why is the login test failing?"
→ That is diagnosis. Use `debug` or `trace`.

## Goal
Turn vague "it should work" claims into concrete evidence.

## Workflow
1. Identify the exact behavior that must be proven.
2. Prefer existing tests first.
3. If coverage is missing, run the narrowest direct verification commands available.
4. If direct automation is not enough, describe the manual validation steps and gather concrete observable evidence.
5. Report only what was actually verified.

## Verification order
1. Existing tests
2. Typecheck / build
3. Narrow direct command checks
4. Manual or interactive validation

## Rules
- Do not say a change is complete without evidence.
- If a check fails, include the failure clearly.
- If no realistic verification path exists, say that explicitly instead of bluffing.
- Prefer concise evidence summaries over noisy logs.
- Do not modify source code to make verification pass — report the failure instead.

## Output Contract

Every verify run must report, in this order:
- **Claim under test:** the specific behavior being proven (from Step 1)
- **Verdict:** VERIFIED / PARTIAL / UNVERIFIED
- **Commands / tests run:** list each command and whether it passed or failed
- **Passed:** what succeeded with evidence
- **Failed or unverified:** what did not pass or could not be checked — never omit this

A report that says "VERIFIED" without listing commands run violates this contract.
