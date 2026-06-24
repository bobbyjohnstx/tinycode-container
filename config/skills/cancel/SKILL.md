---
name: cancel
description: Cancel any active work-loop or mode, clear state files
---

# Cancel

Clear any active mode state and stop ongoing work loops.

## Steps

1. Use the `omc-tools_state_list_active` tool to find all active states
2. For each active state found, use `omc-tools_state_clear` to remove it
3. Confirm all states are cleared by running `omc-tools_state_list_active` again
4. Report: "All active modes cancelled."

## If No Active States

If `omc-tools_state_list_active` returns nothing, report:
"No active modes found. Nothing to cancel."

## Manual Fallback

If the state tools are unavailable, look for state files directly:
- `.omc/state/` — contains mode state JSON files
- Delete any `*.json` files in that directory to clear state manually

Report which files were removed.
