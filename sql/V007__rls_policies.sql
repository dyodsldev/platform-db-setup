-- ================================================================
-- Migration: V007 - Row Level Security Policies
-- Description: Define RLS policies for multi-tenant access control
--              Applied AFTER DBT creates tables
-- ================================================================

-- ----------------------------------------------------------------
-- Function: apply_rls_policies
-- Description: Create all RLS policies on marts tables
--              Supports facility-based multi-tenancy
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.apply_rls_policies()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
BEGIN
    -- ================================================================
    -- FACILITIES TABLE POLICIES
    -- ================================================================
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'platform' AND table_name = 'facilities') THEN
            
            -- Policy: System admins see all facilities
            DROP POLICY IF EXISTS facilities_admin_all ON platform.facilities;
            CREATE POLICY facilities_admin_all ON platform.facilities
                FOR ALL
                TO app_admin
                USING (true);
            
            -- Policy: Users see only their assigned facilities
            DROP POLICY IF EXISTS facilities_user_assigned ON platform.facilities;
            CREATE POLICY facilities_user_assigned ON platform.facilities
                FOR SELECT
                TO app_read, app_write
                USING (
                    id IN (
                        SELECT facility_id 
                        FROM platform.user_facilities 
                        WHERE user_id = current_setting('app.current_user_id', true)::uuid
                    )
                );
            
            result_text := result_text || '✓ RLS policies on facilities\n';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            result_text := result_text || format('✗ Facilities policies failed: %s\n', SQLERRM);
    END;
    
    -- ================================================================
    -- USERS TABLE POLICIES
    -- ================================================================
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'platform' AND table_name = 'users') THEN
            
            -- Policy: Admins see all users
            DROP POLICY IF EXISTS users_admin_all ON platform.users;
            CREATE POLICY users_admin_all ON platform.users
                FOR ALL
                TO app_admin
                USING (true);
            
            -- Policy: Users see themselves
            DROP POLICY IF EXISTS users_see_self ON platform.users;
            CREATE POLICY users_see_self ON platform.users
                FOR SELECT
                TO app_read, app_write
                USING (id = current_setting('app.current_user_id', true)::uuid);
            
            -- Policy: Users see colleagues in same facility
            DROP POLICY IF EXISTS users_see_facility_colleagues ON platform.users;
            CREATE POLICY users_see_facility_colleagues ON platform.users
                FOR SELECT
                TO app_read, app_write
                USING (
                    primary_facility_id IN (
                        SELECT facility_id 
                        FROM platform.user_facilities 
                        WHERE user_id = current_setting('app.current_user_id', true)::uuid
                    )
                );
            
            result_text := result_text || '✓ RLS policies on users\n';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            result_text := result_text || format('✗ Users policies failed: %s\n', SQLERRM);
    END;
    
    -- ================================================================
    -- PATIENTS TABLE POLICIES
    -- ================================================================
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'platform' AND table_name = 'patients') THEN
            
            -- Policy: Admins see all patients
            DROP POLICY IF EXISTS patients_admin_all ON platform.patients;
            CREATE POLICY patients_admin_all ON platform.patients
                FOR ALL
                TO app_admin
                USING (true);
            
            -- Policy: Users see patients from their facilities
            DROP POLICY IF EXISTS patients_facility_access ON platform.patients;
            CREATE POLICY patients_facility_access ON platform.patients
                FOR SELECT
                TO app_read, app_write
                USING (
                    current_facility_id IN (
                        SELECT facility_id 
                        FROM platform.user_facilities 
                        WHERE user_id = current_setting('app.current_user_id', true)::uuid
                    )
                );
            
            -- Policy: Doctors can see their assigned patients
            DROP POLICY IF EXISTS patients_doctor_assigned ON platform.patients;
            CREATE POLICY patients_doctor_assigned ON platform.patients
                FOR SELECT
                TO app_write
                USING (
                    owner_user_id = current_setting('app.current_user_id', true)::uuid
                );
            
            result_text := result_text || '✓ RLS policies on patients\n';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            result_text := result_text || format('✗ Patients policies failed: %s\n', SQLERRM);
    END;
    
    -- ================================================================
    -- PATIENT_VERSIONS TABLE POLICIES
    -- ================================================================
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'platform' AND table_name = 'patient_versions') THEN
            
            -- Policy: Admins see all versions
            DROP POLICY IF EXISTS versions_admin_all ON platform.patient_versions;
            CREATE POLICY versions_admin_all ON platform.patient_versions
                FOR ALL
                TO app_admin
                USING (true);
            
            -- Policy: Users see versions for accessible patients
            DROP POLICY IF EXISTS versions_accessible_patients ON platform.patient_versions;
            CREATE POLICY versions_accessible_patients ON platform.patient_versions
                FOR SELECT
                TO app_read, app_write
                USING (
                    patient_id IN (
                        SELECT id FROM platform.patients 
                        -- Patients table RLS will filter this automatically
                    )
                );
            
            result_text := result_text || '✓ RLS policies on patient_versions\n';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            result_text := result_text || format('✗ Patient versions policies failed: %s\n', SQLERRM);
    END;
    
    -- ================================================================
    -- AUDIT LOG TABLE POLICIES
    -- ================================================================
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'audit' AND table_name = 'audit_log') THEN
            
            -- Policy: Only admins can see audit logs
            DROP POLICY IF EXISTS audit_admin_only ON audit.audit_log;
            CREATE POLICY audit_admin_only ON audit.audit_log
                FOR SELECT
                TO app_admin
                USING (true);
            
            -- No other role can access audit logs
            
            result_text := result_text || '✓ RLS policies on audit_log\n';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            result_text := result_text || format('✗ Audit log policies failed: %s\n', SQLERRM);
    END;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.apply_rls_policies() IS 
'Apply all Row Level Security policies to marts tables';

-- ----------------------------------------------------------------
-- Function: remove_rls_policies
-- Description: Remove all RLS policies (for testing)
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.remove_rls_policies()
RETURNS TEXT AS $$
DECLARE
    policy_record RECORD;
    result_text TEXT := '';
BEGIN
    FOR policy_record IN
        SELECT schemaname, tablename, policyname
        FROM pg_policies
        WHERE schemaname IN ('marts', 'audit')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I',
            policy_record.policyname,
            policy_record.schemaname,
            policy_record.tablename
        );
        
        result_text := result_text || format('✓ Removed policy %s on %s.%s\n',
            policy_record.policyname,
            policy_record.schemaname,
            policy_record.tablename
        );
    END LOOP;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.remove_rls_policies() IS 
'Remove all RLS policies (for testing/maintenance)';

-- ----------------------------------------------------------------
-- Helper function: Set current user context
-- Description: Application should call this after authentication
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_current_user(user_uuid UUID)
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_user_id', user_uuid::text, false);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.set_current_user(UUID) IS 
'Set current user context for RLS policies (call after authentication)';

-- ================================================================
-- NOTE: RLS policies will be applied AFTER DBT creates tables
-- See: callbacks/afterMigrate.sql
-- ================================================================