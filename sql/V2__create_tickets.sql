-- V2__create_tickets.sql
-- Tickets table partitioned by tenant tier (list partitioning)
CREATE TABLE tickets (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    tier tenant_tier NOT NULL,
    subject TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'open',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id, tier)
) PARTITION BY LIST (tier);

-- Partition for free tier tenants
CREATE TABLE tickets_free PARTITION OF tickets
    FOR VALUES IN ('free');

-- Partition for pro tier tenants
CREATE TABLE tickets_pro PARTITION OF tickets
    FOR VALUES IN ('pro');

-- Partition for enterprise tier tenants
CREATE TABLE tickets_enterprise PARTITION OF tickets
    FOR VALUES IN ('enterprise');

-- Partial index for fast retrieval of open tickets per tenant, ordered by creation time descending
CREATE INDEX idx_tickets_open ON tickets (tenant_id, created_at DESC) WHERE status = 'open';