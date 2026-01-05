-- ================================================================
-- Migration: V011 - Partitioning Setup
-- Description: Partition management for large tables
--              Enables automatic monthly partitioning
--
-- NOTE: DBT creates tables first, then we convert to partitioned
-- ================================================================

-- ----------------------------------------------------------------
-- Function: create_partition
-- Description: Create monthly partition for a table
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_partition(
    parent_schema TEXT,
    parent_table TEXT,
    partition_column TEXT,
    year_month TEXT  -- Format: YYYY_MM
)
RETURNS TEXT AS $$
DECLARE
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
    result TEXT;
BEGIN
    -- Generate partition name
    partition_name := parent_table || '_' || year_month;
    
    -- Calculate date range
    start_date := (year_month || '_01')::DATE;
    end_date := (start_date + INTERVAL '1 month')::DATE;
    
    -- Create partition
    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I.%I PARTITION OF %I.%I
        FOR VALUES FROM (%L) TO (%L)',
        parent_schema,
        partition_name,
        parent_schema,
        parent_table,
        start_date,
        end_date
    );
    
    -- Create indexes on partition
    EXECUTE format(
        'CREATE INDEX IF NOT EXISTS %I ON %I.%I (%I)',
        'idx_' || partition_name || '_' || partition_column,
        parent_schema,
        partition_name,
        partition_column
    );
    
    result := format('Created partition %s.%s for %s to %s', parent_schema, partition_name, start_date, end_date);
    
    RAISE NOTICE '%', result;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.create_partition(TEXT, TEXT, TEXT, TEXT) IS 'Create monthly partition for a partitioned table';

-- ----------------------------------------------------------------
-- Function: create_next_month_partitions
-- Description: Automatically create partitions for next 3 months
--              Run this via pg_cron monthly
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_next_month_partitions()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    month_offset INTEGER;
    target_date DATE;
    year_month TEXT;
BEGIN
    -- Create partitions for next 3 months
    FOR month_offset IN 0..2 LOOP
        target_date := (CURRENT_DATE + (month_offset || ' months')::INTERVAL)::DATE;
        year_month := TO_CHAR(target_date, 'YYYY_MM');
        
        -- Create partitions for audit_log if it exists and is partitioned
        BEGIN
            IF EXISTS (
                SELECT 1 FROM pg_class 
                WHERE relname = 'audit_log' 
                AND relnamespace = 'audit'::regnamespace
                AND relkind = 'p'  -- p = partitioned table
            ) THEN
                result_text := result_text || public.create_partition(
                    'audit', 'audit_log', 'performed_at', year_month
                ) || E'\n';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Failed to create audit_log partition for %: %', year_month, SQLERRM;
        END;
        
        -- Add patient_versions partitions if needed
        -- (Uncomment if you convert patient_versions to partitioned table)
        /*
        BEGIN
            IF EXISTS (
                SELECT 1 FROM pg_class 
                WHERE relname = 'patient_versions' 
                AND relnamespace = 'platform'::regnamespace
                AND relkind = 'p'
            ) THEN
                result_text := result_text || public.create_partition(
                    'platform', 'patient_versions', 'valid_from', year_month
                ) || E'\n';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Failed to create patient_versions partition for %: %', year_month, SQLERRM;
        END;
        */
    END LOOP;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.create_next_month_partitions() IS 'Create partitions for next 3 months (run monthly via pg_cron)';

-- ----------------------------------------------------------------
-- Function: drop_old_partitions
-- Description: Archive/drop partitions older than retention period
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.drop_old_partitions(
    parent_schema TEXT,
    parent_table TEXT,
    retention_months INTEGER DEFAULT 84  -- 7 years
)
RETURNS TEXT AS $$
DECLARE
    partition_record RECORD;
    cutoff_date DATE;
    result_text TEXT := '';
    partition_year_month TEXT;
    partition_date DATE;
BEGIN
    cutoff_date := (CURRENT_DATE - (retention_months || ' months')::INTERVAL)::DATE;
    
    FOR partition_record IN
        SELECT 
            schemaname,
            tablename
        FROM pg_tables
        WHERE schemaname = parent_schema
            AND tablename LIKE parent_table || '_%'
            AND tablename ~ '^' || parent_table || '_\d{4}_\d{2}$'
    LOOP
        -- Extract date from partition name
        BEGIN
            partition_year_month := SUBSTRING(
                partition_record.tablename 
                FROM LENGTH(parent_table) + 2
            );
            partition_date := (partition_year_month || '_01')::DATE;
            
            IF partition_date < cutoff_date THEN
                -- Drop old partition
                EXECUTE format('DROP TABLE IF EXISTS %I.%I',
                    partition_record.schemaname,
                    partition_record.tablename
                );
                
                result_text := result_text || format('Dropped %s.%s\n',
                    partition_record.schemaname,
                    partition_record.tablename
                );
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Error processing partition %: %', 
                    partition_record.tablename, SQLERRM;
        END;
    END LOOP;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.drop_old_partitions(TEXT, TEXT, INTEGER) IS 'Drop partitions older than retention period';

-- ----------------------------------------------------------------
-- Schedule partition maintenance with pg_cron (if available)
-- ----------------------------------------------------------------
DO $$
BEGIN
    -- Check if pg_cron extension exists
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        -- Schedule monthly partition creation (1st of month at 2 AM)
        PERFORM cron.schedule(
            'create-partitions',
            '0 2 1 * *',  -- Cron: minute=0, hour=2, day=1, month=*, weekday=*
            'SELECT public.create_next_month_partitions();'
        );
        
        -- Schedule quarterly partition cleanup (1st of quarter at 3 AM)
        PERFORM cron.schedule(
            'cleanup-partitions',
            '0 3 1 */3 *',  -- Every 3 months
            'SELECT public.drop_old_partitions(''audit'', ''audit_log'', 84);'
        );
        
        RAISE NOTICE 'Scheduled partition maintenance jobs';
    ELSE
        RAISE WARNING 'pg_cron extension not available - partition maintenance must be run manually';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Could not schedule partition maintenance: %', SQLERRM;
END $$;

-- ----------------------------------------------------------------
-- NOTE: To convert existing table to partitioned:
-- 1. Rename existing table
-- 2. Create new partitioned table
-- 3. Copy data from old table to new
-- 4. Drop old table
-- 
-- This is complex and should be done carefully!
-- See PostgreSQL documentation on converting to partitioned tables
-- ----------------------------------------------------------------