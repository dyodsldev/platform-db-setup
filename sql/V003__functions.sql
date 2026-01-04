-- ================================================================
-- Migration: V003 - Utility Functions
-- Description: General-purpose functions for calculations,
--              validations, and data manipulation
-- ================================================================

-- ----------------------------------------------------------------
-- Function: update_updated_at_column
-- Description: Automatically update updated_at timestamp
-- Usage: CREATE TRIGGER ON table_name
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.update_updated_at_column() IS 'Trigger function to automatically update updated_at column';

-- ----------------------------------------------------------------
-- Function: calculate_age
-- Description: Calculate age from date of birth
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.calculate_age(date_of_birth DATE)
RETURNS INTEGER AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth))::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.calculate_age(DATE) IS 'Calculate age in years from date of birth';

-- ----------------------------------------------------------------
-- Function: calculate_bmi
-- Description: Calculate Body Mass Index
-- Parameters: weight in kg, height in cm
-- Returns: BMI rounded to 2 decimal places
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.calculate_bmi(
    weight_kg NUMERIC,
    height_cm NUMERIC
)
RETURNS NUMERIC AS $$
BEGIN
    IF weight_kg IS NULL OR height_cm IS NULL THEN
        RETURN NULL;
    END IF;
    
    IF height_cm = 0 THEN
        RETURN NULL;
    END IF;
    
    RETURN ROUND(
        (weight_kg / POWER((height_cm / 100.0), 2))::NUMERIC,
        2
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.calculate_bmi(NUMERIC, NUMERIC) IS 'Calculate BMI from weight (kg) and height (cm)';

-- ----------------------------------------------------------------
-- Function: calculate_egfr
-- Description: Calculate estimated Glomerular Filtration Rate
--              using CKD-EPI equation
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.calculate_egfr(
    creatinine_mg_dl NUMERIC,
    age_years INTEGER,
    is_female BOOLEAN,
    is_black BOOLEAN DEFAULT FALSE
)
RETURNS NUMERIC AS $$
DECLARE
    kappa NUMERIC;
    alpha NUMERIC;
    egfr NUMERIC;
BEGIN
    -- Kappa and alpha values based on sex
    IF is_female THEN
        kappa := 0.7;
        alpha := -0.329;
    ELSE
        kappa := 0.9;
        alpha := -0.411;
    END IF;
    
    -- CKD-EPI formula
    egfr := 141 * 
            POWER(LEAST(creatinine_mg_dl / kappa, 1), alpha) *
            POWER(GREATEST(creatinine_mg_dl / kappa, 1), -1.209) *
            POWER(0.993, age_years);
    
    -- Multiply by 1.159 if black
    IF is_black THEN
        egfr := egfr * 1.159;
    END IF;
    
    -- Multiply by 1.018 if female
    IF is_female THEN
        egfr := egfr * 1.018;
    END IF;
    
    RETURN ROUND(egfr::NUMERIC, 1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.calculate_egfr(NUMERIC, INTEGER, BOOLEAN, BOOLEAN) IS 'Calculate eGFR using CKD-EPI equation';

-- ----------------------------------------------------------------
-- Function: validate_hba1c_range
-- Description: Validate HbA1c value is within reasonable range
-- Returns: TRUE if valid, FALSE if invalid
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_hba1c_range(hba1c_value NUMERIC)
RETURNS BOOLEAN AS $$
BEGIN
    -- HbA1c should be between 3.0 and 20.0 %
    RETURN hba1c_value IS NULL OR (hba1c_value >= 3.0 AND hba1c_value <= 20.0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.validate_hba1c_range(NUMERIC) IS 'Validate HbA1c is within reasonable range (3-20%)';

-- ----------------------------------------------------------------
-- Function: validate_bp_range
-- Description: Validate blood pressure values
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_bp_range(
    systolic INTEGER,
    diastolic INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Systolic: 70-250 mmHg
    -- Diastolic: 40-150 mmHg
    -- Systolic should be greater than diastolic
    RETURN (
        (systolic IS NULL OR (systolic >= 70 AND systolic <= 250)) AND
        (diastolic IS NULL OR (diastolic >= 40 AND diastolic <= 150)) AND
        (systolic IS NULL OR diastolic IS NULL OR systolic > diastolic)
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.validate_bp_range(INTEGER, INTEGER) IS 'Validate blood pressure values are within reasonable ranges';

-- ----------------------------------------------------------------
-- Function: anonymize_text
-- Description: Anonymize text field (for GDPR right to be forgotten)
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.anonymize_text(text_value TEXT)
RETURNS TEXT AS $$
BEGIN
    IF text_value IS NULL THEN
        RETURN NULL;
    END IF;
    
    RETURN 'REDACTED_' || MD5(text_value);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.anonymize_text(TEXT) IS 'Anonymize text by replacing with hash (GDPR compliance)';

-- ----------------------------------------------------------------
-- Function: generate_patient_code
-- Description: Generate unique patient code
-- Format: P + facility code + sequential number
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_patient_code(facility_code TEXT)
RETURNS TEXT AS $$
DECLARE
    next_number INTEGER;
    patient_code TEXT;
BEGIN
    -- This is a placeholder - actual implementation would use a sequence
    -- For now, return a simple code
    RETURN 'P' || facility_code || LPAD(floor(random() * 10000)::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION public.generate_patient_code(TEXT) IS 'Generate unique patient code for a facility';
