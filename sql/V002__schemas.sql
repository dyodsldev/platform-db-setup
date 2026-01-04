-- ================================================================
-- Migration: V002 - Create Database Schemas
-- Description: Create schemas for application
-- ================================================================

-- ----------------------------------------------------------------
-- Application Schema - Core business tables
-- ----------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS platform;
COMMENT ON SCHEMA platform IS 'Core application tables - facilities, users, patients';

-- ----------------------------------------------------------------
-- Lookups Schema - Reference/lookup tables
-- ----------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS lookups;
COMMENT ON SCHEMA lookups IS 'Reference and lookup tables - roles, medications, diagnoses';

-- ----------------------------------------------------------------
-- Audit Schema - System audit trail
-- ----------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS 'Audit trail for all table changes';

-- ----------------------------------------------------------------
-- Note: 'public' schema already exists by default
-- Used for: Extensions, shared utility functions
-- ----------------------------------------------------------------
COMMENT ON SCHEMA public IS 'Extensions and shared utility functions';