-- scripts/demo_isolation.sql
-- Demonstration of shared-schema tenant isolation enforced by PostgreSQL Row-Level Security (RLS).
-- Prerequisites: Migrations V1-V4 applied and R__seed_demo_tenants.sql seeded.

\echo '=== Step 1: Switch to unprivileged application role ==='
SET ROLE app_user;

\echo '=== Step 2: Tenant 1 (Acme Retailers Kenya - Free Tier) opens a ticket ==='
BEGIN;
SET LOCAL app.tenant_id = '11111111-1111-1111-1111-111111111111';

INSERT INTO tickets (tenant_id, tier, subject, description, status)
VALUES (
    '11111111-1111-1111-1111-111111111111',
    'free',
    'POS Terminal Connectivity Failure',
    'Payment gateway timed out during MPESA settlement',
    'open'
);

\echo '--- Visible tickets for Tenant 1 (Expect 1 row) ---'
SELECT id, tenant_id, tier, subject, status FROM tickets;
COMMIT;

\echo '=== Step 3: Tenant 2 (Harambee SACCO - Pro Tier) attempts to read Tenant 1 data ==='
BEGIN;
SET LOCAL app.tenant_id = '22222222-2222-2222-2222-222222222222';

\echo '--- Querying all tickets under Tenant 2 context (Expect: 0 rows) ---'
SELECT count(*) AS visible_tickets_count FROM tickets;

\echo '--- Explicitly querying Tenant 1 ID under Tenant 2 context (Expect: 0 rows) ---'
SELECT * FROM tickets WHERE tenant_id = '11111111-1111-1111-1111-111111111111';
COMMIT;

\echo '=== Step 4: Tenant 2 attempts cross-tenant insert with Tenant 1 ID (Expect: RLS WITH CHECK Violation) ==='
BEGIN;
SET LOCAL app.tenant_id = '22222222-2222-2222-2222-222222222222';

DO $$
BEGIN
    INSERT INTO tickets (tenant_id, tier, subject, description, status)
    VALUES (
        '11111111-1111-1111-1111-111111111111',
        'free',
        'Malicious Cross-Tenant Injection',
        'Attempting to insert into another tenant space',
        'open'
    );
    RAISE EXCEPTION 'SECURITY BREACH: Cross-tenant insert succeeded unexpectedly!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'SUCCESS: RLS blocked unauthorized insert (insufficient_privilege)';
    WHEN SQLSTATE '42501' THEN
        RAISE NOTICE 'SUCCESS: RLS WITH CHECK policy blocked cross-tenant insert (SQLSTATE 42501)';
END $$;

COMMIT;

\echo '=== Step 5: Clean up test ticket and reset role ==='
BEGIN;
SET LOCAL app.tenant_id = '11111111-1111-1111-1111-111111111111';
DELETE FROM tickets WHERE tenant_id = '11111111-1111-1111-1111-111111111111';
COMMIT;

RESET ROLE;
\echo '=== Tenant isolation demonstration completed successfully ==='