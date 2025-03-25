CREATE SCHEMA IF NOT EXISTS groupscholar_resource_usage_ledger;

CREATE TABLE IF NOT EXISTS groupscholar_resource_usage_ledger.usage_events (
  id BIGSERIAL PRIMARY KEY,
  scholar_name TEXT NOT NULL,
  resource_name TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  minutes INTEGER NOT NULL CHECK (minutes >= 0),
  occurred_at TIMESTAMPTZ NOT NULL,
  staff_name TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS usage_events_occurred_at_idx
  ON groupscholar_resource_usage_ledger.usage_events (occurred_at DESC);

CREATE INDEX IF NOT EXISTS usage_events_scholar_idx
  ON groupscholar_resource_usage_ledger.usage_events (scholar_name);

CREATE INDEX IF NOT EXISTS usage_events_resource_idx
  ON groupscholar_resource_usage_ledger.usage_events (resource_name);
