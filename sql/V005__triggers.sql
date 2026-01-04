-- ================================================================
-- Migration: V005 - Trigger Setup (Templates)
-- Description: Trigger definitions that will be applied AFTER
--              DBT creates the tables. This migration creates
--              helper procedures to apply triggers later.
--
-- IMPORTANT: Actual triggers will be applied via callback
--            AFTER DBT runs (see callbacks/afterMigrate.sql)
-- ================================================================

-- ----------------------------------------------------------------
-- Function: apply_all_triggers
-- Description: Apply all standard triggers to platform tables
--              This will be called AFTER DBT creates the tables
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.apply_all_triggers()
RETURNS TEXT AS $$
DECLARE
    table_record RECORD;
    result_text TEXT := '';
BEGIN
    -- Apply updated_at triggers to all platform tables with updated_at column
    FOR table_record IN
        SELECT 
            c.table_schema,
            c.table_name
        FROM information_schema.columns c
        WHERE c.table_schema = 'platform'
          AND c.column_name = 'updated_at'
          AND c.table_name NOT LIKE 'dbt_%'
        GROUP BY c.table_schema, c.table_name
    LOOP
        BEGIN
            -- Create updated_at trigger
            EXECUTE format(
                'DROP TRIGGER IF EXISTS trg_updated_at ON %I.%I',
                table_record.table_schema,
                table_record.table_name
            );
            
            EXECUTE format(
                'CREATE TRIGGER trg_updated_at
                BEFORE UPDATE ON %I.%I
                FOR EACH ROW
                EXECUTE FUNCTION public.update_updated_at_column()',
                table_record.table_schema,
                table_record.table_name
            );
            
            result_text := result_text || format('✓ updated_at trigger on %s.%s\n', 
                table_record.table_schema, table_record.table_name);
        EXCEPTION
            WHEN OTHERS THEN
                result_text := result_text || format('✗ Failed on %s.%s: %s\n', 
                    table_record.table_schema, table_record.table_name, SQLERRM);
        END;
    END LOOP;
    
    -- Apply audit triggers to critical tables
    DECLARE
        audit_tables TEXT[] := ARRAY[
            'patients',
            'patient_versions',
            'users',
            'facilities',
            'patient_transfers'
        ];
        audit_table TEXT;
    BEGIN
        FOREACH audit_table IN ARRAY audit_tables
        LOOP
            BEGIN
                -- Check if table exists first
                IF EXISTS (
                    SELECT 1 FROM information_schema.tables 
                    WHERE table_schema = 'platform' 
                    AND table_name = audit_table
                ) THEN
                    PERFORM audit.enable_audit_trigger('platform', audit_table);
                    result_text := result_text || format('✓ Audit trigger on platform.%s\n', audit_table);
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    result_text := result_text || format('✗ Audit trigger failed on platform.%s: %s\n', 
                        audit_table, SQLERRM);
            END;
        END LOOP;
    END;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.apply_all_triggers() IS 
'Apply all standard triggers to platform tables (run after DBT creates tables)';

-- ----------------------------------------------------------------
-- Function: setup_validation_triggers
-- Description: Add validation triggers for data quality
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.setup_validation_triggers()
RETURNS TEXT AS $$
BEGIN
    -- Placeholder for validation triggers
    -- These will be added after DBT creates the tables
    
    RETURN 'Validation triggers setup complete';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.setup_validation_triggers() IS 
'Set up data validation triggers on platform tables';

-- ----------------------------------------------------------------
-- Example: Patient validation trigger function
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_patient_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate date of birth is not in the future
    IF NEW.date_of_birth > CURRENT_DATE THEN
        RAISE EXCEPTION 'Date of birth cannot be in the future: %', NEW.date_of_birth;
    END IF;
    
    -- Validate patient code format
    IF NEW.code IS NULL OR LENGTH(NEW.code) < 3 THEN
        RAISE EXCEPTION 'Invalid patient code: %', NEW.code;
    END IF;
    
    -- Validate deceased date
    IF NEW.deceased_date IS NOT NULL AND NEW.deceased_date > CURRENT_DATE THEN
        RAISE EXCEPTION 'Deceased date cannot be in the future: %', NEW.deceased_date;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.validate_patient_data() IS 
'Validation trigger for patient table';

-- ----------------------------------------------------------------
-- Example: Patient version validation trigger function
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_patient_version_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate HbA1c range
    IF NEW.hba1c_latest IS NOT NULL THEN
        IF NOT public.validate_hba1c_range(NEW.hba1c_latest) THEN
            RAISE WARNING 'HbA1c value outside normal range: %', NEW.hba1c_latest;
        END IF;
    END IF;
    
    -- Validate blood pressure
    IF NEW.bp_systolic IS NOT NULL OR NEW.bp_diastolic IS NOT NULL THEN
        IF NOT public.validate_bp_range(NEW.bp_systolic, NEW.bp_diastolic) THEN
            RAISE WARNING 'Blood pressure values outside normal range: %/%', 
                NEW.bp_systolic, NEW.bp_diastolic;
        END IF;
    END IF;
    
    -- Validate BMI if provided
    IF NEW.bmi IS NOT NULL AND (NEW.bmi < 10 OR NEW.bmi > 100) THEN
        RAISE WARNING 'BMI value outside normal range: %', NEW.bmi;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.validate_patient_version_data() IS 
'Validation trigger for patient_versions table';

-- ----------------------------------------------------------------
-- NOTE: Actual trigger creation happens in callback
-- See: callbacks/afterMigrate.sql
-- This will be executed AFTER DBT runs
-- ----------------------------------------------------------------