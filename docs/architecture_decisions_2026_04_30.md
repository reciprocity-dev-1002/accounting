# Architecture Decisions — 2026-04-30

Three architectural decisions confirmed on 2026-04-30 after deep review of the Anthropic HIPAA-Ready Offering Implementation Guide (version April 28, 2026), the current state of Anthropic's BAA programs, and the new Anthropic Managed Agents product (launched April 8, 2026).

This document is the authoritative source for these three decisions. Where it conflicts with `ai_agent_architecture.md` (last full revision April 13), this document wins.

---

## Decision 1: Sanitizer-first, Anthropic BAA deferred to Q4 2026

**Decision:** PHI sanitizer is the primary HIPAA defense. No Anthropic BAA pursued in Q1-Q3 2026. Mission Control's prior Priority 1 "Request Anthropic BAA" item was contradictory to the existing architecture and has been removed.

**Why:**
- HIPAA-Ready Enterprise minimum is approximately $50K/year, sales-assisted only. Not viable for a one-pilot-client firm in 2026.
- Sanitizer plus the Tier 0 agent prompt contract (which already requires agents to refuse unsanitized PHI) provides two-layer defense.
- HIPAA Safe Harbor (45 CFR 164.514) explicitly permits properly de-identified data. Strip the 18 identifiers and it is not PHI.
- Daily Open Dental reports (DailyP&I, Daily Payments, Daily Adjustments) are practice-level financial data. Patient names appear in some fields but agents do not NEED them for journal entry creation.
- The April 1, 2026 HIPAA-Ready API Organization construct is real and improves coverage, but does not change the financial calculus.

**How to apply:**
- Build sanitizer as a Tier 1 control (Phase 1, target mid-May 2026)
- Open BAA conversation with Anthropic sales as a Priority 2 item (lock terms, no commitment, no spend)
- Re-evaluate Anthropic BAA in Q4 2026 when revenue from 5-10 clients can support $50K Enterprise tier

---

## Decision 2: Self-hosted agents via Claude Agent SDK

**Decision:** What was previously labeled "Agents (Claude Managed)" in the architecture is relabeled to "Agents (Claude API, self-hosted via Agent SDK)". We build agents using the Claude Agent SDK and host the runtime ourselves.

**Why:**
- Anthropic launched a product called "Claude Managed Agents" on April 8, 2026 (beta, 3 weeks old at the time of this decision). Pricing: tokens + $0.08 per session-hour + $10 per 1,000 web searches.
- Reciprocity's agents are short-lived. Daily JE runs in seconds, monthly close in minutes. Not multi-hour. Session-hour pricing punishes this pattern.
- HIPAA coverage of Managed Agents is unconfirmed in the April 28 guide.
- Power Automate is the orchestrator. It triggers self-hosted agents on schedule. Already in the architecture.
- MCP servers (QBO, Double, Audit) are the same code in either runtime model.

**Implications for the existing arch doc:**
- "Claude Managed Agents" runtime references throughout `/docs/ai_agent_architecture.md` are stale
- Cost lines for Managed Agents session-hours go to zero
- "Anthropic Credential Vaults" (a Managed Agents feature) are replaced with 1Password + environment-loaded secrets
- Multi-agent delegation research preview access is no longer relevant

**How to apply:**
- Build agents in Python or TypeScript using the Claude Agent SDK
- Power Automate triggers each agent run via webhook or scheduled flow
- Re-evaluate Anthropic Managed Agents in Q3-Q4 2026 IF: (a) 10+ clients AND operational burden of self-hosted is real, or (b) a specific agent genuinely needs multi-hour runtime, or (c) HIPAA-Ready Enterprise becomes financially viable

---

## Decision 3: Test on Greg's own books before Smile4Me

**Decision:** First production runs of all agents target Reciprocity Accounting's own QuickBooks Online before touching any Smile4Me data.

**Why:**
- Greg's own books are simple, contain no PHI, and are fully under his control
- Errors during shadow mode against his own books cost nothing operationally
- Smile4Me is a paying client with PHI exposure; the bar is higher
- "Shadow mode on Greg's own books first" replaces the more generic "Production agent shadow mode" in Mission Control

**How to apply:**
- All Phase 1 agent testing runs against Greg's QBO and synthetic data first
- Move to Smile4Me data only after sanitizer is validated and shadow runs match expected output for at least two weeks
- Smile4Me production cutover targeted for Q3 2026 per Year 1 build plan

---

## Sources reviewed

- Anthropic HIPAA-Ready Offering Implementation Guide (April 28, 2026)
- Anthropic Privacy Center: Business Associate Agreements for Commercial Customers
- Anthropic platform docs: Claude Agent SDK, Claude Managed Agents (launched April 8, 2026)
- Aptible HIPAA compliance analysis: confirms Enterprise sales-assisted, ~$50K floor
- Redress Compliance: Claude Enterprise pricing analysis 2026
- trust.anthropic.com — BAA pathway is sales-assisted

## Related decisions and context

- See `ai_agent_architecture.md` for the broader architecture (with the overrides above applied)
- See `year1_build_plan.md` for the operational sequence and quarterly milestones
- See `/compliance/README.md` for the SOC 2 Lite tier model
- See `/compliance/agent_compliance_block.md` for the Tier 0 contract every agent must include
