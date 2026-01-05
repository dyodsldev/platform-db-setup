-- ================================================================
-- Migration: V007 - Enable Row Level Security (RLS)
-- Description: Enable RLS on sensitive tables with granular control
--              Policies will be defined in V008
-- ================================================================

-- ----------------------------------------------------------------
-- Function: enable_rls
-- Description: Enable RLS on a specific table
-- Usage: SELECT public.enable_rls('platform', 'patients');
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enable_rls(
    target_schema TEXT,
    target_table TEXT
)
RETURNS VOID AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY', 
        target_schema,
        target_table
    );
    
    RAISE NOTICE 'RLS enabled on %.%', target_schema, target_table;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Failed to enable RLS on %.%: %', 
            target_schema, target_table, SQLERRM;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.enable_rls(TEXT, TEXT) IS 'Enable Row Level Security on specified table';

-- ----------------------------------------------------------------
-- Function: disable_rls
-- Description: Disable RLS on a specific table
-- Usage: SELECT public.disable_rls('platform', 'patients');
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.disable_rls(
    target_schema TEXT,
    target_table TEXT
)
RETURNS VOID AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I.%I DISABLE ROW LEVEL SECURITY', 
        target_schema,
        target_table
    );
    
    RAISE NOTICE 'RLS disabled on %.%', target_schema, target_table;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Failed to disable RLS on %.%: %', 
            target_schema, target_table, SQLERRM;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.disable_rls(TEXT, TEXT) IS 'Disable Row Level Security on specified table';

-- ----------------------------------------------------------------
-- Function: enable_rls_on_platform
-- Description: Enable RLS on all platform tables (bulk operation)
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
            PERFORM public.enable_rls('platform', table_record.table_name);
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

COMMENT ON FUNCTION public.enable_rls_on_platform() IS 'Enable Row Level Security on all platform tables (bulk operation)';

-- ----------------------------------------------------------------
-- Function: disable_rls_on_platform
-- Description: Disable RLS on all platform tables (for testing/maintenance)
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
        BEGIN
            PERFORM public.disable_rls('platform', table_record.table_name);
            result_text := result_text || format('✓ RLS disabled on platform.%s\n', 
                table_record.table_name);
        EXCEPTION
            WHEN OTHERS THEN
                result_text := result_text || format('✗ Failed on platform.%s: %s\n', 
                    table_record.table_name, SQLERRM);
        END;
    END LOOP;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.disable_rls_on_platform() IS 'Disable Row Level Security on all platform tables (for maintenance)';

-- ----------------------------------------------------------------
-- Function: enable_rls_on_schema
-- Description: Enable RLS on all tables in a specific schema
-- Usage: SELECT public.enable_rls_on_schema('audit');
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enable_rls_on_schema(target_schema TEXT)
RETURNS TEXT AS $$
DECLARE
    table_record RECORD;
    result_text TEXT := '';
BEGIN
    FOR table_record IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = target_schema
          AND table_type = 'BASE TABLE'
    LOOP
        BEGIN
            PERFORM public.enable_rls(target_schema, table_record.table_name);
            result_text := result_text || format('✓ RLS enabled on %s.%s\n', 
                target_schema, table_record.table_name);
        EXCEPTION
            WHEN OTHERS THEN
                result_text := result_text || format('✗ RLS failed on %s.%s: %s\n', 
                    target_schema, table_record.table_name, SQLERRM);
        END;
    END LOOP;
    
    IF result_text = '' THEN
        result_text := format('No tables found in schema: %s\n', target_schema);
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.enable_rls_on_schema(TEXT) IS 'Enable Row Level Security on all tables in specified schema';

-- ----------------------------------------------------------------
-- Function: disable_rls_on_schema
-- Description: Disable RLS on all tables in a specific schema
-- Usage: SELECT public.disable_rls_on_schema('audit');
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.disable_rls_on_schema(target_schema TEXT)
RETURNS TEXT AS $$
DECLARE
    table_record RECORD;
    result_text TEXT := '';
BEGIN
    FOR table_record IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = target_schema
          AND table_type = 'BASE TABLE'
    LOOP
        BEGIN
            PERFORM public.disable_rls(target_schema, table_record.table_name);
            result_text := result_text || format('✓ RLS disabled on %s.%s\n', 
                target_schema, table_record.table_name);
        EXCEPTION
            WHEN OTHERS THEN
                result_text := result_text || format('✗ Failed on %s.%s: %s\n', 
                    target_schema, table_record.table_name, SQLERRM);
        END;
    END LOOP;
    
    IF result_text = '' THEN
        result_text := format('No tables found in schema: %s\n', target_schema);
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.disable_rls_on_schema(TEXT) IS 'Disable Row Level Security on all tables in specified schema';

-- ----------------------------------------------------------------
-- NOTE: RLS will be enabled AFTER tables are created
-- Call from V014/V015 or manually after migration
-- ----------------------------------------------------------------