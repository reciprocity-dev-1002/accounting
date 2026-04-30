# /schema

PostgreSQL schema migrations for the Reciprocity AI Bookkeeper stack on Supabase.

## Conventions

- One file per migration, numbered in order of application: `0001_initial.sql`, `0002_clients.sql`, etc.
- Each migration is idempotent where reasonable (use `CREATE TABLE IF NOT EXISTS`, etc.)
- Every multi-tenant table includes a `client_id uuid NOT NULL` column
- Every table has Row Level Security ENABLED (auto-enforced by event trigger on the project)
- Every table has at least one RLS policy before being shipped (empty RLS = inaccessible)

## Tier 0 controls (SOC 2 Lite)

- RLS on every table from day one
- `agent_actions`, `je_history`, `incidents` tables are append-only (UPDATE/DELETE revoked from service role)
- All tables encrypted at rest (Supabase default)

## Applying migrations

Two paths:

1. **Supabase MCP** (preferred): apply via `apply_migration` tool from Claude
2. **Manual**: paste SQL into Supabase SQL Editor, or run via `supabase db push`

See `/docs/ai_agent_architecture.md` for the full schema model.
