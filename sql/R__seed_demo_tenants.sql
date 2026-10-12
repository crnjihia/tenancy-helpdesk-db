-- R__seed_demo_tenants.sql
-- Seed demo tenants for Kenyan SMEs and SACCOs across different tiers.
-- ON CONFLICT (id) DO NOTHING ensures this repeatable migration is idempotent.

INSERT INTO tenants (id, name, tier)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'Acme Retailers Kenya', 'free'),
    ('22222222-2222-2222-2222-222222222222', 'Harambee Sacco Society', 'pro'),
    ('33333333-3333-3333-3333-333333333333', 'Afya Apex Health Network', 'enterprise')
ON CONFLICT (id) DO NOTHING;
