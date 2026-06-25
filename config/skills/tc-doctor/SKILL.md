---
name: tc-doctor
description: Diagnose and fix tinycode environment issues — missing directories, agents, skills, config, connectivity, and container health
---

# tc-doctor

Self-diagnostic skill that checks the tinycode environment is correctly configured and fixes problems it finds.

## When to use

- The user says "doctor", "tc-doctor", "health check", "fix my setup", "why isn't X working"
- After a fresh deployment or container restart
- When agents, skills, or tools aren't appearing
- When tmux/swarm/terminal features aren't working
- When the model connection is failing

## When NOT to use

- The user is asking about their own application code
- The user wants to configure a new provider (use /mcp-setup or /customize-tinycode instead)

## Checks to run (in order)

### 1. Directory structure
Verify these directories exist and are writable. Create any that are missing:

```bash
# Project-level tinycode directory
mkdir -p .tinycode 2>/dev/null && echo "✓ .tinycode/" || echo "✗ .tinycode/ — not writable"

# Required subdirectories
for dir in .tinycode/plans .tinycode/state .tinycode/swarm; do
  mkdir -p "$dir" 2>/dev/null && echo "✓ $dir" || echo "✗ $dir — not writable"
done

# Config directory (may be PVC-mounted)
ls ~/.config/tinycode/ >/dev/null 2>&1 && echo "✓ ~/.config/tinycode/" || echo "✗ ~/.config/tinycode/ — missing"

# Data directory
ls ~/.local/share/tinycode/ >/dev/null 2>&1 && echo "✓ ~/.local/share/tinycode/" || echo "✗ ~/.local/share/tinycode/ — missing"
```

### 2. Agents
Check that bundled agents are loaded:

```bash
# Count agent files in config
AGENT_COUNT=$(ls ~/.config/tinycode/agent/*.md 2>/dev/null | wc -l)
echo "Agent files: $AGENT_COUNT"
if [ "$AGENT_COUNT" -lt 20 ]; then
  echo "✗ Expected 20+ agent files. Check /opt/tinycode-defaults/agent/ and entrypoint.sh"
  # Attempt fix
  if [ -d /opt/tinycode-defaults/agent ]; then
    mkdir -p ~/.config/tinycode/agent
    cp -n /opt/tinycode-defaults/agent/*.md ~/.config/tinycode/agent/ 2>/dev/null
    echo "  → Copied bundled agents. Restart tinycode to pick them up."
  fi
else
  echo "✓ Agents loaded"
fi
```

### 3. Skills
Check that bundled skills are loaded:

```bash
SKILL_COUNT=$(find ~/.config/tinycode/skills -name "SKILL.md" 2>/dev/null | wc -l)
echo "Skill files: $SKILL_COUNT"
if [ "$SKILL_COUNT" -lt 5 ]; then
  echo "✗ Expected 5+ skill files. Check /opt/tinycode-defaults/skills/"
  if [ -d /opt/tinycode-defaults/skills ]; then
    for skill_dir in /opt/tinycode-defaults/skills/*/; do
      skill_name=$(basename "$skill_dir")
      mkdir -p ~/.config/tinycode/skills/$skill_name
      cp -n "$skill_dir"SKILL.md ~/.config/tinycode/skills/$skill_name/ 2>/dev/null
    done
    echo "  → Copied bundled skills. Restart tinycode to pick them up."
  fi
else
  echo "✓ Skills loaded"
fi
```

### 4. Tools availability
Check that required system tools are present:

```bash
for tool in tmux curl tar gzip git; do
  if command -v $tool >/dev/null 2>&1; then
    echo "✓ $tool: $(command -v $tool)"
  else
    echo "✗ $tool: NOT FOUND"
  fi
done
```

### 5. oc CLI (if cluster-admin mode)
```bash
if [ "${TINYCODE_CLUSTER_ADMIN}" = "true" ] || [ -f ~/.kube/config ]; then
  if command -v oc >/dev/null 2>&1; then
    echo "✓ oc: $(oc version --client 2>/dev/null | head -1)"
    oc whoami 2>/dev/null && echo "✓ Cluster auth valid" || echo "✗ Cluster auth failed — kubeconfig may be expired"
  else
    echo "✗ oc: NOT FOUND — cluster-admin mode requires oc CLI"
  fi
fi
```

### 6. Model connectivity
Check if the configured model responds:

```bash
# Check if any provider is connected
curl -sf http://localhost:4096/provider 2>/dev/null | python3 -c "
import sys, json
try:
  providers = json.load(sys.stdin)
  connected = [p['id'] for p in providers if any(m.get('status') == 'active' for m in p.get('models', {}).values())]
  if connected:
    print(f'✓ Connected providers: {connected}')
  else:
    print('✗ No connected providers — check model configuration')
except:
  print('✗ Could not query provider status')
" 2>/dev/null || echo "✗ tinycode API not responding on localhost:4096"
```

### 7. tmux / swarm readiness
```bash
if command -v tmux >/dev/null 2>&1; then
  echo "✓ tmux available: $(tmux -V)"
  # Test tmux can create a session
  if tmux new-session -d -s tc-doctor-test 2>/dev/null; then
    tmux kill-session -t tc-doctor-test 2>/dev/null
    echo "✓ tmux sessions work"
  else
    echo "✗ tmux cannot create sessions — check /tmp permissions and terminal settings"
  fi
else
  echo "✗ tmux not installed — /swarm skill will not work"
fi
```

### 8. Disk space
```bash
df -h / /home/tinycode/.local/share/tinycode 2>/dev/null | tail -n +2 | while read fs size used avail pct mount; do
  pct_num=${pct%\%}
  if [ "$pct_num" -gt 90 ]; then
    echo "✗ $mount: ${pct} used ($avail free) — LOW DISK SPACE"
  else
    echo "✓ $mount: ${pct} used ($avail free)"
  fi
done
```

## Output format

```
## tinycode Doctor Report

### Environment
- Container: [yes/no]
- Working directory: [path]
- User: [uid]

### Checks
[results from each check above]

### Issues Found
- [list of ✗ items]

### Fixes Applied
- [list of automatic fixes taken]

### Manual Actions Needed
- [anything that couldn't be auto-fixed]
```

## Important

- Run ALL checks, even if early ones fail
- Apply fixes automatically where safe (directory creation, file copying)
- Do NOT modify user config files (tinycode.json, tinycode.jsonc)
- Do NOT restart tinycode — tell the user to restart if needed
- Report everything found, even if all checks pass
