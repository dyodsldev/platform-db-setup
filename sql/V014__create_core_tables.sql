-- ================================================================
-- Migration: V014 - Create Core Tables
-- Description: Create facilities, users, and user_facilities tables
--              Core tables for multi-tenant structure
-- ================================================================

-- ----------------------------------------------------------------
-- Table: facilities
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS platform.facilities (
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

    -- Optimistic locking
    version INTEGER DEFAULT 1,
    
    CONSTRAINT uq_facilities_code UNIQUE (code)
);

CREATE INDEX IF NOT EXISTS idx_facilities_code ON platform.facilities(code);
CREATE INDEX IF NOT EXISTS idx_facilities_active ON platform.facilities(is_active);
CREATE INDEX IF NOT EXISTS idx_facilities_type ON platform.facilities(type);
CREATE INDEX IF NOT EXISTS idx_facilities_city ON platform.facilities(city);

COMMENT ON TABLE platform.facilities IS 'Healthcare facilities/clinics in the system';
COMMENT ON COLUMN platform.facilities.settings IS 'JSONB storage for facility-specific settings';

-- ----------------------------------------------------------------
-- Table: users
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS platform.users (

    -- Identity
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_id TEXT UNIQUE NOT NULL,
    
    -- Profile
    username TEXT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,

    -- Application data
    role_id INTEGER,
    preferences JSONB,
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_login_at TIMESTAMP,
    
    -- Soft delete (NEVER NULL these out)
    deleted_at TIMESTAMP,
    deleted_by TEXT, -- clerk_id
    deletion_reason TEXT,
    archived_data JSONB, -- Original data before anonymization

    -- Deactivation tracking
    deactivated_at TIMESTAMP,
    deactivated_by TEXT, -- clerk_id
    deactivation_reason TEXT,
    deactivation_notes TEXT, -- Additional context
    
    -- Reactivation tracking
    reactivated_at TIMESTAMP,
    reactivated_by TEXT, -- clerk_id
    reactivation_notes TEXT,
    
    -- Count deactivations (for pattern detection)
    deactivation_count INTEGER DEFAULT 0,

    -- Audit
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,

    -- Optimistic locking
    version INTEGER DEFAULT 1,

    -- Constraints
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT uq_users_clerk_id UNIQUE (clerk_id),
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) 
        REFERENCES lookups.roles(id)
);

CREATE INDEX IF NOT EXISTS idx_users_username ON platform.users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON platform.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON platform.users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_active ON platform.users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_last_name ON platform.users(LOWER(last_name));
CREATE INDEX IF NOT EXISTS idx_users_active_not_deleted ON platform.users(is_active) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_deleted ON platform.users(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_deactivated ON platform.users(deactivated_at) WHERE deactivated_at IS NOT NULL AND is_active = false;
CREATE INDEX IF NOT EXISTS idx_users_active_not_deactivated ON platform.users(is_active) WHERE is_active = true AND deleted_at IS NULL;

COMMENT ON TABLE platform.users IS 'System users (doctors, nurses, admin, etc.)';
COMMENT ON COLUMN platform.users.password_hash IS 'Bcrypt hashed password';
COMMENT ON COLUMN platform.users.preferences IS 'JSONB storage for user preferences';

-- ----------------------------------------------------------------
-- Table: user_facilities (many-to-many junction)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS platform.user_facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    facility_id UUID NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT false,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Optimistic locking
    version INTEGER DEFAULT 1,

    CONSTRAINT fk_user_facilities_user FOREIGN KEY (user_id) 
        REFERENCES platform.users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_facilities_facility FOREIGN KEY (facility_id) 
        REFERENCES platform.facilities(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_facilities_assigned_by FOREIGN KEY (assigned_by) 
        REFERENCES platform.users(id),
    CONSTRAINT uq_user_facilities_combo UNIQUE (user_id, facility_id)
);

CREATE INDEX IF NOT EXISTS idx_user_facilities_user ON platform.user_facilities(user_id);
CREATE INDEX IF NOT EXISTS idx_user_facilities_facility ON platform.user_facilities(facility_id);
CREATE INDEX IF NOT EXISTS idx_user_facilities_combo ON platform.user_facilities(user_id, facility_id);
CREATE INDEX IF NOT EXISTS idx_user_facilities_primary ON platform.user_facilities(is_primary) WHERE is_primary = true;

COMMENT ON TABLE platform.user_facilities IS 'Maps users to their assigned facilities';
COMMENT ON COLUMN platform.user_facilities.is_primary IS 'Whether this is the user primary facility';

-- ----------------------------------------------------------------
-- Enable RLS on core tables (policies applied later)
-- ----------------------------------------------------------------
SELECT public.enable_rls('platform', 'facilities');
SELECT public.enable_rls('platform', 'users');
SELECT public.enable_rls('platform', 'user_facilities');

-- ----------------------------------------------------------------
-- Enable audit triggers on core tables
-- ----------------------------------------------------------------
SELECT audit.enable_audit_trigger('platform', 'facilities');
SELECT audit.enable_audit_trigger('platform', 'users');
SELECT audit.enable_audit_trigger('platform', 'user_facilities');

-- ----------------------------------------------------------------
-- Enable version triggers on core tables
-- ----------------------------------------------------------------
SELECT public.enable_version_trigger('platform', 'users');
SELECT public.enable_version_trigger('platform', 'user_facilities');
SELECT public.enable_version_trigger('platform', 'facilities');
