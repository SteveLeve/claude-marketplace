# Hooks Lab Learning Guide

## Welcome to the Hooks Laboratory! 🧪

This plugin is designed to help you understand Claude Code hooks through **verbose, transparent demonstrations**. Every hook logs its lifecycle, decisions, and learning opportunities in real-time.

## What You'll Learn

### 1. Hook Lifecycle Understanding
- **When** each hook type fires
- **What** context is available at each point
- **How** hooks receive and process information
- **Why** certain patterns are useful

### 2. Hook Types and Their Purposes

| Hook Event | Fires When... | Use Cases |
|------------|---------------|-----------|
| **SessionStart** | Claude Code session begins | Initialize state, capture context, set up environment |
| **SessionEnd** | Claude Code session ends | Save state, generate summaries, cleanup |
| **PreToolUse** | Before any tool executes | Validate inputs, log intentions, block dangerous ops |
| **PostToolUse** | After a tool completes | Analyze results, log outputs, trigger follow-ups |
| **UserPromptSubmit** | User submits a prompt | Analyze intent, inject context, enhance prompts |

### 3. Practical Patterns
- **Transparency**: See exactly what's happening at each hook point
- **Validation**: Learn how to inspect and validate tool inputs
- **Context Bundling**: Understand how to capture and use environment context
- **Follow-up Actions**: Discover how to trigger automated workflows

## Learning Methodology

### Observe Through Logs

All hook executions are logged to:
```
~/.claude/hooks-lab/logs/YYYY-MM-DD.log
```

The logs use color-coding:
- 🟣 **MAGENTA**: Hook lifecycle events
- 🔵 **CYAN**: Learning explanations and steps
- 🟢 **GREEN**: Successful operations
- 🟡 **YELLOW**: Warnings and validations
- 🔴 **RED**: Errors or dangerous operations
- ⚪ **GRAY**: Detailed contextual information

### Progressive Learning Path

#### Level 1: Session Lifecycle (Beginner)
**Goal**: Understand session boundaries

**Hooks to study**:
- `SessionStart` - Start a Claude Code session and watch the logs
- `SessionEnd` - End the session and review the summary

**What to observe**:
- When sessions start/end
- What context is captured
- How state is initialized and cleaned up

**Try this**:
1. Start Claude Code with hooks-lab installed
2. Watch for the SessionStart output in your terminal
3. Do some work (run a few commands)
4. Exit Claude Code and see the SessionEnd summary

#### Level 2: Tool Transparency (Intermediate)
**Goal**: See inside tool execution

**Hooks to study**:
- `PreToolUse` - Fires before each tool
- `PostToolUse` - Fires after each tool

**What to observe**:
- Tool names and parameters
- Validation logic in action
- Output analysis patterns
- Performance tracking

**Try this**:
1. Run a simple command: "List files in the current directory"
2. Watch PreToolUse log what Bash command is about to execute
3. Watch PostToolUse analyze the command output
4. Check `~/.claude/hooks-lab/tool-usage-detailed.jsonl` for records

#### Level 3: Context Engineering (Advanced)
**Goal**: Learn context injection patterns

**Hooks to study**:
- `UserPromptSubmit` - Fires when you submit prompts

**What to observe**:
- Intent detection patterns
- Available context (git, project files, etc.)
- Injection opportunities
- Privacy considerations

**Try this**:
1. Submit a prompt: "Explain this code"
2. Watch the hook analyze your intent (explanation pattern)
3. See what context it identifies (git branch, project type, etc.)
4. Understand where context could be injected

#### Level 4: Building Useful Tools (Expert)
**Goal**: Apply hook patterns to real problems

**Concepts to explore**:
- Validation: Block dangerous operations
- Automation: Trigger workflows (tests, formatting)
- Safety: Add guardrails to tool usage
- Intelligence: Context-aware enhancements

**Try this**:
1. Modify a hook to actually block something (change `exit 0` to `exit 1`)
2. Add your own validation logic
3. Inject custom context into prompts
4. Build a follow-up action (e.g., run tests after code changes)

## Hook Anatomy

Every hook in this lab follows the same structure:

```bash
#!/usr/bin/env bash

# 1. Setup
set -euo pipefail
source "${SCRIPT_DIR}/../lib/logger.sh"
source "${SCRIPT_DIR}/../lib/context-builder.sh"

# 2. Read hook context from stdin
hook_context=$(cat)

# 3. Log learning objectives
log_message "LEARNING" "What this hook teaches..."

# 4. Parse and analyze the context
# Use jq to extract relevant fields
tool_name=$(echo "${hook_context}" | jq -r '.tool')

# 5. Make decisions or take actions
# Example: validate, log, inject context

# 6. Exit with appropriate code
# exit 0 = allow/success
# exit 1 = block/failure (for validation hooks)
exit 0
```

## Hook Context Structure

Each hook receives a JSON object via stdin with different fields:

### SessionStart
```json
{
  "event": "SessionStart",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### SessionEnd
```json
{
  "event": "SessionEnd",
  "timestamp": "2025-01-15T11:45:00Z",
  "duration_ms": 4500000
}
```

### PreToolUse
```json
{
  "event": "PreToolUse",
  "tool": "Bash",
  "parameters": {
    "command": "ls -la",
    "description": "List files"
  }
}
```

### PostToolUse
```json
{
  "event": "PostToolUse",
  "tool": "Bash",
  "success": true,
  "output": "...",
  "error": null,
  "duration_ms": 45
}
```

### UserPromptSubmit
```json
{
  "event": "UserPromptSubmit",
  "prompt": "Explain how this works",
  "timestamp": "2025-01-15T10:35:00Z"
}
```

## Data Storage

Hooks lab creates several files for learning and analysis:

```
~/.claude/hooks-lab/
├── logs/
│   └── YYYY-MM-DD.log              # Daily verbose logs
├── sessions/
│   └── session-1234567890.json     # Session metadata
├── session-context.json             # Current session context bundle
├── session-summary.txt              # Last session summary
├── tool-usage.log                   # Simple tool usage log
├── tool-usage-detailed.jsonl        # Detailed tool execution records
└── prompts.jsonl                    # Prompt metadata (privacy-safe)
```

**Privacy Note**: Prompts are logged as metadata only (length, intent), not full content.

## Experimentation Ideas

### 1. Add Custom Validation
Edit `pre-tool-use.sh` to add your own validation rules:
```bash
# Block writing to certain directories
if [[ "${tool_name}" == "Write" ]]; then
    file_path=$(echo "${hook_context}" | jq -r '.parameters.file_path')
    if [[ "${file_path}" == /etc/* ]]; then
        log_error "Blocked: Cannot write to /etc/"
        exit 1  # Block the operation
    fi
fi
```

### 2. Auto-Format After Writes
Edit `post-tool-use.sh` to trigger formatting:
```bash
# Auto-format JavaScript files after writing
if [[ "${tool_name}" == "Write" ]] && [[ "${file_path}" == *.js ]]; then
    prettier --write "${file_path}"
    log_success "Auto-formatted ${file_path}"
fi
```

### 3. Context Injection
Edit `user-prompt-submit.sh` to inject README content:
```bash
# Inject README when user asks about the project
if echo "${user_prompt}" | grep -qi "what is this project"; then
    if [[ -f "README.md" ]]; then
        readme_content=$(cat README.md)
        # Append to prompt (advanced - requires prompt modification support)
        echo "Additional context: ${readme_content}"
    fi
fi
```

### 4. Session Analytics
Build a simple analytics dashboard:
```bash
# Count tool usage
jq -r '.tool' ~/.claude/hooks-lab/tool-usage-detailed.jsonl | \
    sort | uniq -c | sort -rn

# Most active days
ls ~/.claude/hooks-lab/logs/ | sort
```

## Advanced Patterns (Future)

The hooks lab is designed to evolve toward advanced patterns:

### Async Hooks
Execute long-running tasks without blocking:
```bash
# Run expensive operation in background
(expensive_analysis) &
exit 0  # Don't block Claude
```

### Parallel Hooks
Multiple hooks for the same event:
```json
{
  "event": "PreToolUse",
  "hooks": [
    {"name": "validator", "command": "validate.sh"},
    {"name": "logger", "command": "log.sh"},
    {"name": "metrics", "command": "metrics.sh"}
  ]
}
```

### Agent-Based Hooks
Use Claude agents to make intelligent decisions:
```bash
# Invoke a specialized agent for complex validation
claude-agent validate-code --context "${hook_context}"
```

## Troubleshooting

### Hooks not executing?
1. Check hooks are executable: `ls -la plugins/hooks-lab/hooks/**/*.sh`
2. Check hooks.json is valid JSON: `jq . plugins/hooks-lab/hooks/hooks.json`
3. Check Claude Code recognizes the plugin: `/plugin list`

### Logs not appearing?
1. Check log directory exists: `ls -la ~/.claude/hooks-lab/logs/`
2. Check hook is enabled in hooks.json: `"enabled": true`
3. Run hook manually to test: `./hooks/session-hooks/session-start.sh`

### Permission errors?
1. Make scripts executable: `chmod +x hooks/**/*.sh`
2. Check file permissions: `ls -la hooks/`

## Next Steps

1. **Install hooks-lab**: Add to your Claude Code plugins
2. **Start a session**: Watch SessionStart fire
3. **Run some commands**: Observe PreToolUse and PostToolUse
4. **Review logs**: Study the verbose output
5. **Modify hooks**: Experiment with validation or automation
6. **Build your own**: Create custom hooks for your workflow

## Resources

- [Claude Code Hooks Documentation](https://code.claude.com/docs/en/hooks)
- Hook scripts source: `plugins/hooks-lab/hooks/`
- Shared utilities: `plugins/hooks-lab/hooks/lib/`
- Example implementations in each hook file

---

**Happy Learning!** 🧪

The best way to learn hooks is to watch them work. Start Claude Code with hooks-lab installed and observe every step of the lifecycle through verbose, color-coded logs.
