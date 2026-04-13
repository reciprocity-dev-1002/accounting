# Reciprocity AI Bookkeeper — Year 1 Build Plan

**Status:** Active | **Budget:** ~9 hrs/week (20-25% of Greg's time) | **Horizon:** April 2026 → April 2027
**Companion doc:** [`ai_agent_architecture.md`](ai_agent_architecture.md) — the *what*. This doc is the *when* and *how-am-I-spending-my-week*.

---

## How to use this doc

1. **Monday (1 hr) — read the top:** Scan "Current Status" + "This Week's Active Build Queue". Pick the 1-2 things that actually move the needle. Add a TODO to your planner.
2. **Work sessions (Tue/Thu, 2 hr each) — drive one item to done:** Open Claude in this folder. Paste the item. Work it to done. Check it off the queue.
3. **Wednesday (1 hr) — domain braindump:** Voice-memo or write the accounting rules for whatever's next. Feed to Claude.
4. **Friday (2 hr) — QA + update:** Walk Smile4Me's auto-posted week. Red-line errors. Update "Current Status" at top of this doc. Move completed items to "Done this week."
5. **End of quarter — roll the plan:** Check milestone progress. Update the Quarterly Milestones section.
6. **Anytime you make an architectural decision:** log it in the "Decision Log" at the bottom with the date. Future-you and future-Claude-sessions will thank present-Greg.

---

## Current Status *(update weekly)*

**Week of:** April 13, 2026
**Phase:** Phase 0 — Foundation
**Smile4Me status:** Still manual bookkeeping (IG). No agents live yet.
**Biggest unknown this week:** Supabase HIPAA add-on pricing (awaiting quote from sales)
**Greg's block this week:** Selling / client work — primary focus is commercialization
**Next architectural decision needed:** Confirm standardized COA is locked vs Smile4Me's current QBO COA

### Health Indicators *(traffic-light each Friday)*
- **On pace for Q1 milestones?** 🟡 In planning, no build started
- **9 hrs/week actually allocated?** 🟡 This is week 1 of the rhythm — prove it
- **Blockers > 1 week old?** None yet
- **Last shadow-mode QA pass?** N/A (agents not live)

---

## Weekly Rhythm — The 9-Hour Template

| Day | Time | Block | Output |
|---|---|---|---|
| Mon | 1 hr | Plan | Read this doc → pick 1-2 queue items → add to calendar |
| Tue | 2 hr | Build session w/ Claude | Drive one queue item to done |
| Wed | 1 hr | Domain braindump | Accounting rules for next agent/prompt |
| Thu | 2 hr | Build session w/ Claude | Drive next queue item to done |
| Fri | 2 hr | QA + update | Walk prior-week agent output, update this doc |
| **Rolling** | 1 hr | Relationships | Double CSM, Supabase, IG, prospect adjacents |

**Rules:**
- Protect these hours. Put them on the calendar as "Reciprocity Build — DO NOT SCHEDULE." Nothing breaks this block except an active client fire.
- Do NOT write code yourself. Claude writes. You review + decide.
- Do NOT chase every edge case before shipping. Ship the 80%. Use shadow mode to discover the 20%. Feed back via `corrections` table.
- If a session goes over budget, stop and log WHY in the Decision Log. Don't just steal the time from next week.

---

## Quarterly Milestones

### Q1 — April - June 2026: Foundation (Phase 0 + start Phase 1)

**Done = these statements are true:**
- Supabase project stood up (Team + HIPAA add-on) with full schema + RLS policies
- Per-client Anthropic Credential Vault for Smile4Me populated
- Standardized COA locked, reconciled against Smile4Me's QBO
- Git repo `reciprocity-dev-1002/accounting` has agent prompts, schema SQL, MCP server stubs
- PHI sanitizer implemented and unit-tested
- QBO MCP server (thin wrapper) running in sandbox
- Double MCP server v1 with `list_tasks`, `mark_task_complete`, `post_note` working against Smile4Me (client 604199)
- Production Specialist agent running against Smile4Me data in shadow mode (entries proposed, not posted)

### Q2 — July - September 2026: Go-live Phase (Phase 2 + 3)

**Done = these statements are true:**
- Smile4Me Production + Collections agents auto-posting at 95%+ confidence
- Expenses & Payroll agents running in shadow mode for Smile4Me
- First full month-end close run by Close Coordinator (with Greg reviewing every entry)
- IG staff (Drashti + Jehal) have transitioned to QA/shadow reviewers instead of primary bookkeepers
- First external prospect seen a demo of the system (sales leverage)

### Q3 — October - December 2026: Second Client (Phase 4)

**Done = these statements are true:**
- Client #2 signed + onboarded through the templated process in 4 hours of Greg time
- Anything Smile4Me-hardcoded has been refactored
- Client #2 running in shadow mode on all rocks
- Correction log has 100+ entries feeding Agent 8
- Decision: domestic sr accountant hire OR extend IG Pod model

### Q4 — January - April 2027: Scale (Phase 5)

**Done = these statements are true:**
- 5-10 clients live with auto-posting
- First sr accountant hired or IG Pod formalized
- Monthly compliance summary (Tier 2 control) running
- Gross margin ≥ 90% at this scale confirmed in actual P&L
- Year-end decision on pursuing SOC 2 Type II (Tier 3) — yes/no/when

---

## Month-by-Month Build Sequence

### April 2026
- Stand up Supabase (Team + HIPAA add-on confirmed)
- Initial schema commit: `clients`, `agent_actions`, `source_documents`, `je_history`, `corrections`, `incidents` + RLS policies
- Smile4Me Anthropic Credential Vault populated
- Audit & reconcile Smile4Me QBO COA vs master standardized COA
- Pull Double `HookType` schema from Swagger
- Confirm multi-practice OAuth question with Double CSM

### May 2026
- QBO MCP server (custom thin wrapper) built + running in sandbox
- PHI sanitizer implemented (Python, Power Automate pre-processing)
- Production Specialist agent prompt written + tested against last-month Smile4Me data
- Double MCP server v1 (`list_tasks`, `mark_task_complete`, `post_note`)
- Greg weekly reviews using the real Tier 1 `agent_actions` log (not yet auto-posting, just seeing what agent would propose)

### June 2026
- Collections Specialist agent built (three-bucket logic: insurance/patient/financing)
- Shadow-mode accuracy pass: 2 weeks of Smile4Me data, Greg scores each entry
- First IG SOP review (Drashti & Jehal walkthrough of what agents are doing)

### July 2026
- **Smile4Me cutover to live:** Production & Collections agents auto-post at 95%+ confidence
- Expenses agent built (receipt matching + QBO attachment)
- Payroll Accrual agent built (biweekly straddle logic)

### August 2026
- Expenses & Payroll agents cutover to live for Smile4Me
- Close Coordinator agent built (13-step orchestration)
- First agent-run month-end close (July books), Greg reviews every entry

### September 2026
- August close: agent-run with flagged-entry review only (target: <10% flagged)
- Reach Reporting KPI dashboard auto-refresh wired up
- Monarch replacement dashboard built

### October 2026
- First prospect converted → Client #2 signed
- Client #2 onboarding (target: 4 hours of Greg time)
- Shadow mode for Client #2 all rocks
- Refactor anything Smile4Me-hardcoded

### November 2026
- Client #2 first month-end close (agent + Greg review)
- Agent 8 (Memory & Learning) built — reads `corrections` table, proposes prompt updates
- Prospect pipeline building for Q1 2027

### December 2026
- Client #3 signed + onboarded
- Tier 2 controls lit up (RBAC role matrix, weekly incident review start)
- Quarter close: run all clients, measure flagged % + auto-post accuracy

### January - April 2027
- Clients #4-#10 onboarded at ~1/month cadence
- First sr accountant hire OR IG Pod formalization
- Monthly compliance summary automated
- Quarter-end: review SOC 2 Type II pursuit timing

---

## This Week's Active Build Queue *(update every Friday)*

**Week of April 13, 2026:**

**Priority 1 (this week):**
- [ ] Stand up Supabase project — Team tier sign-up + request HIPAA quote from sales
- [ ] Create `reciprocity-dev-1002/accounting` repo folder structure: `/schema`, `/prompts`, `/mcp-servers`, `/docs`, `/compliance`

**Priority 2 (if time):**
- [ ] Pull Double `HookType` schema from Swagger Schemas section, update arch doc §4.7
- [ ] Draft initial Supabase schema SQL (clients, agent_actions, source_documents, je_history, corrections, incidents)
- [ ] Email Double CSM: confirm one-OAuth-per-practice vs firm-level

**Deferred / parked (pick up when ready):**
- Master COA audit vs Smile4Me's QBO live — needed before client #2, not blocking now
- QBO MCP server build — Phase 1 start, target mid-May
- PHI sanitizer implementation — target mid-May

**Done this week:** *(populate on Friday)*

---

## Decision Log *(architectural choices, dated)*

Keep short. Each entry: date, decision, 1-sentence why.

- **2026-04-13** — Supabase chosen over DigitalOcean Managed Postgres / self-hosted. Why: HIPAA BAA available, RLS first-class, pgvector transparent, co-locates with ParkStamp.
- **2026-04-13** — SOC 2 Lite implemented as Tier 0/1/2/3 earn-in, not all-at-once. Why: operational-process theater at 1-client is waste; architectural foundations alone prevent rebuild.
- **2026-04-13** — Pod model (1 sr accountant + 1 admin per ~25 clients), NOT per-client Teams channel. Why: scales linearly, doesn't proliferate channels at 100 clients.
- **2026-04-13** — Single standardized dental COA across all clients, with dormant accounts per practice. Why: cross-client benchmarking, confidence scoring needs comparable historical.
- **2026-04-13** — Claude Managed Agents chosen over Python + Claude API orchestration. Why: native agent orchestration, credential vaults, session state. Eliminates brittle Python routing.
- **2026-04-13** — Power Automate replaces n8n for triggers. Why: included in M365, no extra tooling.
- **2026-04-13** — Double integration via custom MCP server. Why: API confirmed live, webhooks exist, 24-hr tokens, clean wrapping pattern.
- **2026-04-13** — 1Password + Anthropic Credential Vault dual custody. Why: 1Password stays source of truth for humans, Anthropic Vault is runtime scope for agents.

---

## Where This Doc Lives

- **Primary (you):** `computer://Reciprocity Accounting/year1_build_plan.md`
- **Companion:** `computer://Reciprocity Accounting/ai_agent_architecture.md` (the what)
- **Source of truth (repo):** push to `reciprocity-dev-1002/accounting` under `/docs/` after each Friday update. GitHub is the durable record; OneDrive is the active workspace.
- **In future Claude sessions:** reference by name. Memory index points here — any session with auto-memory enabled will know it exists and read it on request.

---

*Revisit quarterly. If at any quarter-end the plan needs more than 20% edits, something structural has changed and the architecture doc probably needs an update too.*
