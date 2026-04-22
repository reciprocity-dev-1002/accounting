-- ============================================================
-- Reciprocity AI Bookkeeper — Supabase Schema v1
-- ============================================================
-- Target:  Supabase (Postgres 15+, pgvector, RLS enabled)
-- Tenancy: Multi-client from day one. Every table has client_id.
--          RLS policies enforce isolation at the DB layer via
--          JWT claim app.tenant_id — a query for client A cannot
--          return client B rows even if an agent drops the WHERE.
-- Auth:    Agent service role = INSERT only on audit tables.
--          UPDATE and DELETE revoked — logs are append-only.
-- ============================================================

-- Enable pgvector (required for Agent 6 confidence scoring)
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================
-- 1. clients
-- The multi-tenant anchor. One row per practice.
-- ============================================================
CREATE TABLE clients (
  id                    BIGSERIAL PRIMARY KEY,
  display_name          TEXT        NOT NULL,
  entity_name           TEXT,                         -- legal entity (e.g. "Davis Dental of Florida LLC")
  qbo_realm_id          TEXT        UNIQUE,           -- QuickBooks Online company ID
  pms_type              TEXT,                         -- open_dental | dentrix | eaglesoft | curve | other
  payroll_provider      TEXT,                         -- surepayroll | gusto | adp | paychex | heartland
  fiscal_year_start     INT         DEFAULT 1,        -- month number (1 = January)
  close_target_day      INT         DEFAULT 5,        -- target close day each month
  auto_post_threshold   NUMERIC(4,3) DEFAULT 0.950,   -- confidence floor for auto-post
  active                BOOLEAN     DEFAULT TRUE,
  onboarded_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE clients IS 'One row per client practice. Auth tokens live in Anthropic Credential Vault; config lives here.';

-- ============================================================
-- 2. client_config
-- Non-auth configuration that varies per client.
-- Stored as JSONB so the schema doesn't need a migration
-- every time we add a new config key.
-- ============================================================
CREATE TABLE client_config (
  id                    BIGSERIAL PRIMARY KEY,
  client_id             BIGINT      NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  config_key            TEXT        NOT NULL,
  config_value          JSONB       NOT NULL,
  note                  TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (client_id, config_key)
);

COMMENT ON TABLE client_config IS
  'Per-client non-auth config: COA mappings, provider roster, financing providers + MDF rates,
   bank/CC account list, recurring JE schedule, loan schedules, OneDrive folder IDs.
   Auth tokens (QBO OAuth, Double OAuth, etc.) live in Anthropic Credential Vault — NOT here.';

-- Example config_keys:
--   coa_mappings         { "insurance_collections": "4001", "patient_collections": "4002", ... }
--   provider_roster      [ { "name": "Dr. Smith", "type": "owner", "revenue_account": "4010" }, ... ]
--   financing_providers  [ { "name": "Cherry", "mdf_rate": 0.06, "bank_account": "Chase 4567" }, ... ]
--   bank_accounts        [ { "name": "Chase Operating", "last4": "4567", "qbo_account_id": "..." }, ... ]
--   recurring_je_schedule [ { "description": "Prepaid insurance amort", "debit": "...", "credit": "...", "amount": 500, "day_of_month": 1 }, ... ]
--   loan_schedule        { "lender": "BofA", "original_balance": 250000, "rate": 0.065, "start_date": "2023-01-01", "qbo_liability_account": "..." }
--   onedrive_folder_ids  { "daily_reports": "...", "monthly_statements": "...", "receipts": "..." }

CREATE INDEX idx_client_config_client_id ON client_config(client_id);

-- ============================================================
-- 3. source_documents
-- Every file the system receives. Written by Agent 1 (Coordinator)
-- on file arrival. Read by every specialist before processing.
-- ============================================================
CREATE TABLE source_documents (
  id                    BIGSERIAL PRIMARY KEY,
  client_id             BIGINT      NOT NULL REFERENCES clients(id),
  file_path             TEXT        NOT NULL,         -- OneDrive path
  file_hash             TEXT        NOT NULL,         -- SHA-256 of raw file
  file_name             TEXT,
  document_type         TEXT,                         -- daily_pi | daily_payments | daily_adjustments |
                                                      -- payroll | bank_statement | cc_statement |
                                                      -- loan_statement | receipt | other
  report_date           DATE,                         -- date the report covers (not received date)
  received_at           TIMESTAMPTZ DEFAULT NOW(),
  processed_at          TIMESTAMPTZ,
  status                TEXT        DEFAULT 'received',  -- received | processing | processed | failed | skipped
  session_id            TEXT,                         -- Managed Agents session that processed this
  error_detail          TEXT,                         -- populated on status=failed
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_source_documents_client_date ON source_documents(client_id, report_date);
CREATE INDEX idx_source_documents_status ON source_documents(client_id, status);
CREATE UNIQUE INDEX idx_source_documents_hash ON source_documents(client_id, file_hash);

-- ============================================================
-- 4. je_history
-- Every journal entry ever proposed or posted.
-- Written by Agent 7 (Poster). Read by Agent 6 (Auditor)
-- for historical pattern matching via pgvector similarity.
-- ============================================================
CREATE TABLE je_history (
  id                    BIGSERIAL PRIMARY KEY,
  client_id             BIGINT      NOT NULL REFERENCES clients(id),
  je_date               DATE        NOT NULL,
  memo                  TEXT,
  accounts              TEXT[]      NOT NULL,         -- GL account numbers involved
  debits                NUMERIC[]   NOT NULL,         -- parallel array to accounts
  credits               NUMERIC[]   NOT NULL,         -- parallel array to accounts
  je_type               TEXT,                         -- production | collections | payroll | expense |
                                                      -- bank_rec | depreciation | prepaid | loan | other
  source_document_id    BIGINT      REFERENCES source_documents(id),
  agent_id              TEXT,                         -- which agent generated this JE
  session_id            TEXT,                         -- Managed Agents session ID
  confidence_score      NUMERIC(4,3),                 -- Agent 6 output (0.000 - 1.000)
  approval_status       TEXT        DEFAULT 'pending', -- pending | auto_approved | flagged | held | human_approved | rejected
  reviewer_id           TEXT,                         -- set if a human approved/rejected
  reviewer_note         TEXT,
  qbo_je_id             TEXT,                         -- QBO journal entry ID after posting
  posted_at             TIMESTAMPTZ,
  reversed_at           TIMESTAMPTZ,
  reversal_je_id        BIGINT      REFERENCES je_history(id),
  -- pgvector embedding for Agent 6 similarity search
  -- 1536 dims matches text-embedding-3-small; adjust if switching models
  embedding             vector(1536),
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_je_history_client_date ON je_history(client_id, je_date);
CREATE INDEX idx_je_history_approval ON je_history(client_id, approval_status);
CREATE INDEX idx_je_history_qbo ON je_history(qbo_je_id) WHERE qbo_je_id IS NOT NULL;
-- ivfflat index for pgvector similarity search (tune lists= after data volume grows)
CREATE INDEX idx_je_history_embedding ON je_history
  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- ============================================================
-- 5. agent_actions
-- Append-only audit log. Written by EVERY agent on EVERY action.
-- This is the SOC 2 Lite backbone.
-- ============================================================
CREATE TABLE agent_actions (
  id                    BIGSERIAL PRIMARY KEY,
  timestamp             TIMESTAMPTZ DEFAULT NOW(),
  client_id             BIGINT      REFERENCES clients(id),  -- nullable: some infra events are cross-client
  session_id            TEXT,
  agent_id              TEXT        NOT NULL,                 -- coordinator | receipt_matcher | payroll |
                                                              -- production | collections | close_coordinator |
                                                              -- bank_rec | loan | auditor | poster | memory
  action_type           TEXT        NOT NULL,                 -- file_read | je_proposed | je_scored |
                                                              -- je_posted | je_flagged | je_held |
                                                              -- task_completed | note_posted | incident_logged |
                                                              -- correction_applied | session_started | session_ended
  input_hash            TEXT,                                 -- SHA-256 of input payload
  input_summary         TEXT,                                 -- non-PHI human-readable summary
  output_summary        TEXT,                                 -- non-PHI human-readable summary
  confidence_score      NUMERIC(4,3),
  approval_status       TEXT,
  reviewer_id           TEXT,
  qbo_je_id             TEXT,
  je_id                 BIGINT      REFERENCES je_history(id),
  source_document_id    BIGINT      REFERENCES source_documents(id),
  -- Compliance block: every action records which prompt version governed it
  prompt_version        TEXT,
  compliance_block_hash TEXT        -- SHA-256 of the compliance block in effect at runtime
);

-- INSERT-only for agent service role (enforced via GRANT below)
CREATE INDEX idx_agent_actions_client_ts ON agent_actions(client_id, timestamp DESC);
CREATE INDEX idx_agent_actions_session ON agent_actions(session_id);
CREATE INDEX idx_agent_actions_type ON agent_actions(action_type);

-- ============================================================
-- 6. corrections
-- Written by humans when they fix an agent's entry.
-- Read exclusively by Agent 8 (Memory & Learning).
-- ============================================================
CREATE TABLE corrections (
  id                    BIGSERIAL PRIMARY KEY,
  client_id             BIGINT      NOT NULL REFERENCES clients(id),
  original_je_id        BIGINT      NOT NULL REFERENCES je_history(id),
  corrected_by          TEXT        NOT NULL,         -- reviewer user ID
  correction_reason     TEXT,
  correction_category   TEXT,                         -- wrong_account | wrong_amount | wrong_period |
                                                      -- wrong_vendor | misclassification | other
  delta                 JSONB,                        -- { "before": {...}, "after": {...} }
  captured_at           TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_corrections_client ON corrections(client_id, captured_at DESC);
CREATE INDEX idx_corrections_category ON corrections(client_id, correction_category);

-- ============================================================
-- 7. incidents
-- Written by any agent that hits a problem.
-- Greg eyeballs this table in Tier 1. Formal review cadence
-- kicks in at Tier 2 (Pod 1 forming, ~5-15 clients).
-- ============================================================
CREATE TABLE incidents (
  id                    BIGSERIAL PRIMARY KEY,
  timestamp             TIMESTAMPTZ DEFAULT NOW(),
  client_id             BIGINT      REFERENCES clients(id),  -- nullable: some incidents are infra-level
  severity              TEXT        NOT NULL,                 -- low | medium | high | critical
  category              TEXT        NOT NULL,                 -- auth_failure | confidence_rejection |
                                                              -- api_error | client_complaint |
                                                              -- access_anomaly | phi_leak_suspected |
                                                              -- agent_escalation | missing_file |
                                                              -- duplicate_entry_blocked
  description           TEXT        NOT NULL,
  triggered_by          TEXT,                                 -- agent_id or user_id
  session_id            TEXT,
  resolution            TEXT,
  resolved_at           TIMESTAMPTZ,
  compliance_relevant   BOOLEAN     DEFAULT FALSE
);

CREATE INDEX idx_incidents_client_ts ON incidents(client_id, timestamp DESC);
CREATE INDEX idx_incidents_severity ON incidents(severity, resolved_at);

-- ============================================================
-- ROW-LEVEL SECURITY
-- Enforced at DB layer via JWT claim app.tenant_id.
-- A query for client A cannot return client B rows even if
-- an agent omits the WHERE clause.
-- ============================================================

ALTER TABLE clients           ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_config     ENABLE ROW LEVEL SECURITY;
ALTER TABLE source_documents  ENABLE ROW LEVEL SECURITY;
ALTER TABLE je_history        ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_actions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE corrections       ENABLE ROW LEVEL SECURITY;
ALTER TABLE incidents         ENABLE ROW LEVEL SECURITY;

-- Service role policy: scoped to JWT tenant
-- (client_id IS NULL rows are infra-level events, visible to admin role only)
CREATE POLICY tenant_isolation ON clients
  USING (id = (current_setting('app.tenant_id', TRUE)::BIGINT));

CREATE POLICY tenant_isolation ON client_config
  USING (client_id = (current_setting('app.tenant_id', TRUE)::BIGINT));

CREATE POLICY tenant_isolation ON source_documents
  USING (client_id = (current_setting('app.tenant_id', TRUE)::BIGINT));

CREATE POLICY tenant_isolation ON je_history
  USING (client_id = (current_setting('app.tenant_id', TRUE)::BIGINT));

CREATE POLICY tenant_isolation ON agent_actions
  USING (
    client_id IS NULL OR
    client_id = (current_setting('app.tenant_id', TRUE)::BIGINT)
  );

CREATE POLICY tenant_isolation ON corrections
  USING (client_id = (current_setting('app.tenant_id', TRUE)::BIGINT));

CREATE POLICY tenant_isolation ON incidents
  USING (
    client_id IS NULL OR
    client_id = (current_setting('app.tenant_id', TRUE)::BIGINT)
  );

-- ============================================================
-- ROLE GRANTS
-- agent_service: the role Managed Agents sessions use.
--   - Can INSERT on all tables (audit trail)
--   - Can SELECT on je_history, source_documents, client_config (agents need to read)
--   - Cannot UPDATE or DELETE on audit tables (immutability)
-- ============================================================

-- These assume a role named agent_service exists (create in Supabase dashboard)
GRANT INSERT ON agent_actions   TO agent_service;
GRANT INSERT ON incidents       TO agent_service;
GRANT INSERT ON source_documents TO agent_service;
GRANT INSERT ON je_history      TO agent_service;
GRANT INSERT ON corrections     TO agent_service;

GRANT SELECT ON je_history      TO agent_service;
GRANT SELECT ON source_documents TO agent_service;
GRANT SELECT ON client_config   TO agent_service;
GRANT SELECT ON clients         TO agent_service;

-- No UPDATE or DELETE on audit tables for agent_service
-- (human_reviewer role gets UPDATE on je_history.approval_status only — add when Pod forms)

-- ============================================================
-- SEED: Reciprocity Accounting as client_id = 1
-- Greg's own books — the internal validation client.
-- ============================================================
INSERT INTO clients (
  id, display_name, entity_name, pms_type,
  auto_post_threshold, active, onboarded_at
) VALUES (
  1,
  'Reciprocity Accounting',
  'Reciprocity Accounting LLC',
  NULL,   -- not a dental practice; no PMS
  0.950,
  TRUE,
  NOW()
);

-- Basic config for Reciprocity's own books
INSERT INTO client_config (client_id, config_key, config_value, note) VALUES
(1, 'bank_accounts',   '[]'::JSONB, 'Populate with QBO bank account IDs once QBO MCP is live'),
(1, 'coa_mappings',    '{}'::JSONB, 'Populate from QBO chart of accounts on first agent run'),
(1, 'onedrive_folder_ids', '{}'::JSONB, 'Populate with OneDrive folder IDs from Operations - IT structure');
