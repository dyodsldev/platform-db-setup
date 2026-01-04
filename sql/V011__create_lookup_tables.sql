-- ================================================================
-- Migration: V011 - Create Lookup Tables
-- Description: Create all lookup/reference tables
--              This replicates what DBT creates, but in pure SQL
--              Enables fresh installs without DBT
-- ================================================================

-- ----------------------------------------------------------------
-- Create lookups schema for reference/lookup tables
-- ----------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS lookups;
COMMENT ON SCHEMA lookups IS 'Lookup and reference tables (roles, privileges, etc.)';

-- ----------------------------------------------------------------
-- Lookup Table: roles
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookups.roles (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    level INTEGER NOT NULL,
    is_system_role BOOLEAN NOT NULL DEFAULT false,
    can_access_all_facilities BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_roles_code UNIQUE (code),
    CONSTRAINT chk_roles_level CHECK (level BETWEEN 1 AND 10)
);

CREATE INDEX IF NOT EXISTS idx_roles_level ON lookups.roles(level);
CREATE INDEX IF NOT EXISTS idx_roles_system ON lookups.roles(is_system_role);

COMMENT ON TABLE lookups.roles IS 'Application roles for RBAC (doctor, nurse, admin, etc.)';
COMMENT ON COLUMN lookups.roles.level IS 'Hierarchy level: 1=highest, 6=lowest';

-- ----------------------------------------------------------------
-- Lookup Table: privileges
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookups.privileges (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    is_sensitive BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_privileges_code UNIQUE (code),
    CONSTRAINT chk_privileges_category CHECK (category IN (
        'patients', 'medical', 'lab', 'medications', 'appointments',
        'transfers', 'administration', 'data', 'analytics', 'nutrition', 'documents'
    ))
);

CREATE INDEX IF NOT EXISTS idx_privileges_category ON lookups.privileges(category);
CREATE INDEX IF NOT EXISTS idx_privileges_sensitive ON lookups.privileges(is_sensitive);

COMMENT ON TABLE lookups.privileges IS 'Granular permissions for RBAC';

-- ----------------------------------------------------------------
-- Lookup Table: role_privileges (junction table)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookups.role_privileges (
    id INTEGER PRIMARY KEY,
    role_id INTEGER NOT NULL,
    privilege_id INTEGER NOT NULL,
    granted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_role_privileges_role FOREIGN KEY (role_id) 
        REFERENCES lookups.roles(id) ON DELETE CASCADE,
    CONSTRAINT fk_role_privileges_privilege FOREIGN KEY (privilege_id) 
        REFERENCES lookups.privileges(id) ON DELETE CASCADE,
    CONSTRAINT uq_role_privileges_combo UNIQUE (role_id, privilege_id)
);

CREATE INDEX IF NOT EXISTS idx_role_privileges_role ON lookups.role_privileges(role_id);
CREATE INDEX IF NOT EXISTS idx_role_privileges_priv ON lookups.role_privileges(privilege_id);

COMMENT ON TABLE lookups.role_privileges IS 'Maps roles to their privileges';

-- ----------------------------------------------------------------
-- Lookup Table: occupation_types
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookups.occupation_types (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_occupation_types_code UNIQUE (code),
    CONSTRAINT chk_occupation_category CHECK (category IN (
        'professional', 'business', 'agriculture', 'labor', 
        'service', 'government', 'non_employed', 'other'
    ))
);

CREATE INDEX IF NOT EXISTS idx_occupation_types_category ON lookups.occupation_types(category);
CREATE INDEX IF NOT EXISTS idx_occupation_types_active ON lookups.occupation_types(is_active);
CREATE INDEX IF NOT EXISTS idx_occupation_types_name ON lookups.occupation_types(LOWER(name));

COMMENT ON TABLE lookups.occupation_types IS 'Patient occupation types for demographics';

-- ----------------------------------------------------------------
-- Lookup Table: marital_statuses
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookups.marital_statuses (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    sort_order INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_marital_statuses_code UNIQUE (code),
    CONSTRAINT uq_marital_statuses_sort UNIQUE (sort_order)
);

CREATE INDEX IF NOT EXISTS idx_marital_statuses_active ON lookups.marital_statuses(is_active);

COMMENT ON TABLE lookups.marital_statuses IS 'Patient marital status options';

-- ----------------------------------------------------------------
-- Lookup Table: diagnosis_types
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookups.diagnosis_types (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    category TEXT,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_diagnosis_types_code UNIQUE (code)
);

CREATE INDEX IF NOT EXISTS idx_diagnosis_types_active ON lookups.diagnosis_types(is_active);

COMMENT ON TABLE lookups.diagnosis_types IS 'Diabetes diagnosis types (T1DM, T2DM, GDM, etc.)';

-- ----------------------------------------------------------------
-- Lookup Table: complication_types
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookups.complication_types (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    category TEXT,
    severity_levels TEXT,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_complication_types_code UNIQUE (code)
);

CREATE INDEX IF NOT EXISTS idx_complication_types_active ON lookups.complication_types(is_active);
CREATE INDEX IF NOT EXISTS idx_complication_types_category ON lookups.complication_types(category);

COMMENT ON TABLE lookups.complication_types IS 'Diabetes complication types';

-- ----------------------------------------------------------------
-- Lookup Table: education_levels
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookups.education_levels (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    sort_order INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_education_levels_code UNIQUE (code)
);

CREATE INDEX IF NOT EXISTS idx_education_levels_active ON lookups.education_levels(is_active);

COMMENT ON TABLE lookups.education_levels IS 'Education level options';

-- ----------------------------------------------------------------
-- Lookup Table: medications
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookups.medications (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    generic_name TEXT,
    category TEXT,
    dosage_forms TEXT,
    common_dosages TEXT,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_medications_code UNIQUE (code)
);

CREATE INDEX IF NOT EXISTS idx_medications_active ON lookups.medications(is_active);
CREATE INDEX IF NOT EXISTS idx_medications_category ON lookups.medications(category);

COMMENT ON TABLE lookups.medications IS 'Medication reference list';

-- ----------------------------------------------------------------
-- Lookup Table: followup_types
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookups.followup_types (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_followup_types_code UNIQUE (code)
);

CREATE INDEX IF NOT EXISTS idx_followup_types_active ON lookups.followup_types(is_active);

COMMENT ON TABLE lookups.followup_types IS 'Patient followup appointment types';

-- ----------------------------------------------------------------
-- Lookup Table: test_types
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookups.test_types (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    category TEXT,
    unit_of_measure TEXT,
    normal_range TEXT,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_test_types_code UNIQUE (code)
);

CREATE INDEX IF NOT EXISTS idx_test_types_active ON lookups.test_types(is_active);
CREATE INDEX IF NOT EXISTS idx_test_types_category ON lookups.test_types(category);

COMMENT ON TABLE lookups.test_types IS 'Laboratory test types';

-- ----------------------------------------------------------------
-- Lookup Table: units
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookups.units (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    symbol TEXT,
    category TEXT,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_units_code UNIQUE (code)
);

CREATE INDEX IF NOT EXISTS idx_units_active ON lookups.units(is_active);

COMMENT ON TABLE lookups.units IS 'Units of measurement';

-- ----------------------------------------------------------------
-- Add updated_at triggers to all lookup tables
-- ----------------------------------------------------------------
DO $$
DECLARE
    lookup_table TEXT;
    lookup_tables TEXT[] := ARRAY[
        'roles', 'privileges', 'role_privileges', 'occupation_types', 
        'marital_statuses', 'diagnosis_types', 'complication_types',
        'education_levels', 'medications', 'followup_types', 'test_types', 'units'
    ];
BEGIN
    FOREACH lookup_table IN ARRAY lookup_tables
    LOOP
        -- Drop trigger if exists, then create
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_updated_at_%I ON lookups.%I',
            lookup_table, lookup_table
        );
        
        EXECUTE format(
            'CREATE TRIGGER trg_updated_at_%I
            BEFORE UPDATE ON lookups.%I
            FOR EACH ROW
            EXECUTE FUNCTION public.update_updated_at_column()',
            lookup_table, lookup_table
        );
    END LOOP;
END $$;