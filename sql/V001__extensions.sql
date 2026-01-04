-- ================================================================
-- Migration: V001 - Install PostgreSQL Extensions
-- Description: Install required extensions for UUID generation,
--              encryption, and full-text search
-- ================================================================

-- UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Cryptographic functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Trigram similarity for fuzzy search
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Statistical analysis
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Comments
COMMENT ON EXTENSION "uuid-ossp" IS 'Generate UUIDs for primary keys';
COMMENT ON EXTENSION "pgcrypto" IS 'Cryptographic functions for password hashing';
COMMENT ON EXTENSION "pg_trgm" IS 'Trigram similarity for fuzzy text search';
COMMENT ON EXTENSION "pg_stat_statements" IS 'Query performance tracking';