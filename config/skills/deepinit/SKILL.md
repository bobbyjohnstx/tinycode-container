---
name: deepinit
description: Generate hierarchical AGENTS.md documentation by exploring the codebase structure
---

# Deepinit

Generate clear, hierarchical `AGENTS.md` documentation files for the codebase. These files help agents (and humans) understand the structure, purpose, and conventions of each directory.

## Goal

Every significant directory in the codebase gets an `AGENTS.md` that answers:
- What does this directory contain?
- What is its purpose in the overall system?
- What are the key files and what do they do?
- What conventions apply here (naming, patterns, testing)?
- What should an agent know before modifying files here?

## Protocol

### Phase 1 — Map the codebase
1. List the top-level directory structure
2. Identify the main areas: source code, tests, config, docs, scripts, etc.
3. Note the technology stack (check package.json, Cargo.toml, go.mod, pyproject.toml, etc.)
4. Find existing documentation (README.md, existing AGENTS.md files)

### Phase 2 — Explore key directories
For each significant directory (skip node_modules, .git, dist, build, __pycache__):
1. List its contents
2. Read key files to understand purpose and patterns
3. Check for existing README or docs
4. Note any conventions (naming, exports, test colocation)

### Phase 3 — Write AGENTS.md files
Write an `AGENTS.md` in each significant directory. Prioritize:
1. Root directory (most important — overview of everything)
2. Main source directory (src/, lib/, app/, etc.)
3. Subdirectories with 3+ files or significant complexity

### AGENTS.md Format

```markdown
# [Directory Name]

## Purpose
[1-2 sentences: what this directory is for in the overall system]

## Contents
- `file-or-subdir` — [what it does]
- `file-or-subdir` — [what it does]

## Key Concepts
[Any domain concepts, patterns, or abstractions an agent needs to understand]

## Conventions
- [Naming convention, if any]
- [Testing convention, if any]
- [Import convention, if any]

## Do Not
- [Things agents should avoid in this directory]
- [Files that should not be modified directly]
```

## Constraints

- Only write `AGENTS.md` files — no other changes to the codebase
- Keep each file under 200 lines
- Be specific: "handles JWT validation" not "handles authentication logic"
- Cite actual file names, not hypothetical ones
- If a directory is self-explanatory (e.g., `assets/images/`), skip it

## Completion

When done, output a summary:
```
DEEPINIT COMPLETE
Directories documented: N
Files written:
- /path/to/AGENTS.md
- /path/to/src/AGENTS.md
...
```
