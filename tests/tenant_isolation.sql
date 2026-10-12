-- tests/tenant_isolation.sql
-- TAP test suite for tenant isolation via RLS

-- Fallback TAP compatibility functions if pgTAP extension is not installed
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'plan') THEN
        CREATE OR REPLACE FUNCTION plan(integer) RETURNS void AS $f$ BEGIN RAISE NOTICE '1..%', $1; END; $f$ LANGUAGE plpgsql;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'ok') THEN
        CREATE OR REPLACE FUNCTION ok(boolean, text) RETURNS text AS $f$
        BEGIN
            IF $1 THEN
                RAISE NOTICE 'ok - %', $2;
                RETURN 'ok - ' || $2;
            ELSE
                RAISE EXCEPTION 'not ok - %', $2;
            END IF;
        END; $f$ LANGUAGE plpgsql;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'finish') THEN
        CREATE OR REPLACE FUNCTION finish() RETURNS void AS $f$ BEGIN RAISE NOTICE '# Tests completed'; END; $f$ LANGUAGE plpgsql;
    END IF;
END $$;

SELECT plan(2);

-- Create a temporary role for testing (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_user_test') THEN
        CREATE ROLE app_user_test LOGIN PASSWORD 'test';
    END IF;
END $$;

-- Grant privileges needed for the test role
GRANT SELECT, INSERT, UPDATE, DELETE ON tenants, tickets, agents TO app_user_test;

-- Switch to the test role
SET ROLE app_user_test;

-- Set tenant context to the Free tier demo tenant
SELECT set_config('app.tenant_id', '11111111-1111-1111-1111-111111111111', false);

-- Insert a ticket for this tenant
INSERT INTO tickets (tenant_id, tier, subject, description, status)
VALUES ('11111111-1111-1111-1111-111111111111', 'free', 'Test ticket', 'RLS test', 'open');

-- Verify that the tenant can see its own ticket
SELECT ok(count(*) = 1, 'Tenant can see its own ticket')
FROM tickets WHERE tenant_id = '11111111-1111-1111-1111-111111111111';

-- Switch to a different tenant (Pro tier)
SELECT set_config('app.tenant_id', '22222222-2222-2222-2222-222222222222', false);

-- Verify that the other tenant cannot see the first tenant's ticket
SELECT ok(count(*) = 0, 'Other tenant cannot see ticket from a different tenant')
FROM tickets WHERE tenant_id = '11111111-1111-1111-1111-111111111111';

-- Cleanup: revert to postgres superuser and delete the demo ticket
SET ROLE postgres;
DELETE FROM tickets WHERE tenant_id = '11111111-1111-1111-1111-111111111111';

SELECT finish();
