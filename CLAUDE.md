# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

A **Claude Code Plugin Marketplace** for developing, testing, and managing plugins. Contains two plugin types: content-based plugins (skills, commands, agents) and behavior-based plugins (hooks).

## Repository Structure

```
claude-marketplace/
├── .claude-plugin/marketplace.json    # Plugin registry
└── plugins/
    ├── cloudflare-expert/             # Content-based plugin example
    │   ├── .claude-plugin/plugin.json
    │   ├── skills/                    # Auto-activating expertise
    │   ├── commands/                  # Slash commands
    │   ├── agents/                    # Autonomous specialists
    │   └── .mcp.json                  # MCP server config
    └── hooks-lab/                     # Behavior-based plugin example
        ├── .claude-plugin/plugin.json
        └── hooks/
            ├── hooks.json             # Hook configuration
            ├── session-hooks/         # SessionStart, SessionEnd
            ├── tool-hooks/            # PreToolUse, PostToolUse
            ├── prompt-hooks/          # UserPromptSubmit
            └── lib/                   # Shared utilities
```

## Plugin Component Types

### Skills
Auto-activating expertise modules in `plugins/{name}/skills/{skill-name}/SKILL.md`.

```yaml
---
name: Skill Name
description: Trigger keywords that activate this skill
version: 0.1.0
---
```

### Commands
Slash commands in `plugins/{name}/commands/{command-name}.md`.

```yaml
---
name: command-name
description: What this command does
argument-hint: "[optional-args]"
allowed-tools: ["Read", "Bash", "Write"]
---
```

### Agents
Autonomous specialists in `plugins/{name}/agents/{agent-name}.md`.

```yaml
---
description: When to invoke this agent
model: sonnet|opus|haiku
color: blue|green|purple
allowed-tools: ["Read", "WebFetch", "Grep"]
---
```

### Hooks
Shell scripts triggered by lifecycle events. Configured in `hooks/hooks.json`:

```json
{
  "hooks": [
    {
      "event": "PreToolUse",
      "name": "my-hook",
      "command": "${CLAUDE_PLUGIN_ROOT}/hooks/my-hook.sh",
      "enabled": true
    }
  ]
}
```

**Hook Events:**
- `SessionStart` / `SessionEnd` - Session lifecycle
- `PreToolUse` / `PostToolUse` - Tool execution (can block with exit code 1)
- `UserPromptSubmit` - Prompt interception

**Hook scripts receive context via stdin as JSON and can:**
- Log information (to stderr for visibility)
- Block operations (exit 1 in PreToolUse)
- Write files for analysis/debugging

## Development Workflow

```bash
# Test entire marketplace
claude --plugin-dir .

# Test specific plugin
claude --plugin-dir plugins/cloudflare-expert
claude --plugin-dir plugins/hooks-lab
```

No build step—changes take effect on new sessions.

### ⚠️ Important: Version Management
**When making changes to any plugin, update the version number in:**
- `plugins/{name}/.claude-plugin/plugin.json` - Plugin version
- `.claude-plugin/marketplace.json` - Corresponding entry in registry

Follow semantic versioning (e.g., 0.1.0 → 0.1.1 for patch, 0.2.0 for minor). This ensures changes are properly tracked and new sessions pick up the latest plugin code.

## Hooks Development

### Testing Hooks Manually
```bash
cd plugins/hooks-lab
echo '{"tool_name":"Bash","parameters":{"command":"ls"}}' | ./hooks/tool-hooks/pre-tool-use.sh
```

### Viewing Hook Logs
```bash
# Daily logs
cat ~/.claude/hooks-lab/logs/$(date +%Y-%m-%d).log

# Tool usage records
cat ~/.claude/hooks-lab/tool-usage-detailed.jsonl

# Session metadata
cat ~/.claude/hooks-lab/sessions/*.json
```

### Hook Script Requirements
- Must be executable (`chmod +x`)
- Parse JSON from stdin using `jq` or bash
- Log to stderr for console visibility
- Exit 0 to allow, exit 1 to block (PreToolUse only)

### Shared Hook Utilities
`hooks/lib/logger.sh` provides color-coded logging functions:
- `log_hook_event` - Hook lifecycle markers
- `log_context` - Key-value context info
- `log_success` / `log_error` - Status messages

Source it in hooks: `source "${CLAUDE_PLUGIN_ROOT}/hooks/lib/logger.sh"`

## File Naming Conventions

| Component | Pattern | Example |
|-----------|---------|---------|
| Skills | `SKILL.md` (uppercase) | `skills/workers/SKILL.md` |
| Commands | `{name}.md` (kebab-case) | `commands/deploy.md` |
| Agents | `{name}.md` (kebab-case) | `agents/docs-specialist.md` |
| Hooks | `{name}.sh` (kebab-case) | `hooks/pre-tool-use.sh` |

## Architecture Patterns

### Content Plugins (cloudflare-expert style)
Use progressive disclosure: SKILL.md → references/ → examples/. Keep main files concise; defer details to subdirectories.

### Behavior Plugins (hooks-lab style)
Organize by hook event type. Share utilities in `hooks/lib/`. Log verbosely during development; reduce in production.

### MCP Integration
Add to `.mcp.json` for external tools:
```json
{
  "mcpServers": {
    "server-name": {
      "url": "https://mcp.example.com/endpoint"
    }
  }
}
```

## Plugin Registry

Register plugins in `.claude-plugin/marketplace.json`:
```json
{
  "plugins": [
    {
      "name": "plugin-name",
      "version": "0.1.0",
      "source": "./plugins/plugin-name"
    }
  ]
}
```
