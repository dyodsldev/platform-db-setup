-- ================================================================
-- Migration: V005 - Trigger Setup (Templates)
-- Description: Trigger definitions that will be applied AFTER
--              Flyway creates the tables. This migration creates
--              helper procedures to apply triggers later.
--
-- ================================================================

-- ----------------------------------------------------------------
-- Function: increment_version
-- Description: Automatically increment version number on update
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.increment_version()
RETURNS TRIGGER AS $$
BEGIN
    -- Increment version on every UPDATE
    NEW.version = OLD.version + 1;

    -- Also update the timestamp
    NEW.updated_at = CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.increment_version() IS 'Auto-increment version column for optimistic locking';

-- ----------------------------------------------------------------
-- Function: update_updated_at_column
-- Description: Automatically update updated_at timestamp (no version)
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.update_updated_at_column() IS 'Auto-update updated_at column on UPDATE (for tables without version)';

-- ----------------------------------------------------------------
-- Function: enable_version_trigger
-- Description: Helper to enable version increment trigger on a table
-- Usage: SELECT public.enable_version_trigger('platform', 'users');
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enable_version_trigger(
    target_schema TEXT,
    target_table TEXT
)
RETURNS VOID AS $$
DECLARE
    trigger_name TEXT;
BEGIN
    trigger_name := 'trg_version_' || target_table;
    
    -- Drop trigger if exists
    EXECUTE format(
        'DROP TRIGGER IF EXISTS %I ON %I.%I',
        trigger_name,
        target_schema,
        target_table
    );
    
    -- Create trigger
    EXECUTE format(
        'CREATE TRIGGER %I
        BEFORE UPDATE ON %I.%I
        FOR EACH ROW EXECUTE FUNCTION public.increment_version()',
        trigger_name,
        target_schema,
        target_table
    );
    
    RAISE NOTICE 'Version trigger enabled on %.%', target_schema, target_table;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.enable_version_trigger(TEXT, TEXT) IS 'Enable optimistic locking trigger on specified table';

-- ----------------------------------------------------------------
-- Function: enable_updated_at_trigger
-- Description: Helper to enable updated_at trigger (no version)
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enable_updated_at_trigger(
    target_schema TEXT,
    target_table TEXT
)
RETURNS VOID AS $$
DECLARE
    trigger_name TEXT;
BEGIN
    trigger_name := 'trg_updated_at_' || target_table;
    
    EXECUTE format(
        'DROP TRIGGER IF EXISTS %I ON %I.%I',
        trigger_name,
        target_schema,
        target_table
    );
    
    EXECUTE format(
        'CREATE TRIGGER %I
        BEFORE UPDATE ON %I.%I
        FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column()',
        trigger_name,
        target_schema,
        target_table
    );
    
    RAISE NOTICE 'Updated_at trigger enabled on %.%', target_schema, target_table;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.enable_updated_at_trigger(TEXT, TEXT) IS 'Enable updated_at trigger (for tables without version column)';

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

COMMENT ON FUNCTION public.setup_validation_triggers() IS 'Set up data validation triggers on platform tables';

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

COMMENT ON FUNCTION public.validate_patient_data() IS 'Validation trigger for patient table';

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

COMMENT ON FUNCTION public.validate_patient_version_data() IS 'Validation trigger for patient_versions table';
