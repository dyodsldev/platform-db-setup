-- ================================================================
-- Migration: V015 - Create Patient Tables
-- Description: Create patient tables matching DBT output schema
--              Matches actual DBT models exactly
-- ================================================================

-- ----------------------------------------------------------------
-- Table: patients (matches DBT output exactly)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS platform.patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mongodb_patient_id TEXT,
    code TEXT NOT NULL,
    
    -- Demographics
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    gender TEXT,
    date_of_birth DATE NOT NULL,
    
    -- Identification
    nic TEXT,
    passport_number TEXT,
    
    -- Contact
    phone TEXT,
    email TEXT,
    address TEXT,
    city TEXT,
    province TEXT,
    
    -- Demographics lookup references
    occupation_type_id INTEGER,
    education_level_id INTEGER,
    marital_status_id INTEGER,
    
    -- Clinical data
    diagnosis_type_id INTEGER,
    diagnosis_date DATE,
    
    -- Facility & Ownership
    current_facility_id UUID NOT NULL,
    owner_user_id UUID,
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_deceased BOOLEAN NOT NULL DEFAULT false,
    deceased_date DATE,
    
    -- Notes
    notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Optimistic locking
    version INTEGER DEFAULT 1,
    
    CONSTRAINT uq_patients_code UNIQUE (code),
    CONSTRAINT fk_patients_current_facility FOREIGN KEY (current_facility_id) 
        REFERENCES platform.facilities(id),
    CONSTRAINT fk_patients_owner FOREIGN KEY (owner_user_id) 
        REFERENCES platform.users(id),
    CONSTRAINT fk_patients_occupation FOREIGN KEY (occupation_type_id) 
        REFERENCES lookups.occupation_types(id),
    CONSTRAINT fk_patients_education FOREIGN KEY (education_level_id) 
        REFERENCES lookups.education_levels(id),
    CONSTRAINT fk_patients_marital_status FOREIGN KEY (marital_status_id) 
        REFERENCES lookups.marital_statuses(id),
    CONSTRAINT fk_patients_diagnosis_type FOREIGN KEY (diagnosis_type_id) 
        REFERENCES lookups.diagnosis_types(id),
    CONSTRAINT chk_patients_dob_past CHECK (date_of_birth <= CURRENT_DATE),
    CONSTRAINT chk_patients_deceased_after_birth CHECK (deceased_date IS NULL OR deceased_date >= date_of_birth),
    CONSTRAINT chk_patients_gender CHECK (gender IN ('M', 'F', 'O', 'U', 'Male', 'Female', 'Other', NULL)),
    CONSTRAINT chk_patients_deceased_logic CHECK (
        (is_deceased = true AND deceased_date IS NOT NULL) OR
        (is_deceased = false AND deceased_date IS NULL)
    )
);

-- Indexes matching DBT post-hooks
CREATE INDEX IF NOT EXISTS idx_patients_code ON platform.patients(code);
CREATE INDEX IF NOT EXISTS idx_patients_facility ON platform.patients(current_facility_id);
CREATE INDEX IF NOT EXISTS idx_patients_owner ON platform.patients(owner_user_id);
CREATE INDEX IF NOT EXISTS idx_patients_dob ON platform.patients(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_patients_diagnosis ON platform.patients(diagnosis_type_id);
CREATE INDEX IF NOT EXISTS idx_patients_active ON platform.patients(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_patients_deceased ON platform.patients(is_deceased) WHERE is_deceased = true;
CREATE INDEX IF NOT EXISTS idx_patients_name ON platform.patients(LOWER(last_name), LOWER(first_name));

-- Additional useful indexes
CREATE INDEX IF NOT EXISTS idx_patients_mongodb_id ON platform.patients(mongodb_patient_id) WHERE mongodb_patient_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_patients_created ON platform.patients(created_at DESC);

COMMENT ON TABLE platform.patients IS 'Patient demographic and current status information (DBT output schema)';
COMMENT ON COLUMN platform.patients.code IS 'Unique patient identifier (e.g., P001)';
COMMENT ON COLUMN platform.patients.mongodb_patient_id IS 'Reference to original MongoDB patient ID';
COMMENT ON COLUMN platform.patients.phone IS 'Primary contact number';
COMMENT ON COLUMN platform.patients.owner_user_id IS 'Primary doctor/user responsible for patient';
COMMENT ON COLUMN platform.patients.is_deceased IS 'Boolean flag derived from deceased_date in DBT';

-- ----------------------------------------------------------------
-- Table: patient_versions (temporal versioning - matches DBT exactly)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS platform.patient_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL,
    facility_id UUID,
    version_number INTEGER NOT NULL,
    
    -- Temporal validity
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    is_current BOOLEAN NOT NULL DEFAULT false,
    
    -- Visit info
    is_baseline BOOLEAN,
    visit_date DATE,
    
    -- Diagnosis
    diagnosis_code TEXT,
    
    -- Lab results - HbA1c
    hba1c_latest NUMERIC(5,2),
    hba1c_date DATE,
    
    -- Lab results - FBS (Fasting Blood Sugar)
    fbs_latest NUMERIC(6,2),
    fbs_date DATE,
    
    -- Lab results - PPBS (Post-Prandial Blood Sugar)
    ppbs_latest NUMERIC(6,2),
    ppbs_date DATE,
    
    -- Physical measurements
    weight NUMERIC(5,2),
    height NUMERIC(5,2),
    bmi NUMERIC(5,2),
    bp_systolic INTEGER,
    bp_diastolic INTEGER,
    
    -- Complications
    has_retinopathy BOOLEAN,
    has_neuropathy BOOLEAN,
    has_nephropathy BOOLEAN,
    has_cvd BOOLEAN,
    
    -- Treatment
    on_insulin BOOLEAN,
    on_oral_meds BOOLEAN,
    
    -- Education
    education_level_code TEXT,
    
    -- Extended data (JSONB for flexibility)
    lab_results_extended JSONB,
    medications_detail JSONB,
    complications_detail JSONB,
    vitals_extended JSONB,
    
    -- Notes
    clinical_notes TEXT,
    
    -- Audit trail
    source_type TEXT,
    source_id TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id UUID,
    created_by_username TEXT,
    
    CONSTRAINT fk_patient_versions_patient FOREIGN KEY (patient_id) 
        REFERENCES platform.patients(id) ON DELETE CASCADE,
    CONSTRAINT fk_patient_versions_facility FOREIGN KEY (facility_id) 
        REFERENCES platform.facilities(id),
    CONSTRAINT fk_patient_versions_created_by FOREIGN KEY (created_by_user_id) 
        REFERENCES platform.users(id),
    CONSTRAINT uq_patient_versions_patient_version UNIQUE (patient_id, version_number),
    CONSTRAINT chk_patient_versions_weight_positive CHECK (weight > 0 OR weight IS NULL),
    CONSTRAINT chk_patient_versions_height_positive CHECK (height > 0 OR height IS NULL),
    CONSTRAINT chk_patient_versions_bp_valid CHECK (
        (bp_systolic IS NULL AND bp_diastolic IS NULL) OR
        (bp_systolic > bp_diastolic AND bp_systolic BETWEEN 70 AND 250 AND bp_diastolic BETWEEN 40 AND 150)
    ),
    CONSTRAINT chk_patient_versions_temporal_valid CHECK (
        (valid_from IS NULL AND valid_to IS NULL) OR
        (valid_to IS NULL) OR
        (valid_from < valid_to)
    ),
    CONSTRAINT chk_patient_versions_source_type CHECK (source_type IN ('history', 'followup', NULL))
);

-- Indexes matching DBT post-hooks
CREATE INDEX IF NOT EXISTS idx_patient_versions_patient ON platform.patient_versions(patient_id, version_number);
CREATE INDEX IF NOT EXISTS idx_patient_versions_valid_from ON platform.patient_versions(valid_from);
CREATE INDEX IF NOT EXISTS idx_patient_versions_valid_to ON platform.patient_versions(valid_to);
CREATE INDEX IF NOT EXISTS idx_patient_versions_temporal ON platform.patient_versions(patient_id, valid_from, valid_to);
CREATE INDEX IF NOT EXISTS idx_patient_versions_baseline ON platform.patient_versions(patient_id, is_baseline) WHERE is_baseline = true;
CREATE INDEX IF NOT EXISTS idx_patient_versions_facility ON platform.patient_versions(facility_id);
CREATE INDEX IF NOT EXISTS idx_patient_versions_visit_date ON platform.patient_versions(visit_date);

-- Additional useful indexes
CREATE INDEX IF NOT EXISTS idx_patient_versions_current ON platform.patient_versions(patient_id) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_patient_versions_created ON platform.patient_versions(created_at DESC);

COMMENT ON TABLE platform.patient_versions IS 'Temporal patient history - each row is a snapshot at a point in time (DBT output schema)';
COMMENT ON COLUMN platform.patient_versions.valid_from IS 'Start of validity period for this version';
COMMENT ON COLUMN platform.patient_versions.valid_to IS 'End of validity period (NULL if current)';
COMMENT ON COLUMN platform.patient_versions.is_current IS 'True if this is the current/latest version (valid_to IS NULL)';
COMMENT ON COLUMN platform.patient_versions.is_baseline IS 'True if this is the baseline/initial measurement';
COMMENT ON COLUMN platform.patient_versions.source_type IS 'Source of this version: history or followup';
COMMENT ON COLUMN platform.patient_versions.source_id IS 'Original MongoDB record ID';

-- ----------------------------------------------------------------
-- Table: patient_transfers (facility transfer tracking - matches DBT)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS platform.patient_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL,
    from_facility_id UUID NOT NULL,
    to_facility_id UUID NOT NULL,
    from_doctor_id UUID,
    to_doctor_id UUID,
    
    -- Transfer details
    transfer_type TEXT,
    reason TEXT,
    clinical_summary TEXT,
    urgency_level TEXT,
    transport_required TEXT,
    medical_equipment_needed TEXT,
    documents_url TEXT,
    
    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending',
    requested_at TIMESTAMP,
    accepted_at TIMESTAMP,
    rejected_at TIMESTAMP,
    in_transit_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    transferred_at TIMESTAMP,
    
    -- Users involved
    requested_by_user_id UUID,
    accepted_by_user_id UUID,
    completed_by_user_id UUID,
    
    -- Rejection/cancellation tracking
    rejection_reason TEXT,
    cancellation_reason TEXT,
    
    -- Notes
    notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Optimistic locking
    version INTEGER DEFAULT 1,
    
    CONSTRAINT fk_patient_transfers_patient FOREIGN KEY (patient_id) 
        REFERENCES platform.patients(id) ON DELETE CASCADE,
    CONSTRAINT fk_patient_transfers_from_facility FOREIGN KEY (from_facility_id) 
        REFERENCES platform.facilities(id),
    CONSTRAINT fk_patient_transfers_to_facility FOREIGN KEY (to_facility_id) 
        REFERENCES platform.facilities(id),
    CONSTRAINT fk_patient_transfers_from_doctor FOREIGN KEY (from_doctor_id) 
        REFERENCES platform.users(id),
    CONSTRAINT fk_patient_transfers_to_doctor FOREIGN KEY (to_doctor_id) 
        REFERENCES platform.users(id),
    CONSTRAINT fk_patient_transfers_requested_by FOREIGN KEY (requested_by_user_id) 
        REFERENCES platform.users(id),
    CONSTRAINT fk_patient_transfers_accepted_by FOREIGN KEY (accepted_by_user_id) 
        REFERENCES platform.users(id),
    CONSTRAINT fk_patient_transfers_completed_by FOREIGN KEY (completed_by_user_id) 
        REFERENCES platform.users(id),
    CONSTRAINT chk_patient_transfers_different_facilities CHECK (from_facility_id != to_facility_id),
    CONSTRAINT chk_patient_transfers_status CHECK (status IN ('pending', 'accepted', 'rejected', 'in_transit', 'completed', 'cancelled')),
    CONSTRAINT chk_patient_transfers_transfer_type CHECK (transfer_type IN ('permanent', 'temporary', 'consultation', 'emergency', NULL)),
    CONSTRAINT chk_patient_transfers_urgency CHECK (urgency_level IN ('routine', 'urgent', 'emergency', NULL)),
    CONSTRAINT chk_patient_transfers_transport CHECK (transport_required IN ('ambulance', 'patient', 'none', NULL))
);

-- Indexes matching DBT post-hooks
CREATE INDEX IF NOT EXISTS idx_patient_transfers_patient ON platform.patient_transfers(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_transfers_from_facility ON platform.patient_transfers(from_facility_id);
CREATE INDEX IF NOT EXISTS idx_patient_transfers_to_facility ON platform.patient_transfers(to_facility_id);
CREATE INDEX IF NOT EXISTS idx_patient_transfers_status ON platform.patient_transfers(status);
CREATE INDEX IF NOT EXISTS idx_patient_transfers_requested_at ON platform.patient_transfers(requested_at);

-- Additional useful indexes
CREATE INDEX IF NOT EXISTS idx_patient_transfers_from_doctor ON platform.patient_transfers(from_doctor_id);
CREATE INDEX IF NOT EXISTS idx_patient_transfers_to_doctor ON platform.patient_transfers(to_doctor_id);
CREATE INDEX IF NOT EXISTS idx_patient_transfers_created ON platform.patient_transfers(created_at DESC);

COMMENT ON TABLE platform.patient_transfers IS 'Patient transfers between facilities - schema ready for future implementation (DBT output schema)';
COMMENT ON COLUMN platform.patient_transfers.transfer_type IS 'Transfer type: permanent, temporary, consultation, emergency';
COMMENT ON COLUMN platform.patient_transfers.urgency_level IS 'Urgency: routine, urgent, emergency';
COMMENT ON COLUMN platform.patient_transfers.transport_required IS 'Transport method: ambulance, patient, none';
COMMENT ON COLUMN platform.patient_transfers.status IS 'Status: pending, accepted, rejected, in_transit, completed, cancelled';

-- ----------------------------------------------------------------
-- Enable RLS on patient tables (policies applied later)
-- ----------------------------------------------------------------
SELECT public.enable_rls('platform', 'patients');
SELECT public.enable_rls('platform', 'patient_versions');
SELECT public.enable_rls('platform', 'patient_transfers');

-- ----------------------------------------------------------------
-- Enable audit triggers on all patient tables
-- ----------------------------------------------------------------
SELECT audit.enable_audit_trigger('platform', 'patients');
SELECT audit.enable_audit_trigger('platform', 'patient_versions');
SELECT audit.enable_audit_trigger('platform', 'patient_transfers');

-- ----------------------------------------------------------------
-- Enable version triggers on patient tables
-- ----------------------------------------------------------------
SELECT public.enable_version_trigger('platform', 'patients');
SELECT public.enable_version_trigger('platform', 'patient_transfers');

-- Note: patient_versions is immutable, no update trigger needed