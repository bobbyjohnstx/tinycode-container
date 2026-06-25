---
name: remember
description: Triage a session's findings across memory surfaces — classify each item and route it to the right destination (project memory, CLAUDE.md/AGENTS.md, or session notes) rather than dumping everything into one store
---

# Remember

Use this skill at a natural session boundary when you need to decide what knowledge is worth persisting beyond this conversation.

## When to Use

Use this skill when:
- The user says "remember", "save this", "keep that", or "what should we keep from this session"
- A session surfaced a durable fact, user preference, project convention, or decision with rationale worth persisting
- You are wrapping up a work session and want to distill what graduates from chat history into memory
- The user wants to clean up stale or conflicting memory entries

## When Not to Use

- The user wants a quick scratch note for this session only — use a notepad or inline note instead
- The user wants to directly edit `CLAUDE.md` or `AGENTS.md` — do that edit directly, do not run a triage workflow
- Mid-task capture of working state — wait for a natural review point; mid-task memories are usually temporary
- The information is already captured in `CLAUDE.md` or derivable from the code — do not duplicate it

## Examples

**Good:** "We just figured out the deploy pipeline uses a non-standard port — remember that"
→ Classify as a durable project fact, route to project memory with source context.

**Good:** End of session: "What should we save from today?"
→ Scan the session, classify each candidate, propose destinations.

**Bad:** "Jot down that I want to try Exa for search"
→ That is a scratch note, not a durable memory. Keep it in the conversation or a quick note.

**Bad:** "Update CLAUDE.md with the new build command"
→ Edit CLAUDE.md directly. Do not run a triage workflow for a direct instruction update.

## Goal
Promote durable, reusable knowledge into the right memory surface instead of leaving it buried in chat history.

## Memory surfaces
- **`~/.config/tinycode/projects/<project>/memory/`** — durable project knowledge (facts, feedback, decisions)
- **`CLAUDE.md` / `AGENTS.md`** — durable instructions and conventions when they truly belong there
- **Session notes** — temporary working context for the current conversation only

## Workflow
1. Scan the session for memory candidates: facts established, user corrections or preferences voiced, conventions agreed upon, decisions made with rationale. List each candidate before classifying.
2. Classify each item:
   - durable project fact
   - user preference or feedback
   - operator instruction or convention
   - temporary working note
   - duplicate / stale / conflicting information
3. Propose the best destination for each item.
4. Write or update only the appropriate memory surface.
5. Call out duplicates or conflicts that should be cleaned up.

## Rules
- Do not dump everything into one store.
- Prefer project memory for durable team/project knowledge.
- Keep entries concise and actionable.
- If something is uncertain, mark it as uncertain rather than storing it as fact.
- Do not save things already captured in CLAUDE.md or derivable from the code.

## Output Contract

For each item processed, report:
- **Item:** brief description of the knowledge
- **Destination:** exact surface and path (e.g. `~/.config/tinycode/projects/myproject/memory/project_facts.md`)
- **Action:** stored / updated / skipped (with reason) / flagged as conflict
- **Entry written:** quote the actual text stored (or "skipped" if not written)

End with a **Conflicts/duplicates** block if any were found, listing what to clean up.

Do not report "stored X" without showing the destination path and a quote of what was written.
