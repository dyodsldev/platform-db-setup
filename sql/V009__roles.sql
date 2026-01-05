-- ================================================================
-- Migration: V009 - Database Roles
-- Description: Create PostgreSQL roles for application access
--              Implements least-privilege principle
-- ================================================================

-- ----------------------------------------------------------------
-- Application Roles
-- ----------------------------------------------------------------

-- Read-only role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_read') THEN
        CREATE ROLE app_read NOLOGIN;
    END IF;
END $$;

COMMENT ON ROLE app_read IS 'Read-only access to platform schema';

-- Read-write role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_write') THEN
        CREATE ROLE app_write NOLOGIN;
    END IF;
END $$;

COMMENT ON ROLE app_write IS 'Read-write access to platform schema (no DELETE)';

-- Admin role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_admin') THEN
        CREATE ROLE app_admin NOLOGIN;
    END IF;
END $$;

COMMENT ON ROLE app_admin IS 'Full administrative access';

-- ----------------------------------------------------------------
-- Service Roles
-- ----------------------------------------------------------------

-- DBT service role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dbt_service') THEN
        CREATE ROLE dbt_service LOGIN;
        -- Set password via ALTER USER after creation
    END IF;
END $$;

COMMENT ON ROLE dbt_service IS 'DBT service account for data transformations';

-- Dagster service role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dagster_service') THEN
        CREATE ROLE dagster_service LOGIN;
    END IF;
END $$;

COMMENT ON ROLE dagster_service IS 'Dagster orchestration service account';

-- Backup service role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'backup_service') THEN
        CREATE ROLE backup_service LOGIN;
    END IF;
END $$;

COMMENT ON ROLE backup_service IS 'Backup and restore operations';

-- ----------------------------------------------------------------
-- Analyst Roles
-- ----------------------------------------------------------------

-- Read-only analyst role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'analyst_read') THEN
        CREATE ROLE analyst_read NOLOGIN;
    END IF;
END $$;

COMMENT ON ROLE analyst_read IS 'Analysts - read-only access to platform and aggregated views';

-- ----------------------------------------------------------------
-- Role Hierarchy
-- ----------------------------------------------------------------

-- app_write inherits from app_read
GRANT app_read TO app_write;

-- app_admin inherits from app_write
GRANT app_write TO app_admin;

-- Service accounts inherit appropriate roles
GRANT app_admin TO dbt_service;
GRANT app_write TO dagster_service;
GRANT app_read TO backup_service;
GRANT app_read TO analyst_read;

-- ----------------------------------------------------------------
-- Set default connection limits
-- ----------------------------------------------------------------

ALTER ROLE app_read CONNECTION LIMIT 100;
ALTER ROLE app_write CONNECTION LIMIT 50;
ALTER ROLE app_admin CONNECTION LIMIT 10;
ALTER ROLE dbt_service CONNECTION LIMIT 5;
ALTER ROLE dagster_service CONNECTION LIMIT 10;
ALTER ROLE backup_service CONNECTION LIMIT 2;
ALTER ROLE analyst_read CONNECTION LIMIT 20;

-- ----------------------------------------------------------------
-- Set default statement timeouts (milliseconds)
-- ----------------------------------------------------------------

ALTER ROLE app_read SET statement_timeout = '30s';
ALTER ROLE app_write SET statement_timeout = '60s';
ALTER ROLE app_admin SET statement_timeout = '300s';
ALTER ROLE dbt_service SET statement_timeout = '600s';
ALTER ROLE dagster_service SET statement_timeout = '300s';

-- ----------------------------------------------------------------
-- Function: create_application_user
-- Description: Helper to create application users with proper role
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_application_user(
    username TEXT,
    user_password TEXT,
    user_role TEXT DEFAULT 'app_read'
)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
BEGIN
    -- Validate role
    IF user_role NOT IN ('app_read', 'app_write', 'app_admin') THEN
        RAISE EXCEPTION 'Invalid role: %. Must be app_read, app_write, or app_admin', user_role;
    END IF;
    
    -- Create user
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', username, user_password);
    
    -- Grant role
    EXECUTE format('GRANT %I TO %I', user_role, username);
    
    result := format('Created user %s with role %s', username, user_role);
    RAISE NOTICE '%', result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.create_application_user(TEXT, TEXT, TEXT) IS 'Create application user with specified role';

-- ----------------------------------------------------------------
-- NOTE: Actual permissions granted in V009__grants.sql
-- ----------------------------------------------------------------
