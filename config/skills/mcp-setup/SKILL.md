---
name: mcp-setup
description: Configure MCP servers via a guided menu — curated bundles (Context7, Exa, Filesystem, GitHub) or a custom stdio/HTTP server — using tinycode mcp add, with scope control, verification, and troubleshooting guidance
---

# MCP Setup

Configure Model Context Protocol (MCP) servers to extend tinycode's capabilities with external tools like web search, file system access, and GitHub integration.

## Overview

MCP servers provide additional tools that tinycode agents can use. This skill helps you configure popular MCP servers using the `tinycode mcp add` command-line interface.

## When to Use

Use this skill when:
- The user says "set up MCP", "add an MCP server", "configure Context7/Exa/Filesystem/GitHub", or "extend tinycode with external tools"
- The user wants web search, docs context, file access, or GitHub integration via MCP
- The user wants to add a custom stdio or HTTP MCP server to their tinycode config

## When Not to Use

- The user wants to *write or code* a new MCP server implementation — that is development work, not setup
- The user wants to change tinycode settings, hooks, or permissions — use the `update-config` skill
- The user needs deep runtime debugging of a failing MCP server beyond the Common Issues list — use `debug`
- The user already has MCP servers configured and just wants to list or remove them — run `tinycode mcp list` or `tinycode mcp remove <name>` directly

## Step 1: Choose a Setup Path

Use **AskUserQuestion** with **one question at a time** and **no more than 3 options per question**.

### Step 1.1: First menu

**Question:** "What kind of MCP setup would you like?"

**Options:**
1. **Recommended starter setup** - Fast path for the most common tinycode MCP additions
2. **Individual popular server** - Pick one server from a short follow-up menu
3. **Custom server** - Add your own stdio or HTTP MCP server

### Step 1.2: If the user chooses "Recommended starter setup"

Ask a follow-up **AskUserQuestion**:

**Question:** "Which recommended MCP bundle should I configure?"

**Options:**
1. **Context7 only (Recommended)** - Zero-config docs/context server
2. **Context7 + Exa** - Docs/context plus enhanced web search
3. **Full recommended bundle** - Context7, Exa, Filesystem, and GitHub

### Step 1.3: If the user chooses "Individual popular server"

Ask a follow-up **AskUserQuestion**:

**Question:** "Which server should I configure first?"

**Options:**
1. **Context7 (Recommended)** - Documentation and code context from popular libraries
2. **Exa Web Search** - Enhanced web search (replaces built-in websearch)
3. **More server choices** - Filesystem, GitHub, or the full recommended bundle

If the user chooses **More server choices**, ask one more **AskUserQuestion**:

**Question:** "Which additional MCP option do you want?"

**Options:**
1. **Filesystem (Recommended)** - Extended file system access with additional capabilities
2. **GitHub** - GitHub API integration for issues, PRs, and repository management
3. **Full recommended bundle** - Configure Context7, Exa, Filesystem, and GitHub together

### Step 1.4: If the user chooses "Custom server"

Skip directly to the **Custom MCP Server** section below.

## Step 2: Gather Required Information

### For Context7:
No API key required. Ready to use immediately.

### For Exa Web Search:
Ask for API key:
```
Do you have an Exa API key?
- Get one at: https://exa.ai
- Enter your API key, or type 'skip' to configure later
```

### For Filesystem:
Ask for allowed directories:
```
Which directories should the filesystem MCP have access to?
Default: Current working directory
Enter comma-separated paths, or press Enter for default
```

### For GitHub:
Ask for token:
```
Do you have a GitHub Personal Access Token?
- Create one at: https://github.com/settings/tokens
- Recommended scopes: repo, read:org
- Enter your token, or type 'skip' to configure later
```

## Step 3: Add MCP Servers Using CLI

Use the `tinycode mcp add` command to configure each MCP server. The CLI automatically handles settings.json updates and merging.

> **Scope:** By default, `tinycode mcp add` writes to the user-level config (`~/.config/tinycode/`). To scope to the current project only, add `-s project` (or `--scope project`). Ask the user if they want user-level (available everywhere) or project-level (this repo only) when it's not obvious.

### Context7 Configuration:
```bash
tinycode mcp add context7 -- npx -y @upstash/context7-mcp
```

### Exa Web Search Configuration:
```bash
tinycode mcp add -e EXA_API_KEY=<user-provided-key> exa -- npx -y exa-mcp-server
```

### Filesystem Configuration:
```bash
tinycode mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem <allowed-directories>
```

> **Note:** The `<allowed-directories>` argument requires space-separated paths, not comma-separated. If the user provided comma-separated paths (e.g., `/home/user, /projects`), convert them: `tinycode mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem /home/user /projects`

### GitHub Configuration:

**Option 1: Docker (local)**
```bash
tinycode mcp add -e GITHUB_PERSONAL_ACCESS_TOKEN=<user-provided-token> github -- docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server
```

**Option 2: HTTP (remote)**
```bash
tinycode mcp add --transport http github https://api.githubcopilot.com/mcp/
```

> Note: Docker option requires Docker installed. HTTP option is simpler but may have different capabilities.

## Step 4: Verify Installation

After configuration, verify the MCP servers are properly set up:

```bash
# List configured MCP servers
tinycode mcp list
```

Include the `tinycode mcp list` output in the Step 5 completion report. Only claim "configured" for servers that appear in this output. If a server does not appear, report it as "not registered" and suggest the troubleshooting step.

## Step 5: Show Completion Message

**Always report on completion (required — substitute real values, not placeholders):**
- Which servers were successfully configured (verified present in `tinycode mcp list` output)
- Which servers were deferred because the user skipped an API key (list them and what key is needed)
- The actual output of `tinycode mcp list` confirming the servers are registered
- The restart reminder

```
MCP Server Configuration Complete!

CONFIGURED SERVERS:
[List the servers that were configured]

NEXT STEPS:
1. Restart tinycode for changes to take effect
2. The configured MCP tools will be available to all agents
3. Run `tinycode mcp list` to verify configuration

USAGE TIPS:
- Context7: Ask about library documentation (e.g., "How do I use React hooks?")
- Exa: Use for web searches (e.g., "Search the web for latest TypeScript features")
- Filesystem: Extended file operations beyond the working directory
- GitHub: Interact with GitHub repos, issues, and PRs

TROUBLESHOOTING:
- If MCP servers don't appear, run `tinycode mcp list` to check status
- Ensure you have Node.js 18+ installed for npx-based servers
- For GitHub Docker option, ensure Docker is installed and running
- Check server logs for errors

MANAGING MCP SERVERS:
- Add more servers: `tinycode mcp add ...`
- List servers: `tinycode mcp list`
- Remove a server: `tinycode mcp remove <server-name>`
```

## Custom MCP Server

If user selects "Custom":

Ask for:
1. Server name (identifier)
2. Transport type: `stdio` (default) or `http`
3. For stdio: Command and arguments (e.g., `npx my-mcp-server`)
4. For http: URL (e.g., `https://example.com/mcp`)
5. Environment variables (optional, key=value pairs)
6. HTTP headers (optional, for http transport only)

Then construct and run the appropriate `tinycode mcp add` command:

**For stdio servers:**
```bash
# Without environment variables
tinycode mcp add <server-name> -- <command> [args...]

# With environment variables
tinycode mcp add -e KEY1=value1 -e KEY2=value2 <server-name> -- <command> [args...]
```

**For HTTP servers:**
```bash
# Basic HTTP server
tinycode mcp add --transport http <server-name> <url>

# HTTP server with headers
tinycode mcp add --transport http --header "Authorization: Bearer <token>" <server-name> <url>
```

## Common Issues

### MCP Server Not Loading
- Ensure Node.js 18+ is installed
- Check that npx is available in PATH
- Run `tinycode mcp list` to verify server status
- Check server logs for errors

### API Key Issues
- Exa: Verify key at https://dashboard.exa.ai
- GitHub: Ensure token has required scopes (repo, read:org)
- Re-run `tinycode mcp add` with correct credentials if needed

### Agents Still Using Built-in Tools
- Restart tinycode after configuration
- The built-in websearch will be deprioritized when exa is configured
- Run `tinycode mcp list` to confirm servers are active

### Removing or Updating a Server
- Remove: `tinycode mcp remove <server-name>`
- Update: Remove the old server, then add it again with new configuration
