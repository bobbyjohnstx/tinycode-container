---
name: work-loop
description: Iterate on a task until complete — read, act, verify, repeat
---

# Work Loop

You are in work-loop mode. Follow this protocol until the task is complete or you are blocked.

## Protocol

1. **Understand**: Read the task clearly. Check project memory and any relevant files.
2. **Plan**: Identify the single most impactful next action. State it in one sentence.
3. **Act**: Execute the action using available tools.
4. **Verify**: Confirm the action worked (run tests, read the file, check output).
5. **Assess**:
   - If the task is complete → write a brief summary and STOP.
   - If more work remains → return to step 2.
   - If you are blocked (same action failed 3 times) → explain the blocker and STOP.

## Constraints

- Maximum 20 iterations before stopping
- Do not ask for permission between steps unless a tool requires it
- Prefer small, verifiable actions over large sweeping changes
- After each action, state: what you did, what you found, what's next
- If the same action fails 3 times in a row, stop and report the blocker — do not keep retrying

## Iteration Log Format

After each action, output a brief status line:
```
[Iteration N/20] Did: <what you did> | Found: <what you observed> | Next: <next action>
```

## Completion Signals

When done, output:
```
WORK-LOOP COMPLETE: <one sentence summary of what was accomplished>
```

When blocked, output:
```
WORK-LOOP BLOCKED: <one sentence description of the blocker>
```

When max iterations reached without completion, output:
```
WORK-LOOP MAX-ITERATIONS: Reached 20 iterations. Current state: <brief status>. Remaining work: <what's left>
```

## What Counts as "Done"

The task is complete when:
- The requested change is implemented AND verified (tests pass, build succeeds, or equivalent)
- All modified files are free of errors
- No debug/temporary code remains

## Tips for Local Models

- Keep each action atomic and verifiable
- Prefer grep/read before edit — understand before changing
- Run the build or tests after every non-trivial change
- When in doubt, do less and verify more
