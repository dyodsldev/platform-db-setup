-- ================================================================
-- Migration: V011 - Create Audit Tables
-- Description: Complete audit trail tables
-- ================================================================

-- ----------------------------------------------------------------
-- Create audit log table
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit.audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_schema TEXT NOT NULL,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL,
    
    -- User information
    username TEXT,
    application_name TEXT,
    client_address INET,
    
    -- Data changes
    old_data JSONB,
    new_data JSONB,
    changed_fields TEXT[],
    
    -- Metadata
    transaction_id BIGINT,
    performed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Named constraint (only one!)
    CONSTRAINT audit_log_operation_check CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE'))
);

CREATE INDEX IF NOT EXISTS idx_audit_log_table ON audit.audit_log(table_schema, table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_performed_at ON audit.audit_log(performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_username ON audit.audit_log(username);
CREATE INDEX IF NOT EXISTS idx_audit_log_operation ON audit.audit_log(operation);

-- Add table comment
COMMENT ON TABLE audit.audit_log IS 'Complete audit trail of all database changes';
