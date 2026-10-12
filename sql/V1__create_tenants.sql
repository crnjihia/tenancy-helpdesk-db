-- V1__create_tenants.sql
-- Create enum for tenant tier
CREATE TYPE tenant_tier AS ENUM ('free', 'pro', 'enterprise');

-- Tenants table
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    tier tenant_tier NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
