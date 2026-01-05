-- ================================================================
-- Flyway Callback: afterMigrate
-- Description: Runs AFTER all Flyway migrations complete
--              Applies RLS policies and verifies setup
-- ================================================================

-- ----------------------------------------------------------------
-- STEP 1: Apply RLS Policies
-- ----------------------------------------------------------------
DO $$
DECLARE
    result TEXT;
BEGIN
    RAISE NOTICE 'Applying RLS policies...';
    
    SELECT public.apply_rls_policies() INTO result;
    
    RAISE NOTICE '%', result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error applying RLS policies: %', SQLERRM;
END $$;

-- ----------------------------------------------------------------
-- STEP 2: Grant Permissions (in case new tables were added)
-- ----------------------------------------------------------------
DO $$
DECLARE
    result TEXT;
BEGIN
    RAISE NOTICE 'Granting permissions...';
    
    SELECT public.grant_table_permissions() INTO result;
    
    RAISE NOTICE '%', result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error granting permissions: %', SQLERRM;
END $$;

-- ----------------------------------------------------------------
-- STEP 3: Verify Setup
-- ----------------------------------------------------------------
DO $$
DECLARE
    trigger_count INTEGER;
    rls_count INTEGER;
    policy_count INTEGER;
BEGIN
    RAISE NOTICE 'Verifying setup...';
    
    -- Count triggers
    SELECT COUNT(*) INTO trigger_count
    FROM information_schema.triggers
    WHERE trigger_schema = 'platform';
    
    RAISE NOTICE '✓ Triggers created: %', trigger_count;
    
    -- Count tables with RLS enabled
    SELECT COUNT(*) INTO rls_count
    FROM pg_tables t
    JOIN pg_class c ON t.tablename = c.relname AND t.schemaname = c.relnamespace::regnamespace::text
    WHERE t.schemaname = 'platform'
      AND c.relrowsecurity = true;
    
    RAISE NOTICE '✓ Tables with RLS: %', rls_count;
    
    -- Count RLS policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname IN ('platform', 'audit');
    
    RAISE NOTICE '✓ RLS policies: %', policy_count;
    
    RAISE NOTICE '✅ Post-migration setup complete!';
END $$;

-- ================================================================
-- MANUAL STEPS REMINDER
-- ================================================================
-- 
-- After migrations complete:
-- 
-- 1. Set passwords for service accounts:
--    ALTER USER dbt_service WITH PASSWORD 'secure-password';
--    ALTER USER dagster_service WITH PASSWORD 'secure-password';
--    ALTER USER backup_service WITH PASSWORD 'secure-password';
-- 
-- 2. Test RLS policies:
--    SELECT public.set_current_user('<user-uuid>');
--    SELECT * FROM platform.patients;  -- Should filter based on RLS
-- 
-- 3. Test audit logging:
--    UPDATE platform.patients SET first_name = 'Test' WHERE id = '<id>';
--    SELECT * FROM audit.audit_log ORDER BY performed_at DESC LIMIT 5;
-- 
-- 4. Test optimistic locking:
--    -- Simulate concurrent updates to verify version checking
-- 
-- ================================================================