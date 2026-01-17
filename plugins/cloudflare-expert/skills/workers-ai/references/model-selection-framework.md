# Model Selection Framework

Decision criteria for choosing Workers AI models without hardcoded recommendations. Use these criteria to evaluate models based on your project's specific needs.

## Text Generation Model Criteria

| Criterion | Questions to Ask | Impact on Choice |
|-----------|-----------------|------------------|
| **Context Length** | How much text do I need to process at once? | >32K tokens → need larger context models |
| **Response Speed** | Is latency critical? Real-time chat? | Low latency → smaller models, Mistral |
| **Quality Needs** | Complex reasoning? Creative writing? | High quality → larger parameter models |
| **Language** | English only or multilingual? | Multilingual → Llama 3.1 or Qwen |
| **Cost Sensitivity** | High volume? Budget constraints? | Cost-sensitive → smaller models |

### Decision Flow

```
Is context >32K tokens needed?
├── Yes → Llama 3.1 8B (128K context)
└── No → Is speed critical?
    ├── Yes → Mistral 7B (faster)
    └── No → Is multilingual needed?
        ├── Yes → Llama 3.1 8B or Qwen
        └── No → Mistral 7B for simple, Llama for complex
```

## Embedding Model Criteria

| Criterion | Questions to Ask | Impact on Choice |
|-----------|-----------------|------------------|
| **Dimensions** | What does your Vectorize index support? | Must match index dimensions |
| **Languages** | English only or multilingual? | Multilingual → bge-m3 |
| **Volume** | How many embeddings per second? | High volume → bge-small |
| **Quality** | Retrieval precision critical? | High precision → bge-large |
| **Existing Index** | Is there already a Vectorize index? | Must match existing dimensions |

### Embedding Dimensions Reference

| Model | Dimensions | Use Case |
|-------|------------|----------|
| bge-small-en-v1.5 | 384 | High throughput, cost-sensitive |
| bge-base-en-v1.5 | 768 | Balanced quality/speed |
| bge-large-en-v1.5 | 1024 | Maximum quality |
| bge-m3 | 1024 | Multilingual content |

### Decision Flow

```
Is content multilingual?
├── Yes → bge-m3 (1024 dims)
└── No → Is quality critical?
    ├── Yes → bge-large-en-v1.5 (1024 dims)
    └── No → Is volume very high?
        ├── Yes → bge-small-en-v1.5 (384 dims)
        └── No → bge-base-en-v1.5 (768 dims)
```

## When to Re-evaluate Model Decisions

- **New model releases**: Check Cloudflare docs for new models quarterly
- **Performance issues**: Latency or quality problems
- **Cost changes**: Significant cost increase
- **Requirement changes**: New languages, longer context needs
- **After 90 days**: Routine re-evaluation

## MCP vs Skill Knowledge

| Information Type | Source |
|-----------------|--------|
| Current model list | Docs MCP (always fresh) |
| Model characteristics | Skill (patterns don't change) |
| Performance benchmarks | Docs MCP (may update) |
| Code patterns | Skill (stable) |
| Pricing | Docs MCP (may change) |

## Trade-off Summaries

### Speed vs Quality
- Faster: Smaller models (Mistral 7B, bge-small)
- Higher quality: Larger models (Llama 3.1 8B, bge-large)
- Compromise: Mid-size with quantization (Qwen AWQ)

### Cost vs Performance
- Lower cost: Smaller models, caching, batching
- Better performance: Larger models, more parameters
- Balance: AI Gateway caching + mid-size models

### Simplicity vs Flexibility
- Simple: Use bge-base + Llama 3.1 for everything
- Flexible: Different models per use case
- Trade-off: Maintenance overhead vs optimization

## Recording Decisions

When a model is selected, record in `.claude/cloudflare-expert.local.md`:

```markdown
### Current Model Selections
| Use Case | Model | Rationale | Decided | Re-evaluate By |
|----------|-------|-----------|---------|----------------|
| [your use case] | `[model-id]` | [why this model] | [today] | [+90 days] |
```

This enables:
- Consistent recommendations across sessions
- Decision history tracking
- Planned re-evaluation reminders
