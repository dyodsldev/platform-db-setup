-- ================================================================
-- Migration: V010 - Grant Permissions
-- Description: Grant appropriate permissions to each role
--              Implements least-privilege access control
-- ================================================================

-- ----------------------------------------------------------------
-- Schema Usage Grants
-- ----------------------------------------------------------------

-- Grant usage on schemas to all application roles
GRANT USAGE ON SCHEMA public TO app_read, app_write, app_admin;
GRANT USAGE ON SCHEMA platform TO app_read, app_write, app_admin;
GRANT USAGE ON SCHEMA lookups TO app_read, app_write, app_admin;
GRANT USAGE ON SCHEMA audit TO app_admin;

-- Analyst access (read-only on application data)
GRANT USAGE ON SCHEMA platform TO analyst_read;
GRANT USAGE ON SCHEMA lookups TO analyst_read;

-- ----------------------------------------------------------------
-- Function: grant_table_permissions
-- Description: Helper to grant permissions on future tables
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.grant_table_permissions()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
BEGIN
    -- ================================================================
    -- APP_READ ROLE - SELECT only
    -- ================================================================
    
    -- Platform tables
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA platform TO app_read');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA platform GRANT SELECT ON TABLES TO app_read');
    
    -- Lookups tables (read-only reference data)
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA lookups TO app_read');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA lookups GRANT SELECT ON TABLES TO app_read');
    
    -- Functions
    EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO app_read');
    
    result_text := result_text || '✓ Granted SELECT to app_read\n';
    
    -- ================================================================
    -- APP_WRITE ROLE - INSERT, UPDATE (no DELETE)
    -- ================================================================
    
    -- Platform tables
    EXECUTE format('GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA platform TO app_write');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA platform GRANT SELECT, INSERT, UPDATE ON TABLES TO app_write');
    
    -- Lookups tables (read-only reference data for app_write)
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA lookups TO app_write');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA lookups GRANT SELECT ON TABLES TO app_write');
    
    -- Sequences (for auto-increment fields)
    EXECUTE format('GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA platform TO app_write');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA platform GRANT USAGE, SELECT ON SEQUENCES TO app_write');
    
    result_text := result_text || '✓ Granted INSERT, UPDATE to app_write\n';
    
    -- ================================================================
    -- APP_ADMIN ROLE - Full access
    -- ================================================================
    
    -- All schemas
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA platform TO app_admin');
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA lookups TO app_admin');
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit TO app_admin');
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA platform TO app_admin');
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO app_admin');
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA audit TO app_admin');
    
    -- Default privileges
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA platform GRANT ALL ON TABLES TO app_admin');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA lookups GRANT ALL ON TABLES TO app_admin');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT ALL ON TABLES TO app_admin');
    
    result_text := result_text || '✓ Granted ALL to app_admin\n';
    
    -- ================================================================
    -- ANALYST_READ ROLE - Read-only on platform and lookups
    -- ================================================================
    
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA platform TO analyst_read');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA platform GRANT SELECT ON TABLES TO analyst_read');
    
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA lookups TO analyst_read');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA lookups GRANT SELECT ON TABLES TO analyst_read');
    
    result_text := result_text || '✓ Granted SELECT to analyst_read\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.grant_table_permissions() IS 'Grant appropriate permissions to all roles on existing and future tables';

-- ----------------------------------------------------------------
-- Execute grants function
-- ----------------------------------------------------------------
SELECT public.grant_table_permissions();

-- ----------------------------------------------------------------
-- Revoke dangerous public permissions
-- ----------------------------------------------------------------

-- Revoke public schema creation
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Revoke all on public tables from PUBLIC role
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA platform FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA audit FROM PUBLIC;

-- ----------------------------------------------------------------
-- Function-specific grants
-- ----------------------------------------------------------------

-- Allow app_read to use utility functions
GRANT EXECUTE ON FUNCTION public.calculate_age(DATE) TO app_read;
GRANT EXECUTE ON FUNCTION public.calculate_bmi(NUMERIC, NUMERIC) TO app_read;
GRANT EXECUTE ON FUNCTION public.calculate_egfr(NUMERIC, INTEGER, BOOLEAN, BOOLEAN) TO app_read;

-- Allow app_write to use validation functions
GRANT EXECUTE ON FUNCTION public.validate_hba1c_range(NUMERIC) TO app_write;
GRANT EXECUTE ON FUNCTION public.validate_bp_range(INTEGER, INTEGER) TO app_write;

-- Only admins can modify triggers
GRANT EXECUTE ON FUNCTION public.apply_all_triggers() TO app_admin;
GRANT EXECUTE ON FUNCTION audit.enable_audit_trigger(TEXT, TEXT) TO app_admin;
GRANT EXECUTE ON FUNCTION audit.disable_audit_trigger(TEXT, TEXT) TO app_admin;

-- ----------------------------------------------------------------
-- Audit Log Table Permissions
-- ----------------------------------------------------------------
-- Read-only access to audit logs for app_read and app_write
GRANT SELECT ON audit.audit_log TO app_read;
GRANT SELECT ON audit.audit_log TO app_write;

-- Full access for admins
GRANT ALL ON audit.audit_log TO app_admin;

-- Audit trigger function (used internally by triggers)
GRANT EXECUTE ON FUNCTION audit.audit_trigger() TO app_admin;

-- Only admins can manage RLS
GRANT EXECUTE ON FUNCTION public.enable_rls_on_platform() TO app_admin;
GRANT EXECUTE ON FUNCTION public.disable_rls_on_platform() TO app_admin;
GRANT EXECUTE ON FUNCTION public.apply_rls_policies() TO app_admin;

-- Audit history access (only grant on functions that exist)
GRANT EXECUTE ON FUNCTION audit.get_audit_history(TEXT, TEXT, UUID) TO app_read;
GRANT EXECUTE ON FUNCTION audit.get_audit_history(TEXT, TEXT, UUID) TO app_write;
GRANT EXECUTE ON FUNCTION audit.get_audit_history(TEXT, TEXT, UUID) TO app_admin;

-- ----------------------------------------------------------------
-- NOTE: These grants apply immediately
-- After DBT runs, call grant_table_permissions() again
-- to grant permissions on newly created tables
-- ----------------------------------------------------------------