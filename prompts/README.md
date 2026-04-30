# /prompts

System prompts for each agent in the Reciprocity AI Bookkeeper stack.

## Convention

- One Markdown file per agent: `agent_<role>.md`
- Files in this directory are the source of truth. The Agent SDK or Power Automate flow reads from here.
- No prompts in code. Prompts live here, code references them.

## Required structure for every prompt

1. **Role and scope.** What this agent does, what it does not do.
2. **Tools available.** Explicit list of MCP tools the agent may call.
3. **Compliance block.** Paste from `/compliance/agent_compliance_block.md`. Do not paraphrase.
4. **Output contract.** Exactly what the agent returns and in what shape.

## Active agents

| Agent | Status | File |
|-------|--------|------|
| Production JE | scaffolding | `agent_production.md` |
| Collections JE | planned | `agent_collections.md` |
| Expenses + Payroll | planned | `agent_expenses.md` |
| Close Coordinator + Memory | planned | `agent_close_coordinator.md` |

See `/docs/ai_agent_architecture.md` for the agent design.
