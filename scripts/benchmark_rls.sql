-- scripts/benchmark_rls.sql
-- Benchmark a typical per-tenant ticket query utilizing the partial index idx_tickets_open.
-- Seeds 1,000 sample tickets (500 open, 500 closed), runs EXPLAIN (ANALYZE, BUFFERS),
-- and rolls back the transaction to leave the database clean.

SET ROLE app_user;

BEGIN;
-- Set tenant context for Acme Retailers Kenya (Free tier)
SET LOCAL app.tenant_id = '11111111-1111-1111-1111-111111111111';

-- Populate a batch of tickets to demonstrate index selection over table scan
INSERT INTO tickets (tenant_id, tier, subject, description, status, created_at)
SELECT
    '11111111-1111-1111-1111-111111111111',
    'free',
    'Helpdesk Support Ticket #' || g,
    'Synthetic benchmark load issue description #' || g,
    CASE WHEN g % 2 = 0 THEN 'open' ELSE 'closed' END,
    now() - (g || ' minutes')::interval
FROM generate_series(1, 1000) AS g;

-- Query the 10 most recent open tickets for the current tenant.
-- The query planner uses the partial index idx_tickets_open on partition tickets_free.
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, tenant_id, tier, subject, status, created_at
FROM tickets
WHERE tenant_id = current_setting('app.tenant_id')::uuid
  AND status = 'open'
ORDER BY created_at DESC
LIMIT 10;

-- Rollback ensures benchmark execution is idempotent and leaves no leftover records
ROLLBACK;

RESET ROLE;