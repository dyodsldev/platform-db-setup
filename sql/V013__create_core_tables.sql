-- ================================================================
-- Migration: V013 - Create Core Tables
-- Description: Create facilities, users, and user_facilities tables
--              Core tables for multi-tenant structure
-- ================================================================

-- ----------------------------------------------------------------
-- Table: facilities
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marts.facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT,
    address TEXT,
    city TEXT,
    province TEXT,
    postal_code TEXT,
    phone TEXT,
    email TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    settings JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_facilities_code UNIQUE (code)
);

CREATE INDEX IF NOT EXISTS idx_facilities_code ON marts.facilities(code);
CREATE INDEX IF NOT EXISTS idx_facilities_active ON marts.facilities(is_active);
CREATE INDEX IF NOT EXISTS idx_facilities_type ON marts.facilities(type);
CREATE INDEX IF NOT EXISTS idx_facilities_city ON marts.facilities(city);

DROP TRIGGER IF EXISTS trg_updated_at_facilities ON marts.facilities;
CREATE TRIGGER trg_updated_at_facilities
    BEFORE UPDATE ON marts.facilities
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE marts.facilities IS 'Healthcare facilities/clinics in the system';
COMMENT ON COLUMN marts.facilities.settings IS 'JSONB storage for facility-specific settings';

-- ----------------------------------------------------------------
-- Table: users
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marts.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT NOT NULL,
    email TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    role_id INTEGER,
    primary_facility_id UUID,
    phone TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_login_at TIMESTAMP,
    email_verified BOOLEAN NOT NULL DEFAULT false,
    preferences JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) 
        REFERENCES lookups.roles(id),
    CONSTRAINT fk_users_primary_facility FOREIGN KEY (primary_facility_id) 
        REFERENCES marts.facilities(id)
);

CREATE INDEX IF NOT EXISTS idx_users_username ON marts.users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON marts.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON marts.users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_primary_facility ON marts.users(primary_facility_id);
CREATE INDEX IF NOT EXISTS idx_users_active ON marts.users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_last_name ON marts.users(LOWER(last_name));

DROP TRIGGER IF EXISTS trg_updated_at_users ON marts.users;
CREATE TRIGGER trg_updated_at_users
    BEFORE UPDATE ON marts.users
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE marts.users IS 'System users (doctors, nurses, admin, etc.)';
COMMENT ON COLUMN marts.users.password_hash IS 'Bcrypt hashed password';
COMMENT ON COLUMN marts.users.preferences IS 'JSONB storage for user preferences';

-- ----------------------------------------------------------------
-- Table: user_facilities (many-to-many junction)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marts.user_facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    facility_id UUID NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT false,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_user_facilities_user FOREIGN KEY (user_id) 
        REFERENCES marts.users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_facilities_facility FOREIGN KEY (facility_id) 
        REFERENCES marts.facilities(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_facilities_assigned_by FOREIGN KEY (assigned_by) 
        REFERENCES marts.users(id),
    CONSTRAINT uq_user_facilities_combo UNIQUE (user_id, facility_id)
);

CREATE INDEX IF NOT EXISTS idx_user_facilities_user ON marts.user_facilities(user_id);
CREATE INDEX IF NOT EXISTS idx_user_facilities_facility ON marts.user_facilities(facility_id);
CREATE INDEX IF NOT EXISTS idx_user_facilities_combo ON marts.user_facilities(user_id, facility_id);
CREATE INDEX IF NOT EXISTS idx_user_facilities_primary ON marts.user_facilities(is_primary) WHERE is_primary = true;

DROP TRIGGER IF EXISTS trg_updated_at_user_facilities ON marts.user_facilities;
CREATE TRIGGER trg_updated_at_user_facilities
    BEFORE UPDATE ON marts.user_facilities
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE marts.user_facilities IS 'Maps users to their assigned facilities';
COMMENT ON COLUMN marts.user_facilities.is_primary IS 'Whether this is the user primary facility';

-- ----------------------------------------------------------------
-- Enable RLS on core tables (policies applied later)
-- ----------------------------------------------------------------
ALTER TABLE marts.facilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE marts.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE marts.user_facilities ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------
-- Enable audit triggers on core tables
-- ----------------------------------------------------------------
SELECT audit.enable_audit_trigger('marts', 'facilities');
SELECT audit.enable_audit_trigger('marts', 'users');
SELECT audit.enable_audit_trigger('marts', 'user_facilities');