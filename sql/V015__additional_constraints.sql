-- ================================================================
-- Migration: V015 - Additional Constraints
-- Description: Add additional constraints matching DBT output schema
-- ================================================================

-- ----------------------------------------------------------------
-- Additional NOT NULL constraints for critical fields
-- ----------------------------------------------------------------

-- Users: Ensure critical fields are not null
ALTER TABLE platform.users 
    ALTER COLUMN username SET NOT NULL,
    ALTER COLUMN first_name SET NOT NULL,
    ALTER COLUMN last_name SET NOT NULL;

-- ----------------------------------------------------------------
-- Additional CHECK constraints
-- ----------------------------------------------------------------

-- Patients: Age validation (must be reasonable)
ALTER TABLE platform.patients 
    DROP CONSTRAINT IF EXISTS chk_patients_reasonable_age;
ALTER TABLE platform.patients 
    ADD CONSTRAINT chk_patients_reasonable_age 
    CHECK (date_of_birth >= '1900-01-01'::DATE);

-- Patients: Phone format validation (DBT uses 'phone' not 'contact_number')
ALTER TABLE platform.patients 
    DROP CONSTRAINT IF EXISTS chk_patients_phone_format;
ALTER TABLE platform.patients 
    ADD CONSTRAINT chk_patients_phone_format 
    CHECK (phone IS NULL OR phone ~ '^[0-9\+\-\(\)\s]+$');

-- Patients: Email format validation
ALTER TABLE platform.patients 
    DROP CONSTRAINT IF EXISTS chk_patients_email_format;
ALTER TABLE platform.patients 
    ADD CONSTRAINT chk_patients_email_format 
    CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$');

-- Users: Email format validation
ALTER TABLE platform.users 
    DROP CONSTRAINT IF EXISTS chk_users_email_format;
ALTER TABLE platform.users 
    ADD CONSTRAINT chk_users_email_format 
    CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$');

-- ----------------------------------------------------------------
-- Exclusion constraints for preventing overlaps
-- ----------------------------------------------------------------

-- Patient versions: Only one current version per patient
DROP INDEX IF EXISTS platform.idx_patient_versions_one_current;
CREATE UNIQUE INDEX idx_patient_versions_one_current 
    ON platform.patient_versions(patient_id) 
    WHERE is_current = true;

-- ----------------------------------------------------------------
-- Comments on constraints
-- ----------------------------------------------------------------

COMMENT ON CONSTRAINT chk_patients_reasonable_age ON platform.patients IS 
'Ensures date of birth is after 1900 (reasonable age validation)';

COMMENT ON CONSTRAINT chk_patients_phone_format ON platform.patients IS 
'Basic validation for phone number format (allows +, -, (), spaces, and digits)';

COMMENT ON CONSTRAINT chk_patients_email_format ON platform.patients IS 
'Validates email format using regex pattern';

COMMENT ON CONSTRAINT chk_users_email_format ON platform.users IS 
'Validates email format using regex pattern';