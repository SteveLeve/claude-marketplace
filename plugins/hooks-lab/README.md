# Hooks Lab 🧪

**An interactive laboratory for learning Claude Code hooks through verbose, transparent demonstrations**

## Overview

Hooks Lab is a learning-focused plugin that demonstrates every Claude Code hook type with extensive logging, educational explanations, and practical patterns. Perfect for understanding hook lifecycles, exploring context engineering, and building toward sophisticated automation.

## Features

### 📚 Educational Design
- **Verbose logging** with color-coded output
- **Learning objectives** for each hook
- **Step-by-step execution** narration
- **Real-time transparency** into hook lifecycles

### 🎯 Demonstration Hooks

| Hook | Purpose | What You Learn |
|------|---------|----------------|
| **SessionStart** | Session initialization | Context bundling, state setup |
| **SessionEnd** | Session cleanup | Summary generation, analytics |
| **PreToolUse** | Pre-execution validation | Tool interception, input validation |
| **PostToolUse** | Post-execution analysis | Output analysis, pattern detection |
| **UserPromptSubmit** | Prompt interception | Intent detection, context injection |

### 🔬 Learning Modules

1. **Session Lifecycle** - Understand session boundaries and state management
2. **Tool Transparency** - See inside tool execution with validation examples
3. **Context Engineering** - Learn context bundling and injection patterns
4. **Advanced Patterns** - Foundation for async, parallel, and agent-based hooks

## Installation

### Option 1: Via Marketplace (Recommended)

```bash
# In Claude Code session
/plugin marketplace add /path/to/claude-marketplace
/plugin install hooks-lab@steves-claude-marketplace
```

### Option 2: Direct Load

```bash
# Load for single session
claude --plugin-dir /path/to/claude-marketplace/plugins/hooks-lab
```

## Quick Start

### 1. Install the Plugin

Follow installation instructions above.

### 2. Start Claude Code

```bash
cd /your/project
claude --plugin-dir /path/to/hooks-lab
```

You'll immediately see the **SessionStart** hook fire with detailed logging.

### 3. Run a Command

Try a simple command:
```
List the files in the current directory
```

Watch the hooks log:
- **PreToolUse**: Logs the Bash command before execution
- **PostToolUse**: Analyzes the output after execution

### 4. Review the Logs

Check the detailed logs:
```bash
cat ~/.claude/hooks-lab/logs/$(date +%Y-%m-%d).log
```

### 5. Explore Hook Data

```bash
# View session metadata
cat ~/.claude/hooks-lab/sessions/*.json

# View tool usage stats
cat ~/.claude/hooks-lab/tool-usage-detailed.jsonl

# Read session summary
cat ~/.claude/hooks-lab/session-summary.txt
```

## What Gets Logged

### Console Output (Colorized)
Every hook prints educational information to your terminal:
- 🟣 Hook lifecycle events
- 🔵 Learning objectives and steps
- 🟢 Success messages
- 🟡 Validation warnings
- 🔴 Errors or dangerous operations
- ⚪ Contextual details

### Log Files
```
~/.claude/hooks-lab/
├── logs/YYYY-MM-DD.log           # Daily detailed logs
├── sessions/session-*.json       # Session metadata
├── session-context.json          # Current session context
├── session-summary.txt           # Last session summary
├── tool-usage.log                # Simple usage log
├── tool-usage-detailed.jsonl     # Detailed execution records
└── prompts.jsonl                 # Prompt metadata (privacy-safe)
```

## Learning Path

### 🟢 Beginner: Session Lifecycle
1. Start Claude Code with hooks-lab
2. Observe SessionStart logging
3. Do some work
4. Exit and review SessionEnd summary
5. Read session metadata files

**Goal**: Understand when sessions begin/end and what context is available.

### 🟡 Intermediate: Tool Transparency
1. Run various commands (Read, Write, Bash, Grep)
2. Watch PreToolUse validate inputs
3. Watch PostToolUse analyze outputs
4. Check tool-usage-detailed.jsonl
5. Study validation logic in hook scripts

**Goal**: See inside tool execution and learn validation patterns.

### 🔴 Advanced: Context Engineering
1. Submit different types of prompts
2. Watch UserPromptSubmit detect intent
3. See available context (git, projects, files)
4. Understand injection opportunities
5. Modify hooks to inject custom context

**Goal**: Master context bundling and prompt enhancement.

### 🔮 Expert: Build Your Own
1. Modify validation rules in PreToolUse
2. Add automated actions in PostToolUse
3. Inject custom context in UserPromptSubmit
4. Create new hooks for specific workflows
5. Design agent-based or async patterns

**Goal**: Build production-ready hooks for your workflow.

## Hook Scripts

All hook scripts are extensively documented and designed for learning:

```
hooks/
├── hooks.json                    # Hook configuration
├── session-hooks/
│   ├── session-start.sh         # Session initialization demo
│   └── session-end.sh           # Session cleanup demo
├── tool-hooks/
│   ├── pre-tool-use.sh          # Pre-execution transparency
│   └── post-tool-use.sh         # Post-execution analysis
├── prompt-hooks/
│   └── user-prompt-submit.sh    # Prompt interception demo
└── lib/
    ├── logger.sh                # Verbose logging utilities
    └── context-builder.sh       # Context bundling utilities
```

Each script includes:
- Learning objectives
- Step-by-step narration
- Extensive comments
- Example patterns
- Color-coded output

## Customization

### Enable/Disable Hooks

Edit `hooks/hooks.json`:
```json
{
  "hooks": [
    {
      "event": "PreToolUse",
      "name": "pre-tool-transparency",
      "enabled": false  // Disable this hook
    }
  ]
}
```

### Modify Validation Rules

Edit `hooks/tool-hooks/pre-tool-use.sh`:
```bash
# Add custom validation
if [[ "${tool_name}" == "Write" ]]; then
    file_path=$(echo "${hook_context}" | jq -r '.parameters.file_path')

    # Block writes to production config
    if [[ "${file_path}" == *"production.json" ]]; then
        log_error "Blocked: Cannot modify production config"
        exit 1  # This blocks the tool execution
    fi
fi
```

### Add Automation

Edit `hooks/tool-hooks/post-tool-use.sh`:
```bash
# Auto-format TypeScript files after writing
if [[ "${tool_name}" == "Write" ]] && [[ "${file_path}" == *.ts ]]; then
    prettier --write "${file_path}"
    log_success "Auto-formatted ${file_path}"
fi
```

### Inject Context

Edit `hooks/prompt-hooks/user-prompt-submit.sh`:
```bash
# Inject coding standards when user asks to write code
if echo "${user_prompt}" | grep -qi "write.*code"; then
    if [[ -f "CODING_STANDARDS.md" ]]; then
        # Read and inject standards
        standards=$(cat CODING_STANDARDS.md)
        # (Advanced: requires prompt modification support)
    fi
fi
```

## Documentation

- **[Learning Guide](docs/LEARNING-GUIDE.md)** - Comprehensive learning path and concepts
- **[Hook Lifecycle](docs/HOOK-LIFECYCLE.md)** - Visual lifecycle diagrams
- **[Advanced Patterns](docs/ADVANCED-PATTERNS.md)** - Future: async, parallel, agents

## Use Cases

### Learning & Education
- Understand Claude Code internals
- Learn hook patterns before building production hooks
- Experiment safely with verbose feedback

### Development & Debugging
- Debug hook configurations
- Test validation logic
- Prototype automation workflows

### Transparency & Auditing
- See exactly what tools Claude uses
- Track tool usage patterns
- Monitor session activities

### Context Engineering Research
- Explore context bundling strategies
- Experiment with prompt enhancement
- Study intent detection patterns

## Privacy & Security

### What Gets Logged
- ✅ Hook lifecycle events
- ✅ Tool names and parameters
- ✅ Execution results and timing
- ✅ Environment context (working dir, git branch)
- ✅ Prompt metadata (length, detected intent)

### What Doesn't Get Logged
- ❌ Full prompt content (only metadata)
- ❌ Sensitive parameter values (filtered)
- ❌ File contents (only paths and sizes)

### Security Considerations
- All hooks run in learning mode (don't block by default)
- To enable blocking, modify hook scripts explicitly
- Review hook scripts before enabling validation
- Logs are stored locally in `~/.claude/hooks-lab/`

## Requirements

- Claude Code CLI installed
- Bash shell (4.0+)
- `jq` (optional but recommended for better JSON parsing)
  ```bash
  # Install jq
  # macOS
  brew install jq

  # Ubuntu/Debian
  sudo apt-get install jq

  # Fedora
  sudo dnf install jq
  ```

## Troubleshooting

### Hooks Not Executing
```bash
# Check scripts are executable
chmod +x hooks/**/*.sh

# Verify hooks.json is valid
jq . hooks/hooks.json

# Check plugin is loaded
/plugin list
```

### Logs Not Appearing
```bash
# Check log directory
ls -la ~/.claude/hooks-lab/logs/

# Test hook manually
cd plugins/hooks-lab
echo '{}' | ./hooks/session-hooks/session-start.sh
```

### Permission Errors
```bash
# Fix permissions
chmod +x hooks/lib/*.sh
chmod +x hooks/**/*.sh
```

## Roadmap

- [x] SessionStart/SessionEnd hooks
- [x] PreToolUse/PostToolUse hooks
- [x] UserPromptSubmit hook
- [x] Verbose logging system
- [x] Context bundling utilities
- [x] Learning documentation
- [ ] Hook lifecycle visualization
- [ ] Advanced async patterns
- [ ] Agent-based hook examples
- [ ] Parallel hook execution demos
- [ ] Web dashboard for analytics

## Contributing

This plugin is part of a personal learning lab, but contributions are welcome!

Ideas for contributions:
- Additional validation patterns
- New context injection strategies
- Performance optimizations
- Analytics visualizations
- Advanced pattern demonstrations

## License

MIT

## Author

Steve Leve (steve.e.leve@gmail.com)

---

**🧪 Start Learning Today!**

The best way to understand Claude Code hooks is to see them in action. Install hooks-lab, start a session, and watch the verbose logs reveal exactly what's happening at each stage of the lifecycle.

```bash
claude --plugin-dir /path/to/hooks-lab
```

Every hook execution is an opportunity to learn! 🚀
