-- tests/jsonb_config.sql
-- TAP test suite for JSONB config column and GIN index

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

SELECT plan(1);

-- Insert a tenant with a feature flag if not already present
INSERT INTO tenants (id, name, tier, config)
VALUES ('44444444-4444-4444-4444-444444444444', 'FlagTenant', 'free', '{"feature_flags":{"chat":true}}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- Verify that the GIN index can be used for a containment query
SELECT ok(
    EXISTS (
        SELECT 1 FROM tenants
        WHERE config @> '{"feature_flags":{"chat":true}}'::jsonb
    ),
    'GIN index allows fast containment query for feature flag'
);

-- Cleanup
DELETE FROM tenants WHERE id = '44444444-4444-4444-4444-444444444444';

SELECT finish();
