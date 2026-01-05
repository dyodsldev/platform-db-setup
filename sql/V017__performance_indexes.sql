-- ================================================================
-- Migration: V016 - Performance Indexes
-- Description: Performance indexes matching DBT output schema
-- ================================================================

-- ================================================================
-- PATIENTS TABLE INDEXES
-- ================================================================

-- Composite index for facility + active patients (common query pattern)
CREATE INDEX IF NOT EXISTS idx_patients_facility_active 
    ON platform.patients(current_facility_id, is_active) 
    WHERE is_active = true;

-- Composite index for facility + owner (doctor's patient list)
CREATE INDEX IF NOT EXISTS idx_patients_facility_owner 
    ON platform.patients(current_facility_id, owner_user_id) 
    WHERE is_active = true;

-- Index for patient search by full name
CREATE INDEX IF NOT EXISTS idx_patients_fullname 
    ON platform.patients(LOWER(first_name || ' ' || last_name));

-- Index for diagnosis type analysis
CREATE INDEX IF NOT EXISTS idx_patients_diagnosis_analysis
    ON platform.patients(diagnosis_type_id, is_active)
    WHERE diagnosis_type_id IS NOT NULL;

-- Composite index for demographics analysis
CREATE INDEX IF NOT EXISTS idx_patients_demographics 
    ON platform.patients(occupation_type_id, education_level_id, marital_status_id) 
    WHERE is_active = true;

-- Index for diagnosis date range queries
CREATE INDEX IF NOT EXISTS idx_patients_diagnosis_date_range
    ON platform.patients(diagnosis_date DESC) 
    WHERE diagnosis_date IS NOT NULL;

-- Index for MongoDB patient ID lookups
CREATE INDEX IF NOT EXISTS idx_patients_mongodb_lookup
    ON platform.patients(mongodb_patient_id)
    WHERE mongodb_patient_id IS NOT NULL;

-- Index for phone number searches
CREATE INDEX IF NOT EXISTS idx_patients_phone_search
    ON platform.patients(phone) 
    WHERE phone IS NOT NULL;

-- Index for email searches
CREATE INDEX IF NOT EXISTS idx_patients_email_search
    ON platform.patients(LOWER(email)) 
    WHERE email IS NOT NULL;

-- Partial index for deceased patients with date
CREATE INDEX IF NOT EXISTS idx_patients_deceased_with_date
    ON platform.patients(deceased_date DESC) 
    WHERE is_deceased = true;

-- Partial index for active patients by age (birth year)
CREATE INDEX IF NOT EXISTS idx_patients_active_by_birthyear
    ON platform.patients(date_of_birth, current_facility_id) 
    WHERE is_active = true;

-- Trigram index for fuzzy name search (requires pg_trgm extension)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
        CREATE INDEX IF NOT EXISTS idx_patients_name_trgm 
            ON platform.patients USING gin ((first_name || ' ' || last_name) gin_trgm_ops);
    END IF;
END $$;

-- ================================================================
-- PATIENT_VERSIONS TABLE INDEXES (Temporal + Clinical Data)
-- ================================================================

-- Composite index for temporal range queries
CREATE INDEX IF NOT EXISTS idx_patient_versions_temporal_range
    ON platform.patient_versions(patient_id, valid_from DESC, valid_to DESC);

-- Index for current versions only
CREATE INDEX IF NOT EXISTS idx_patient_versions_current_only
    ON platform.patient_versions(patient_id, version_number DESC)
    WHERE is_current = true;

-- Index for baseline measurements
CREATE INDEX IF NOT EXISTS idx_patient_versions_baseline_lookup
    ON platform.patient_versions(patient_id, visit_date)
    WHERE is_baseline = true;

-- Index for visit date queries
CREATE INDEX IF NOT EXISTS idx_patient_versions_visit_timeline
    ON platform.patient_versions(patient_id, visit_date DESC)
    WHERE visit_date IS NOT NULL;

-- Facility-specific indexes
CREATE INDEX IF NOT EXISTS idx_patient_versions_facility_visits
    ON platform.patient_versions(facility_id, visit_date DESC)
    WHERE facility_id IS NOT NULL;

-- ================================================================
-- LAB RESULTS INDEXES
-- ================================================================

-- HbA1c tracking
CREATE INDEX IF NOT EXISTS idx_patient_versions_hba1c_high
    ON platform.patient_versions(patient_id, hba1c_latest DESC, hba1c_date DESC)
    WHERE hba1c_latest >= 7.0;

CREATE INDEX IF NOT EXISTS idx_patient_versions_hba1c_timeline
    ON platform.patient_versions(patient_id, hba1c_date DESC)
    WHERE hba1c_latest IS NOT NULL;

-- FBS (Fasting Blood Sugar) tracking
CREATE INDEX IF NOT EXISTS idx_patient_versions_fbs_high
    ON platform.patient_versions(patient_id, fbs_latest DESC, fbs_date DESC)
    WHERE fbs_latest >= 126;

CREATE INDEX IF NOT EXISTS idx_patient_versions_fbs_timeline
    ON platform.patient_versions(patient_id, fbs_date DESC)
    WHERE fbs_latest IS NOT NULL;

-- PPBS (Post-Prandial Blood Sugar) tracking
CREATE INDEX IF NOT EXISTS idx_patient_versions_ppbs_high
    ON platform.patient_versions(patient_id, ppbs_latest DESC, ppbs_date DESC)
    WHERE ppbs_latest >= 200;

CREATE INDEX IF NOT EXISTS idx_patient_versions_ppbs_timeline
    ON platform.patient_versions(patient_id, ppbs_date DESC)
    WHERE ppbs_latest IS NOT NULL;

-- ================================================================
-- PHYSICAL MEASUREMENTS INDEXES
-- ================================================================

-- BMI tracking
CREATE INDEX IF NOT EXISTS idx_patient_versions_bmi_high
    ON platform.patient_versions(patient_id, bmi DESC, visit_date DESC)
    WHERE bmi >= 25.0;

CREATE INDEX IF NOT EXISTS idx_patient_versions_bmi_obese_asian
    ON platform.patient_versions(patient_id, bmi DESC)
    WHERE bmi >= 27.5;  -- Asian obesity threshold

-- Weight tracking
CREATE INDEX IF NOT EXISTS idx_patient_versions_weight_timeline
    ON platform.patient_versions(patient_id, weight DESC, visit_date DESC)
    WHERE weight IS NOT NULL;

-- Blood pressure tracking
CREATE INDEX IF NOT EXISTS idx_patient_versions_bp_uncontrolled
    ON platform.patient_versions(patient_id, bp_systolic DESC, bp_diastolic DESC, visit_date DESC)
    WHERE bp_systolic >= 140 OR bp_diastolic >= 90;

CREATE INDEX IF NOT EXISTS idx_patient_versions_bp_hypertension_stage2
    ON platform.patient_versions(patient_id, bp_systolic DESC, visit_date DESC)
    WHERE bp_systolic >= 160 OR bp_diastolic >= 100;

-- ================================================================
-- COMPLICATIONS INDEXES
-- ================================================================

-- Composite complications tracking
CREATE INDEX IF NOT EXISTS idx_patient_versions_complications
    ON platform.patient_versions(patient_id, visit_date DESC)
    WHERE has_retinopathy = true 
       OR has_neuropathy = true 
       OR has_nephropathy = true 
       OR has_cvd = true;

-- Individual complication indexes
CREATE INDEX IF NOT EXISTS idx_patient_versions_retinopathy
    ON platform.patient_versions(patient_id, visit_date DESC)
    WHERE has_retinopathy = true;

CREATE INDEX IF NOT EXISTS idx_patient_versions_neuropathy
    ON platform.patient_versions(patient_id, visit_date DESC)
    WHERE has_neuropathy = true;

CREATE INDEX IF NOT EXISTS idx_patient_versions_nephropathy
    ON platform.patient_versions(patient_id, visit_date DESC)
    WHERE has_nephropathy = true;

CREATE INDEX IF NOT EXISTS idx_patient_versions_cvd
    ON platform.patient_versions(patient_id, visit_date DESC)
    WHERE has_cvd = true;

-- ================================================================
-- TREATMENT INDEXES
-- ================================================================

-- Treatment type tracking
CREATE INDEX IF NOT EXISTS idx_patient_versions_on_insulin
    ON platform.patient_versions(patient_id, visit_date DESC)
    WHERE on_insulin = true;

CREATE INDEX IF NOT EXISTS idx_patient_versions_on_oral_meds
    ON platform.patient_versions(patient_id, visit_date DESC)
    WHERE on_oral_meds = true;

CREATE INDEX IF NOT EXISTS idx_patient_versions_combined_therapy
    ON platform.patient_versions(patient_id, visit_date DESC)
    WHERE on_insulin = true AND on_oral_meds = true;

-- ================================================================
-- JSONB EXTENDED DATA INDEXES
-- ================================================================

-- GIN indexes for JSONB fields (flexible querying)
CREATE INDEX IF NOT EXISTS idx_patient_versions_lab_results_extended_gin 
    ON platform.patient_versions USING gin (lab_results_extended);

CREATE INDEX IF NOT EXISTS idx_patient_versions_medications_detail_gin 
    ON platform.patient_versions USING gin (medications_detail);

CREATE INDEX IF NOT EXISTS idx_patient_versions_complications_detail_gin 
    ON platform.patient_versions USING gin (complications_detail);

CREATE INDEX IF NOT EXISTS idx_patient_versions_vitals_extended_gin 
    ON platform.patient_versions USING gin (vitals_extended);

-- ================================================================
-- AUDIT & SOURCE TRACKING INDEXES
-- ================================================================

-- Source tracking
CREATE INDEX IF NOT EXISTS idx_patient_versions_source_type
    ON platform.patient_versions(source_type, visit_date DESC)
    WHERE source_type IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_patient_versions_source_id
    ON platform.patient_versions(source_id)
    WHERE source_id IS NOT NULL;

-- Created by user tracking
CREATE INDEX IF NOT EXISTS idx_patient_versions_created_by
    ON platform.patient_versions(created_by_user_id, created_at DESC)
    WHERE created_by_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_patient_versions_created_by_username
    ON platform.patient_versions(created_by_username, created_at DESC)
    WHERE created_by_username IS NOT NULL;

-- ================================================================
-- PATIENT_TRANSFERS TABLE INDEXES (Comprehensive Transfer Workflow)
-- ================================================================

-- Status-based workflow indexes
CREATE INDEX IF NOT EXISTS idx_patient_transfers_pending
    ON platform.patient_transfers(requested_at DESC)
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_patient_transfers_in_transit
    ON platform.patient_transfers(in_transit_at DESC)
    WHERE status = 'in_transit';

CREATE INDEX IF NOT EXISTS idx_patient_transfers_completed
    ON platform.patient_transfers(completed_at DESC)
    WHERE status = 'completed';

-- Facility-based indexes for pending transfers
CREATE INDEX IF NOT EXISTS idx_patient_transfers_pending_to_facility
    ON platform.patient_transfers(to_facility_id, requested_at DESC)
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_patient_transfers_pending_from_facility
    ON platform.patient_transfers(from_facility_id, requested_at DESC)
    WHERE status = 'pending';

-- Doctor assignment indexes
CREATE INDEX IF NOT EXISTS idx_patient_transfers_from_doctor
    ON platform.patient_transfers(from_doctor_id, requested_at DESC)
    WHERE from_doctor_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_patient_transfers_to_doctor
    ON platform.patient_transfers(to_doctor_id, requested_at DESC)
    WHERE to_doctor_id IS NOT NULL;

-- Urgency-based indexes
CREATE INDEX IF NOT EXISTS idx_patient_transfers_urgent
    ON platform.patient_transfers(requested_at DESC, from_facility_id)
    WHERE urgency_level IN ('urgent', 'emergency');

CREATE INDEX IF NOT EXISTS idx_patient_transfers_emergency
    ON platform.patient_transfers(requested_at DESC)
    WHERE urgency_level = 'emergency' AND status IN ('pending', 'accepted', 'in_transit');

-- Transfer type analysis
CREATE INDEX IF NOT EXISTS idx_patient_transfers_by_type
    ON platform.patient_transfers(transfer_type, requested_at DESC)
    WHERE transfer_type IS NOT NULL;

-- Transport coordination
CREATE INDEX IF NOT EXISTS idx_patient_transfers_ambulance_needed
    ON platform.patient_transfers(requested_at DESC, from_facility_id, to_facility_id)
    WHERE transport_required = 'ambulance' AND status IN ('pending', 'accepted');

-- User action tracking
CREATE INDEX IF NOT EXISTS idx_patient_transfers_requested_by
    ON platform.patient_transfers(requested_by_user_id, requested_at DESC)
    WHERE requested_by_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_patient_transfers_accepted_by
    ON platform.patient_transfers(accepted_by_user_id, accepted_at DESC)
    WHERE accepted_by_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_patient_transfers_completed_by
    ON platform.patient_transfers(completed_by_user_id, completed_at DESC)
    WHERE completed_by_user_id IS NOT NULL;

-- Patient transfer history
CREATE INDEX IF NOT EXISTS idx_patient_transfers_patient_history
    ON platform.patient_transfers(patient_id, requested_at DESC);

-- Timeline tracking
CREATE INDEX IF NOT EXISTS idx_patient_transfers_timeline
    ON platform.patient_transfers(
        requested_at DESC, 
        accepted_at DESC, 
        in_transit_at DESC, 
        completed_at DESC
    );

-- Rejection/cancellation tracking
CREATE INDEX IF NOT EXISTS idx_patient_transfers_rejected
    ON platform.patient_transfers(rejected_at DESC)
    WHERE status = 'rejected';

CREATE INDEX IF NOT EXISTS idx_patient_transfers_cancelled
    ON platform.patient_transfers(cancelled_at DESC)
    WHERE status = 'cancelled';

-- ================================================================
-- FACILITIES TABLE INDEXES (Additional)
-- ================================================================

-- Partial index for active facilities
CREATE INDEX IF NOT EXISTS idx_facilities_active 
    ON platform.facilities(name) 
    WHERE is_active = true;

-- Index for facility type filtering
CREATE INDEX IF NOT EXISTS idx_facilities_type 
    ON platform.facilities(type) 
    WHERE type IS NOT NULL;

-- ================================================================
-- USERS TABLE INDEXES (Additional)
-- ================================================================

-- Composite index for active users by facility
CREATE INDEX IF NOT EXISTS idx_users_facility_active 
    ON platform.users(primary_facility_id, is_active) 
    WHERE is_active = true;

-- Index for role-based queries
CREATE INDEX IF NOT EXISTS idx_users_role_active
    ON platform.users(role_id, is_active) 
    WHERE is_active = true;

-- Index for MongoDB user ID lookups
CREATE INDEX IF NOT EXISTS idx_users_mongodb_lookup
    ON platform.users(mongodb_user_id)
    WHERE mongodb_user_id IS NOT NULL;

-- ================================================================
-- USER_FACILITIES TABLE INDEXES (Additional)
-- ================================================================

-- Composite index for user's assigned facilities
CREATE INDEX IF NOT EXISTS idx_user_facilities_user_active 
    ON platform.user_facilities(user_id, facility_id) 
    WHERE is_active = true;

-- Reverse index for facility's assigned users
CREATE INDEX IF NOT EXISTS idx_user_facilities_facility_users 
    ON platform.user_facilities(facility_id, user_id) 
    WHERE is_active = true;

-- ================================================================
-- MAINTENANCE
-- ================================================================

-- Run ANALYZE after creating indexes to update statistics
ANALYZE platform.patients;
ANALYZE platform.patient_versions;
ANALYZE platform.patient_transfers;
ANALYZE platform.facilities;
ANALYZE platform.users;
ANALYZE platform.user_facilities;

-- ================================================================
-- INDEX MONITORING NOTES
-- ================================================================
-- Monitor index usage with:
-- 
-- SELECT 
--     schemaname, 
--     tablename, 
--     indexname, 
--     idx_scan,
--     idx_tup_read,
--     idx_tup_fetch,
--     pg_size_pretty(pg_relation_size(indexrelid)) as index_size
-- FROM pg_stat_user_indexes 
-- WHERE schemaname = 'platform'
-- ORDER BY idx_scan;
--
-- Drop unused indexes if idx_scan remains 0 after reasonable time
-- Consider index size vs. usage when evaluating performance impact
-- ================================================================