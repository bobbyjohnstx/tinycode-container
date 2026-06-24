---
name: wiki
description: LLM Wiki — persistent markdown knowledge base that compounds across sessions
---

# Wiki

Persistent, self-maintained markdown knowledge base for project and session knowledge.

## Operations

### Ingest
Process knowledge into wiki pages. A single ingest can touch multiple pages.

```
omc-tools_wiki_ingest({ title: "Auth Architecture", content: "...", tags: ["auth", "architecture"], category: "architecture" })
```

### Query
Search across all wiki pages by keywords and tags. Returns matching pages with snippets — YOU (the LLM) synthesize answers with citations from the results.

```
omc-tools_wiki_query({ query: "authentication", tags: ["auth"], category: "architecture" })
```

### Lint
Run health checks on the wiki. Detects orphan pages, stale content, broken cross-references, oversized pages, and structural contradictions.

```
omc-tools_wiki_lint()
```

### Quick Add
Add a single page quickly (simpler than ingest).

```
omc-tools_wiki_add({ title: "Page Title", content: "...", tags: ["tag1"], category: "decision" })
```

### List / Read / Delete
```
omc-tools_wiki_list()                              # Show all pages (reads index.md)
omc-tools_wiki_read({ page: "auth-architecture" }) # Read specific page
omc-tools_wiki_delete({ page: "outdated-page" })   # Delete a page
```

## Categories
Pages are organized by category: `architecture`, `decision`, `pattern`, `debugging`, `environment`, `session-log`

## Storage
- Pages: `.omc/wiki/*.md` (markdown with YAML frontmatter)
- Index: `.omc/wiki/index.md` (auto-maintained catalog)
- Log: `.omc/wiki/log.md` (append-only operation chronicle)

## Cross-References
Use `[[page-name]]` wiki-link syntax to create cross-references between pages.

## Hard Constraints
- NO vector embeddings — query uses keyword + tag matching only
- Wiki pages are local to the project (`.omc/wiki/` directory)

## Usage Guidelines

When the user asks to "wiki this" or "add to wiki":
1. Identify the key knowledge to capture
2. Choose the appropriate category
3. Use `omc-tools_wiki_ingest` to create or update the page
4. Confirm the page was created with its title

When the user asks to "query wiki" or "find in wiki":
1. Use `omc-tools_wiki_query` with relevant keywords and tags
2. Synthesize the results into a clear answer with page citations
3. If no results, say so clearly — do not invent content

When the user asks to "lint wiki" or "check wiki health":
1. Use `omc-tools_wiki_lint` to run health checks
2. Report findings grouped by severity
3. Suggest fixes for broken cross-references or stale pages
