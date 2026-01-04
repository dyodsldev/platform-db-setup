-- ================================================================
-- Migration: V006 - Enable Row Level Security (RLS)
-- Description: Enable RLS on all sensitive tables
--              Policies will be defined in V007
-- ================================================================

-- ----------------------------------------------------------------
-- Function: enable_rls_on_platform
-- Description: Enable RLS on all platform tables
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enable_rls_on_platform()
RETURNS TEXT AS $$
DECLARE
    table_record RECORD;
    result_text TEXT := '';
BEGIN
    -- Enable RLS on all platform tables
    FOR table_record IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'platform'
          AND table_type = 'BASE TABLE'
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE platform.%I ENABLE ROW LEVEL SECURITY', 
                table_record.table_name);
            
            result_text := result_text || format('✓ RLS enabled on platform.%s\n', 
                table_record.table_name);
        EXCEPTION
            WHEN OTHERS THEN
                result_text := result_text || format('✗ RLS failed on platform.%s: %s\n', 
                    table_record.table_name, SQLERRM);
        END;
    END LOOP;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.enable_rls_on_platform() IS 
'Enable Row Level Security on all platform tables';

-- ----------------------------------------------------------------
-- Function: disable_rls_on_platform
-- Description: Disable RLS (for testing/maintenance)
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.disable_rls_on_platform()
RETURNS TEXT AS $$
DECLARE
    table_record RECORD;
    result_text TEXT := '';
BEGIN
    FOR table_record IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'platform'
          AND table_type = 'BASE TABLE'
    LOOP
        EXECUTE format('ALTER TABLE platform.%I DISABLE ROW LEVEL SECURITY', 
            table_record.table_name);
        
        result_text := result_text || format('✓ RLS disabled on platform.%s\n', 
            table_record.table_name);
    END LOOP;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.disable_rls_on_platform() IS 
'Disable Row Level Security on all platform tables (for maintenance)';

-- ----------------------------------------------------------------
-- NOTE: RLS will be enabled AFTER tables are created in V013-V014
-- See: callbacks/afterMigrate.sql or call manually after migration
-- ----------------------------------------------------------------