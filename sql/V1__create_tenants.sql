-- V1__create_tenants.sql
-- Create enum for tenant tier
CREATE TYPE tenant_tier AS ENUM ('free','pro','enterprise');

-- Tenants table
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    tier tenant_tier NOT NULL,
    config JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Generated column for SLA threshold (expects config JSON to contain "sla_ms" integer)
    sla_ms INTEGER GENERATED ALWAYS AS ((config->>'sla_ms')::INTEGER) STORED
);

-- GIN index for config containment queries
CREATE INDEX idx_tenants_config_gin ON tenants USING GIN (config);