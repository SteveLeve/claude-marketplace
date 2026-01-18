# Steve's Claude Code Plugin Marketplace

A personal plugin marketplace for Claude Code development, featuring curated plugins for learning context engineering and agentic development patterns.

## Overview

This marketplace serves as both a learning environment and a toolkit for Claude Code plugin development. It follows a monorepo structure to enable rapid experimentation while maintaining clear plugin boundaries.

## Structure

```
claude-marketplace/
├── .claude-plugin/
│   └── marketplace.json     # Marketplace registry
├── plugins/                 # Individual plugins
│   ├── cloudflare-expert/   # Cloudflare Developer Platform plugin
│   └── hooks-lab/           # Hooks learning laboratory
└── CLAUDE.md                # Guide for Claude Code instances
```

## Plugins

### cloudflare-expert (v0.1.3)

Cloudflare Developer Platform Expert - Comprehensive guidance for building on Cloudflare Workers, platform products, and Workers AI.

**Features:**
- 7 auto-activating skills (Workers development, Wrangler workflows, Platform products, Workers AI, Deployment strategies, Workflows patterns, Frameworks integration)
- 3 workflow commands (/cloudflare:dev, /cloudflare:deploy, /cloudflare:debug)
- 4 specialized agents (docs specialist, workers specialist, AI specialist, observability specialist)
- MCP integration with Cloudflare documentation and observability APIs
- Living memory system for project-specific knowledge

**Installation:**
```bash
# Load specific plugin
claude --plugin-dir /path/to/claude-marketplace/plugins/cloudflare-expert

# Or install from marketplace
/plugin marketplace add /path/to/claude-marketplace
/plugin install cloudflare-expert@steves-claude-marketplace
```

### hooks-lab (v0.1.0)

Interactive laboratory for learning Claude Code hooks through verbose, transparent demonstrations.

**Features:**
- 5 demonstration hooks (SessionStart, SessionEnd, PreToolUse, PostToolUse, UserPromptSubmit)
- Verbose, color-coded logging with educational explanations
- Context bundling and analysis utilities
- Comprehensive learning documentation
- Data collection for analytics and pattern study

**Installation:**
```bash
# Load specific plugin
claude --plugin-dir /path/to/claude-marketplace/plugins/hooks-lab

# Or install from marketplace
/plugin marketplace add /path/to/claude-marketplace
/plugin install hooks-lab@steves-claude-marketplace
```

**What You'll Learn:**
- Hook lifecycle and execution flow
- Tool interception and validation patterns
- Context engineering and injection techniques
- Session state management
- Building production-ready automation

## Usage

### Testing the Marketplace
```bash
# Test all plugins in marketplace
cd /path/to/claude-marketplace
cc --plugin-dir .

# Test specific plugin
cc --plugin-dir ./plugins/cloudflare-expert
```

### Adding New Plugins

1. Create plugin directory: `plugins/your-plugin-name/`
2. Add plugin manifest: `plugins/your-plugin-name/.claude-plugin/plugin.json`
3. Develop plugin components (skills, commands, agents)
4. Register in marketplace: Edit `.claude-plugin/marketplace.json`

## Development Philosophy

This marketplace emphasizes:
- **Experimentation**: Rapid iteration on plugin patterns
- **Context Engineering**: Exploring how context flows through plugins
- **Agentic Development**: Building autonomous, specialized agents
- **Progressive Disclosure**: Layered information architecture

## Roadmap

- [x] Cloudflare Developer Platform plugin
- [x] Hooks experimentation plugin (hooks-lab)
- [ ] Advanced hooks patterns (async, parallel, agent-based)
- [ ] Shared utilities library
- [ ] Plugin development toolkit

## References

- [Claude Code Documentation](https://code.claude.com/docs)
- [Plugin Marketplace Guide](https://code.claude.com/docs/en/plugin-marketplaces)
- [Plugin Development Guide](https://code.claude.com/docs/en/plugins)

## License

MIT
