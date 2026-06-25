---
name: deepinit
description: Deep codebase initialization — generates a per-directory tree of parent-linked AGENTS.md files with merge-preserving regeneration (keeps <!-- MANUAL --> sections), providing whole-repo coverage where the sibling `init` skill writes only a single root file
---

# Deep Init Skill

Creates comprehensive, hierarchical AGENTS.md documentation across the entire codebase.

## Core Concept

AGENTS.md files serve as **AI-readable documentation** that helps agents understand:
- What each directory contains
- How components relate to each other
- Special instructions for working in that area
- Dependencies and relationships

## When to Use

Use this skill when:
- The user says "deepinit", "deep init", "document the whole repo", "AGENTS.md tree", or "per-directory docs"
- The repo is large, nested, or multi-package and a single root CLAUDE.md is insufficient
- You need agents to navigate documentation hierarchically (parent-to-child directory links)
- You are initializing or refreshing AI-readable docs across an entire codebase
- Existing AGENTS.md files need updating while preserving manual annotations

## When Not to Use

- A single root documentation file is all that's needed — use the `init` skill instead
- The repo is trivial or flat (1–2 directories) — use `init`
- The user wants to document a single file or answer a one-off question about the codebase
- The request is to update one existing AGENTS.md by hand

## Examples

**Good:** "Run deepinit on this monorepo — it has 8 packages and agents keep getting lost"
→ deepinit generates a parent-linked AGENTS.md tree across all packages.

**Bad:** "Initialize docs for this project" (small single-package repo with one src/ dir)
→ Use `init` to write a single CLAUDE.md instead.

## Hierarchical Tagging System

Every AGENTS.md (except root) includes a parent reference tag:

```markdown
<!-- Parent: ../AGENTS.md -->
```

This creates a navigable hierarchy:
```
/AGENTS.md                          ← Root (no parent tag)
├── src/AGENTS.md                   ← <!-- Parent: ../AGENTS.md -->
│   ├── src/components/AGENTS.md    ← <!-- Parent: ../AGENTS.md -->
│   └── src/utils/AGENTS.md         ← <!-- Parent: ../AGENTS.md -->
└── docs/AGENTS.md                  ← <!-- Parent: ../AGENTS.md -->
```

## AGENTS.md Template

```markdown
<!-- Parent: {relative_path_to_parent}/AGENTS.md -->
<!-- Generated: {timestamp} | Updated: {timestamp} -->

# {Directory Name}

## Purpose
{One-paragraph description of what this directory contains and its role}

## Key Files
{List each significant file with a one-line description}

| File | Description |
|------|-------------|
| `file.ts` | Brief description of purpose |

## Subdirectories
{List each subdirectory with brief purpose}

| Directory | Purpose |
|-----------|---------|
| `subdir/` | What it contains (see `subdir/AGENTS.md`) |

## For AI Agents

### Working In This Directory
{Special instructions for AI agents modifying files here}

### Testing Requirements
{How to test changes in this directory}

### Common Patterns
{Code patterns or conventions used here}

## Dependencies

### Internal
{References to other parts of the codebase this depends on}

### External
{Key external packages/libraries used}

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
```

## Execution Workflow

> **Scope rule:** Document only the requested repo or subtree. Do not generate AGENTS.md files for directories outside the requested path, even if they are visible on disk.

### Step 1: Map Directory Structure

Spawn an explore agent to list all directories recursively, excluding: `node_modules`, `.git`, `dist`, `build`, `__pycache__`, `.venv`, `coverage`, `.next`, `.nuxt`.

### Step 2: Create Work Plan

Generate todo items for each directory, organized by depth level:

```
Level 0: / (root)
Level 1: /src, /docs, /tests
Level 2: /src/components, /src/utils, /docs/api
...
```

### Step 3: Generate Level by Level

**IMPORTANT**: Generate parent levels before child levels to ensure parent references are valid.

For each directory:
1. Read all files in the directory
2. Analyze purpose and relationships
3. Generate AGENTS.md content
4. Write file with proper parent reference

### Step 4: Compare and Update (if exists)

When AGENTS.md already exists:

1. **Read existing content**
2. **Identify sections**:
   - Auto-generated sections (can be updated)
   - Manual sections (`<!-- MANUAL -->` preserved)
3. **Compare**:
   - New files added?
   - Files removed?
   - Structure changed?
4. **Merge**:
   - Update auto-generated content
   - Preserve manual annotations
   - Update timestamp

### Step 5: Validate Hierarchy

After generation, run validation checks:

| Check | How to Verify | Corrective Action |
|-------|--------------|-------------------|
| Parent references resolve | Read each AGENTS.md, check `<!-- Parent: -->` path exists | Fix path or remove orphan |
| No orphaned AGENTS.md | Compare AGENTS.md locations to directory structure | Delete orphaned files |
| Completeness | List all directories, check for AGENTS.md | Generate missing files |
| Timestamps current | Check `<!-- Generated: -->` dates | Regenerate outdated files |

Validation script pattern:
```bash
# Find all AGENTS.md files
find . -name "AGENTS.md" -type f

# Check parent references
grep -r "<!-- Parent:" --include="AGENTS.md" .
```

## Smart Delegation

| Task | Agent |
|------|-------|
| Directory mapping | `explore` |
| File analysis | `architect` |
| Content generation | `writer` |
| AGENTS.md writes | `writer` |

## Empty Directory Handling

| Condition | Action |
|-----------|--------|
| No files, no subdirectories | **Skip** - do not create AGENTS.md |
| No files, has subdirectories | Create minimal AGENTS.md with subdirectory listing only |
| Has only generated files (*.min.js, *.map) | Skip or minimal AGENTS.md |
| Has only config files | Create AGENTS.md describing configuration purpose |

## Parallelization Rules

1. **Same-level directories**: Process in parallel
2. **Different levels**: Sequential (parent first)
3. **Large directories**: Spawn dedicated agent per directory
4. **Small directories**: Batch multiple into one agent

## Quality Standards

### Must Include
- [ ] Accurate file descriptions
- [ ] Correct parent references
- [ ] Subdirectory links
- [ ] AI agent instructions

### Must Avoid (verifiable)
- [ ] Every `<!-- Parent: -->` path resolves to an existing file
- [ ] Every file name in "Key Files" table exists in the directory (verify against the file read in Step 3)
- [ ] No `## Purpose` section is a single generic sentence that could apply to any directory
- [ ] No directory with files is missing from the "Subdirectories" table of its parent

## Output Contract

Always report on completion:
- **Directories scanned:** total count
- **Files created:** list of new AGENTS.md paths
- **Files updated:** list of updated paths (with what changed)
- **Files skipped:** directories skipped with reason (empty, excluded, out-of-scope)
- **Validation results:** pass/fail for each check in the Validate Hierarchy table
