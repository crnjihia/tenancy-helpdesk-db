-- R__seed_demo_tenants.sql
-- Seed demo tenants for Kenyan SMEs and SACCOs across different tiers.
-- ON CONFLICT (id) DO NOTHING ensures this repeatable migration is idempotent.

INSERT INTO tenants (id, name, tier, config)
VALUES
    (
        '11111111-1111-1111-1111-111111111111',
        'Acme Retailers Kenya',
        'free',
        '{
            "sla_ms": 7200000,
            "feature_flags": {
                "chat": false,
                "priority_support": false,
                "custom_domain": false
            },
            "branding": {
                "company_name": "Acme Retailers",
                "primary_color": "#004080",
                "logo_url": "https://cdn.acmekenya.co.ke/logo.png"
            }
        }'::jsonb
    ),
    (
        '22222222-2222-2222-2222-222222222222',
        'Harambee Sacco Society',
        'pro',
        '{
            "sla_ms": 3600000,
            "feature_flags": {
                "chat": true,
                "priority_support": false,
                "custom_domain": true
            },
            "branding": {
                "company_name": "Harambee SACCO",
                "primary_color": "#008040",
                "logo_url": "https://cdn.harambeesacco.co.ke/logo.png"
            }
        }'::jsonb
    ),
    (
        '33333333-3333-3333-3333-333333333333',
        'Afya Apex Health Network',
        'enterprise',
        '{
            "sla_ms": 1800000,
            "feature_flags": {
                "chat": true,
                "priority_support": true,
                "custom_domain": true
            },
            "branding": {
                "company_name": "Afya Apex Network",
                "primary_color": "#800020",
                "logo_url": "https://cdn.afyaapex.co.ke/logo.png"
            }
        }'::jsonb
    )
ON CONFLICT (id) DO NOTHING;