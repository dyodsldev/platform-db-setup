-- ================================================================
-- Migration: V004 - Audit Logging Functions
-- Description: Complete audit trail system for tracking all
--              INSERT, UPDATE, DELETE operations
-- ================================================================

-- ----------------------------------------------------------------
-- Function: audit_trigger
-- Description: Generic trigger function to log all changes
-- Usage: CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION audit.audit_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_old_data JSONB;
    v_new_data JSONB;
    v_changed_fields TEXT[];
    v_username TEXT;
    v_application_name TEXT;
    v_client_address INET;
BEGIN
    -- Get session information
    v_username := current_user;
    v_application_name := current_setting('application_name', true);
    
    -- Try to get client address (may fail in some contexts)
    BEGIN
        v_client_address := inet_client_addr();
    EXCEPTION WHEN OTHERS THEN
        v_client_address := NULL;
    END;
    
    -- Handle different operations
    IF (TG_OP = 'DELETE') THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := NULL;
        v_changed_fields := NULL;
        
    ELSIF (TG_OP = 'INSERT') THEN
        v_old_data := NULL;
        v_new_data := to_jsonb(NEW);
        v_changed_fields := NULL;
        
    ELSIF (TG_OP = 'UPDATE') THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
        
        -- Calculate changed fields
        SELECT array_agg(key)
        INTO v_changed_fields
        FROM (
            SELECT key
            FROM jsonb_each(to_jsonb(NEW))
            WHERE to_jsonb(NEW) -> key IS DISTINCT FROM to_jsonb(OLD) -> key
        ) changed;
    END IF;
    
    -- Insert audit record
    INSERT INTO audit.audit_log (
        table_schema,
        table_name,
        operation,
        username,
        application_name,
        client_address,
        old_data,
        new_data,
        changed_fields,
        transaction_id,
        performed_at
    ) VALUES (
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        TG_OP,
        v_username,
        v_application_name,
        v_client_address,
        v_old_data,
        v_new_data,
        v_changed_fields,
        txid_current(),
        CURRENT_TIMESTAMP
    );
    
    -- Return appropriate record
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.audit_trigger() IS 'Generic audit trigger function - tracks all changes';

-- ----------------------------------------------------------------
-- Function: enable_audit_trigger
-- Description: Helper function to enable audit logging on a table
-- Usage: SELECT audit.enable_audit_trigger('schema_name', 'table_name');
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION audit.enable_audit_trigger(
    target_schema TEXT,
    target_table TEXT
)
RETURNS VOID AS $$
DECLARE
    trigger_name TEXT;
BEGIN
    trigger_name := 'audit_trigger_' || target_table;
    
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
        AFTER INSERT OR UPDATE OR DELETE ON %I.%I
        FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger()',
        trigger_name,
        target_schema,
        target_table
    );
    
    RAISE NOTICE 'Audit trigger enabled on %.%', target_schema, target_table;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION audit.enable_audit_trigger(TEXT, TEXT) IS 'Enable audit logging on specified table';

-- ----------------------------------------------------------------
-- Function: disable_audit_trigger
-- Description: Helper function to disable audit logging on a table
-- Usage: SELECT audit.disable_audit_trigger('schema_name', 'table_name');
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION audit.disable_audit_trigger(
    target_schema TEXT,
    target_table TEXT
)
RETURNS VOID AS $$
DECLARE
    trigger_name TEXT;
BEGIN
    trigger_name := 'audit_trigger_' || target_table;
    
    EXECUTE format(
        'DROP TRIGGER IF EXISTS %I ON %I.%I',
        trigger_name,
        target_schema,
        target_table
    );
    
    RAISE NOTICE 'Audit trigger disabled on %.%', target_schema, target_table;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION audit.disable_audit_trigger(TEXT, TEXT) IS 'Disable audit logging on specified table';

-- ----------------------------------------------------------------
-- Function: get_audit_history
-- Description: Get audit history for a specific record
-- Usage: SELECT * FROM audit.get_audit_history('platform', 'patients', 'uuid-here');
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION audit.get_audit_history(
    target_schema TEXT,
    target_table TEXT,
    record_id UUID
)
RETURNS TABLE (
    operation TEXT,
    changed_fields TEXT[],
    performed_at TIMESTAMP,
    username TEXT,
    old_data JSONB,
    new_data JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.operation,
        a.changed_fields,
        a.performed_at,
        a.username,
        a.old_data,
        a.new_data
    FROM audit.audit_log a
    WHERE a.table_schema = target_schema
      AND a.table_name = target_table
      AND (
          (a.old_data->>'id')::UUID = record_id OR
          (a.new_data->>'id')::UUID = record_id
      )
    ORDER BY a.performed_at DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION audit.get_audit_history(TEXT, TEXT, UUID) IS 'Get complete audit history for a specific record';

-- ----------------------------------------------------------------
-- Partitioning setup for audit_log (for performance)
-- Note: Actual partitions will be created by V010__partitioning.sql
-- ----------------------------------------------------------------
COMMENT ON COLUMN audit.audit_log.performed_at IS 'Timestamp for partitioning by month';

-- ----------------------------------------------------------------
-- Note: Permissions will be granted in V009__grants.sql
-- after roles are created in V008__roles.sql
-- ----------------------------------------------------------------
