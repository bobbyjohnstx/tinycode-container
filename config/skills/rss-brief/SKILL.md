---
name: rss-brief
description: Use this skill when the user asks for a news brief, story summary, or wants to search the rss-feeder for articles on a topic. Trigger phrases include "rss brief", "brief on", "what's in my feeds about", "summarize news about", "story brief for", or any request to search rss-feeder and get a synthesized summary.
version: 1.0.0
---

# RSS Brief Skill

Searches the rss-feeder semantic index for the best matching item on a topic, then synthesizes a narrative brief from that item and its related items.

## mcpo Endpoint

All tools are available via POST to:
```
http://192.168.68.74:8000/rss_feeder/<tool_name>
```

Call them with Bash/curl — no auth header needed (mcpo handles it):
```bash
curl -s http://192.168.68.74:8000/rss_feeder/<tool_name> \
  -X POST -H "Content-Type: application/json" \
  -d '<json body>'
```

## Workflow

### Step 1 — Semantic search for the query

Call `rss_search_items` with the user's query. Use `days=0` to search all time unless the user specifies recency.

```bash
curl -s http://192.168.68.74:8000/rss_feeder/rss_search_items \
  -X POST -H "Content-Type: application/json" \
  -d '{"q": "<user query>", "days": 0, "limit": 5}'
```

Take the **first result** (highest similarity score). Note its `id`, `title`, `feed_name`, `published_at`, `ai_summary`, and `url`.

### Step 2 — Get related items

Call `rss_get_related` with the top item's id.

```bash
curl -s http://192.168.68.74:8000/rss_feeder/rss_get_related \
  -X POST -H "Content-Type: application/json" \
  -d '{"item_id": <id>}'
```

Note the related items — title, feed_name, published_at, score, and url. If the list is empty, proceed without them.

### Step 3 — Generate the story brief

Call `rss_get_brief` with the top item's id. This combines the item's AI summary with related items into a narrative via Ollama. First call takes 5–15s; subsequent calls return cached.

```bash
curl -s http://192.168.68.74:8000/rss_feeder/rss_get_brief \
  -X POST -H "Content-Type: application/json" \
  -d '{"item_id": <id>}'
```

### Step 4 — Fetch summaries for top related items (optional enrichment)

If related items exist and their summaries would add context, fetch a few with `rss_get_summary`:

```bash
curl -s http://192.168.68.74:8000/rss_feeder/rss_get_summary \
  -X POST -H "Content-Type: application/json" \
  -d '{"item_id": <related_id>}'
```

### Step 5 — Write the narrative output

Present the result in this structure:

```
**<Feed Name> — <date>**
**"<Title>"**
<url>

<The brief from rss_get_brief — 3-5 sentences synthesized narrative>

**In context of related items:**
<For each related item with a score above 0.72:
- **<Feed Name> — "<Title>"** (score)
  <url>
  <one sentence on how it connects to the main item>
Arrange chronologically to show how the topic has evolved over time.>

**The throughline:**
<1-2 sentences identifying the core tension or theme that runs across all the related items.>
```

## Notes

- If the search returns no results, tell the user and suggest a broader query.
- If `rss_get_brief` returns `"cached": true`, mention it was retrieved from cache.
- The semantic search finds conceptually related items even without exact word matches — a query like "AI job displacement" will surface relevant items even if they don't use those exact words.
- If the user specifies a feed by name, pass `feed_id` to narrow the search. Use `rss_list_feeds` first to resolve the name to an id.
