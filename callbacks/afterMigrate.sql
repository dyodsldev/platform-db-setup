-- ================================================================
-- Flyway Callback: afterMigrate
-- Description: Runs AFTER all Flyway migrations complete
--              AND AFTER DBT has created tables
--              Applies triggers, RLS, and permissions to DBT tables
--
-- EXECUTION ORDER:
-- 1. Flyway V001-V016
-- 2. THIS FILE (applies triggers/RLS to DBT tables)
-- ================================================================

-- ----------------------------------------------------------------
-- STEP 1: Apply Triggers
-- ----------------------------------------------------------------
DO $$
DECLARE
    result TEXT;
BEGIN
    RAISE NOTICE 'Applying triggers to marts tables...';
    
    SELECT public.apply_all_triggers() INTO result;
    
    RAISE NOTICE '%', result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error applying triggers: %', SQLERRM;
END $$;

-- ----------------------------------------------------------------
-- STEP 2: Apply Validation Triggers
-- ----------------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE 'Applying validation triggers...';
    
    -- Validation trigger on patients table
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'marts' AND table_name = 'patients') THEN
        
        DROP TRIGGER IF EXISTS trg_validate_patient ON marts.patients;
        CREATE TRIGGER trg_validate_patient
            BEFORE INSERT OR UPDATE ON marts.patients
            FOR EACH ROW
            EXECUTE FUNCTION public.validate_patient_data();
        
        RAISE NOTICE '✓ Validation trigger on patients';
    END IF;
    
    -- Validation trigger on patient_versions table
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'marts' AND table_name = 'patient_versions') THEN
        
        DROP TRIGGER IF EXISTS trg_validate_version ON marts.patient_versions;
        CREATE TRIGGER trg_validate_version
            BEFORE INSERT OR UPDATE ON marts.patient_versions
            FOR EACH ROW
            EXECUTE FUNCTION public.validate_patient_version_data();
        
        RAISE NOTICE '✓ Validation trigger on patient_versions';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error applying validation triggers: %', SQLERRM;
END $$;

-- ----------------------------------------------------------------
-- STEP 3: Enable Row Level Security
-- ----------------------------------------------------------------
DO $$
DECLARE
    result TEXT;
BEGIN
    RAISE NOTICE 'Enabling Row Level Security...';
    
    SELECT public.enable_rls_on_marts() INTO result;
    
    RAISE NOTICE '%', result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error enabling RLS: %', SQLERRM;
END $$;

-- ----------------------------------------------------------------
-- STEP 4: Apply RLS Policies
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
-- STEP 5: Grant Permissions on New Tables
-- ----------------------------------------------------------------
DO $$
DECLARE
    result TEXT;
BEGIN
    RAISE NOTICE 'Granting permissions on marts tables...';
    
    SELECT public.grant_table_permissions() INTO result;
    
    RAISE NOTICE '%', result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error granting permissions: %', SQLERRM;
END $$;

-- ----------------------------------------------------------------
-- STEP 6: Create Initial Partitions (if needed)
-- ----------------------------------------------------------------
DO $$
DECLARE
    result TEXT;
BEGIN
    RAISE NOTICE 'Creating initial partitions...';
    
    SELECT public.create_next_month_partitions() INTO result;
    
    IF result IS NOT NULL AND result != '' THEN
        RAISE NOTICE '%', result;
    ELSE
        RAISE NOTICE 'No partitioned tables to process';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error creating partitions: %', SQLERRM;
END $$;

-- ----------------------------------------------------------------
-- STEP 7: Analyze Tables
-- ----------------------------------------------------------------
DO $$
DECLARE
    table_record RECORD;
BEGIN
    RAISE NOTICE 'Analyzing marts tables...';
    
    FOR table_record IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'marts'
          AND table_type = 'BASE TABLE'
          AND table_name NOT LIKE 'dbt_%'
    LOOP
        EXECUTE format('ANALYZE marts.%I', table_record.table_name);
        RAISE NOTICE '✓ Analyzed marts.%', table_record.table_name;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error analyzing tables: %', SQLERRM;
END $$;

-- ----------------------------------------------------------------
-- STEP 8: Verify Setup
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
    WHERE trigger_schema = 'marts';
    
    RAISE NOTICE '✓ Triggers created: %', trigger_count;
    
    -- Count tables with RLS enabled
    SELECT COUNT(*) INTO rls_count
    FROM pg_tables t
    JOIN pg_class c ON t.tablename = c.relname
    WHERE t.schemaname = 'marts'
      AND c.relrowsecurity = true;
    
    RAISE NOTICE '✓ Tables with RLS: %', rls_count;
    
    -- Count RLS policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname IN ('marts', 'audit');
    
    RAISE NOTICE '✓ RLS policies: %', policy_count;
    
    RAISE NOTICE '✅ Post-migration setup complete!';
END $$;

-- ================================================================
-- MANUAL STEPS REMINDER
-- ================================================================
-- 
-- After this callback completes, you should:
-- 
-- 1. Set passwords for service accounts:
--    ALTER USER dbt_service WITH PASSWORD 'secure-password-here';
--    ALTER USER dagster_service WITH PASSWORD 'secure-password-here';
--    ALTER USER backup_service WITH PASSWORD 'secure-password-here';
-- 
-- 2. Test RLS policies:
--    SELECT public.set_current_user('<some-user-uuid>');
--    SELECT * FROM marts.patients;  -- Should only see allowed records
-- 
-- 3. Test audit logging:
--    UPDATE marts.patients SET first_name = 'Test' WHERE id = '<some-id>';
--    SELECT * FROM audit.audit_log ORDER BY performed_at DESC LIMIT 5;
-- 
-- 4. Verify triggers:
--    UPDATE marts.users SET first_name = 'Updated';
--    -- Check that updated_at changed automatically
-- 
-- ================================================================