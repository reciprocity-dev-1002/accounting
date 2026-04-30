# /compliance

SOC 2 Lite tiered compliance controls and supporting documentation for the Reciprocity AI Bookkeeper.

## Tier model

Compliance posture earns in over time. Architectural controls land day one. Operational rigor lands at scale triggers.

| Tier | Trigger | Examples |
|------|---------|----------|
| 0 — Day 1 | First line of code | MFA on accounts, RLS on every table, append-only audit tables, `agent_compliance_block.md` in every prompt |
| 1 — Phase 1 Agents Live | Real client data flows to Claude | PHI sanitizer live, `agent_actions` table active, immutable cold backups |
| 2 — Pod 1 Forming | Humans other than Greg touch client data | RBAC matrix, weekly incident review, monthly compliance summary, quarterly credential rotation |
| 3 — Formal SOC 2 Type II | White-label or enterprise DSO prospect demands it | Third-party audit, documented procedures with evidence, annual penetration test |

## Anti-theater rule

Don't fabricate process for an audience of one. A weekly incident review of your own work with yourself as the only reviewer is theater. Wait for the audience to exist before instituting the cadence. Logs are still captured at Tier 1. The cadence waits until Tier 2.

## Files

- `agent_compliance_block.md` — non-negotiable constraints pasted into every agent prompt (Tier 0)
- `incidents/` — incident log entries (Tier 1+, files start landing here when Phase 1 agents go live)
- `monthly_reviews/` — monthly compliance summaries (Tier 2+, do not start until Pod 1 forms)

## Why no Anthropic BAA in 2026

The PHI sanitizer architecture means Anthropic never sees PHI, which means Anthropic is not a Business Associate, which means no BAA is required. HIPAA-Ready Enterprise is approximately $50K/year minimum, sales-assisted only. Re-evaluate Q4 2026.

See architecture decisions doc for the full reasoning.
