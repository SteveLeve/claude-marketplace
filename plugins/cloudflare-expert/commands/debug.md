---
name: debug
description: Debug production issues by querying Worker logs and analyzing errors using the Cloudflare Observability MCP
argument-hint: "[--worker <name>] [--timeframe <duration>] [--errors-only]"
allowed-tools: ["Read", "Grep", "Glob",
  "mcp__cloudflare-observability__query_worker_observability",
  "mcp__cloudflare-observability__observability_keys",
  "mcp__cloudflare-observability__observability_values",
  "mcp__cloudflare-observability__workers_list",
  "mcp__cloudflare-observability__workers_get_worker"]
---

# Debug Production Issues

Interactive debugging workflow for diagnosing production issues with Cloudflare Workers.

## What This Command Does

1. **Identifies the Worker**: Determines which Worker to debug
2. **Queries Logs**: Fetches recent logs and errors from production
3. **Analyzes Patterns**: Looks for common error patterns and performance issues
4. **Provides Diagnosis**: Explains what went wrong and suggests fixes
5. **Offers Follow-up**: Enables deeper investigation as needed

## Arguments

- `--worker <name>`: Worker name to debug (optional, will list if not provided)
- `--timeframe <duration>`: Time range to analyze (default: 1h)
  - Examples: `15m`, `1h`, `6h`, `24h`, `7d`
- `--errors-only`: Only show errors, not all logs

## Process

### Step 1: Identify Worker

If `--worker` not provided:
1. List all Workers using `workers_list`
2. Ask user to select which Worker to debug
3. Confirm the Worker exists using `workers_get_worker`

If `--worker` provided:
1. Verify the Worker exists
2. Show basic Worker info (bindings, routes)

### Step 2: Initial Error Scan

Query for recent errors:

```json
{
  "view": "events",
  "queryId": "error-scan",
  "limit": 10,
  "parameters": {
    "filters": [
      {
        "key": "$metadata.service",
        "operation": "eq",
        "type": "string",
        "value": "[WORKER_NAME]"
      },
      {
        "key": "$metadata.error",
        "operation": "exists",
        "type": "string"
      }
    ]
  },
  "timeframe": {
    "reference": "now",
    "offset": "-[TIMEFRAME]"
  }
}
```

Display results in readable format:
- Timestamp
- Error message
- Request path (if available)
- Request ID for follow-up

### Step 3: Error Aggregation

If errors found, aggregate by type:

```json
{
  "view": "calculations",
  "queryId": "error-aggregation",
  "parameters": {
    "calculations": [
      { "operator": "count", "alias": "count" }
    ],
    "groupBys": [
      { "type": "string", "value": "$metadata.error" }
    ],
    "limit": 5,
    "orderBy": { "value": "count", "order": "desc" }
  }
}
```

Show:
- Most common error types
- Error counts
- Percentage of total errors

### Step 4: Performance Overview

If not `--errors-only`, check performance:

```json
{
  "view": "calculations",
  "queryId": "performance-overview",
  "parameters": {
    "calculations": [
      { "operator": "count", "alias": "total_requests" },
      { "operator": "avg", "key": "$metadata.wallTime", "keyType": "number", "alias": "avg_latency" },
      { "operator": "p99", "key": "$metadata.wallTime", "keyType": "number", "alias": "p99_latency" }
    ]
  }
}
```

Show:
- Total request count
- Average latency
- P99 latency
- Error rate (if applicable)

### Step 5: Provide Analysis

Based on findings, provide:

**If errors found**:
- Most common error type explained
- Likely root cause
- Suggested fixes
- Example error details

**If slow performance**:
- Latency breakdown
- Potential bottlenecks
- Optimization suggestions

**If all healthy**:
- Confirmation of healthy state
- Recent traffic summary

### Step 6: Offer Follow-up Actions

Ask user what they want to do next:
1. "See more details about a specific error?"
2. "Check performance by endpoint?"
3. "Compare to previous time period?"
4. "Look at logs around a specific time?"

## Example Output

```
Debug Report for Worker: my-api-worker
Timeframe: Last 1 hour
─────────────────────────────────────

ERRORS (3 found)
├── TypeError: Cannot read property 'id' of undefined (2x)
│   └── Last seen: 5 minutes ago
│   └── Endpoint: POST /api/users
│
└── D1 Error: UNIQUE constraint failed (1x)
    └── Last seen: 23 minutes ago
    └── Endpoint: POST /api/users

PERFORMANCE
├── Total Requests: 1,234
├── Avg Latency: 45ms
├── P99 Latency: 234ms
└── Error Rate: 0.24%

DIAGNOSIS
The TypeError suggests null-checking is missing in the POST /api/users
handler. The D1 constraint error indicates a duplicate key insertion
attempt - likely a race condition or retry logic issue.

RECOMMENDED ACTIONS
1. Add null check: Verify request body contains 'id' before accessing
2. Handle constraint errors: Use INSERT OR IGNORE or try/catch with
   appropriate error message
```

## Timeframe Parsing

Parse user-provided timeframes:
- `15m` → last 15 minutes
- `1h` → last 1 hour (default)
- `6h` → last 6 hours
- `24h` or `1d` → last day
- `7d` → last week (maximum)

## Error Categories to Look For

1. **Runtime Errors**: TypeError, ReferenceError, SyntaxError
2. **Binding Errors**: D1, KV, R2, Vectorize access issues
3. **Network Errors**: Fetch failures, timeout issues
4. **AI Errors**: Workers AI inference failures
5. **Auth Errors**: Permission denied, invalid token

## Integration

This command uses the observability-specialist agent capabilities directly. For complex investigations, the full agent may be invoked.

## Important Notes

- Maximum queryable timeframe is 7 days
- Large result sets are automatically paginated
- Request IDs can be used for detailed investigation
- Performance queries may take a few seconds for large datasets
