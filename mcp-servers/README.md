# /mcp-servers

Model Context Protocol (MCP) server implementations for the tool integrations the agents call.

## Servers

| Server | Purpose | Subdir |
|--------|---------|--------|
| QBO MCP | Read/write to QuickBooks Online via Intuit API | `/qbo` |
| Double MCP | Close checklist + review workflows on Double | `/double` |
| Audit MCP | Append-only audit log writer (internal) | `/audit` |

## Conventions

- One subdirectory per server, named by the surface it wraps
- Each subdir contains: server entry point, tool definitions, README documenting auth model and rate limits
- Audit MCP is internal only. No third-party data leaves that boundary. Do not add external network calls there.
- QBO and Double MCPs are external. Every call respects the active `client_id` scope.

## Why we host these ourselves

Per the April 2026 Anthropic HIPAA-Ready Implementation Guide, third-party MCPs are not covered under Anthropic's BAA. Self-hosting lets us put each MCP behind our own sanitizer and audit layer.

## Adding a new MCP server

1. Create `/mcp-servers/<name>/` subdir
2. Implement the MCP server in Python or TypeScript
3. Document tools in `<name>/tools.md`
4. Register the server in agent prompts that need it
