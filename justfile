# ================================================================
# Justfile for Flyway Database Migrations
# Ultra-minimal version - no heredocs, no SQL parsing issues
# ================================================================

set shell := ["bash", "-uc"]
set dotenv-load := true

default:
    @just --list

# ================================================================
# Environment & Setup
# ================================================================

[private]
check-env:
    @test -f .env || (echo "Error: .env not found. Copy .env.example to .env" && exit 1)

env: check-env
    @echo "Current Environment Configuration:"
    @echo "=================================="
    @echo "Database Host: ${DB_HOST}"
    @echo "Database Port: ${DB_PORT}"
    @echo "Database Name: ${DB_NAME}"
    @echo "Database User: ${DB_USER}"
    @echo "Environment:   ${ENVIRONMENT:-dev}"
    @echo "=================================="

test-connection: check-env
    @echo "Testing database connection..."
    @psql "${DATABASE_URL}" -c "SELECT version();" > /dev/null 2>&1 && echo "Database connection successful!" || echo "Database connection failed!"

# ================================================================
# Flyway Migration Commands
# ================================================================

info: check-env
    @echo "Migration Status:"
    @flyway -configFiles=flyway.conf info

validate: check-env
    @echo "Validating migrations..."
    @flyway -configFiles=flyway.conf validate

migrate: check-env
    @echo "Running migrations..."
    @flyway -configFiles=flyway.conf migrate

migrate-to VERSION: check-env
    @echo "Migrating to version {{VERSION}}..."
    @flyway -configFiles=flyway.conf -target={{VERSION}} migrate

repair: check-env
    @echo "Repairing migration history..."
    @flyway -configFiles=flyway.conf repair

clean: check-env
    @echo "WARNING: This will DELETE all database objects!"
    @echo "Press Ctrl+C to cancel, or Enter to continue..."
    @read && flyway -configFiles=flyway.conf -cleanDisabled=false clean

baseline: check-env
    @echo "Setting baseline..."
    @flyway -configFiles=flyway.conf baseline

# ================================================================
# Database Operations
# ================================================================

backup: check-env
    @mkdir -p backups
    @echo "Creating backup..."
    @pg_dump "${DATABASE_URL}" | gzip > "backups/backup_$$(date +%Y%m%d_%H%M%S).sql.gz"
    @echo "Backup created in backups/"

restore BACKUP_FILE: check-env
    @echo "WARNING: This will REPLACE the current database!"
    @echo "Restoring from: {{BACKUP_FILE}}"
    @echo "Press Ctrl+C to cancel, or Enter to continue..."
    @read && gunzip -c {{BACKUP_FILE}} | psql "${DATABASE_URL}"
    @echo "Database restored"

psql: check-env
    @psql "${DATABASE_URL}"

query QUERY: check-env
    @psql "${DATABASE_URL}" -c "{{QUERY}}"

run-sql FILE: check-env
    @echo "Running SQL file: {{FILE}}"
    @psql "${DATABASE_URL}" -f {{FILE}}

# ================================================================
# Verification & Testing
# ================================================================

verify-lookups: check-env
    @echo "Verifying lookup data..."
    @just _check-count "roles" "lookups.roles" "10"
    @just _check-count "privileges" "lookups.privileges" "25"
    @just _check-count "role_privileges" "lookups.role_privileges" "93"
    @just _check-count "occupation_types" "lookups.occupation_types" "40"
    @just _check-count "marital_statuses" "lookups.marital_statuses" "7"
    @just _check-count "diagnosis_types" "lookups.diagnosis_types" "6"
    @just _check-count "complication_types" "lookups.complication_types" "9"
    @just _check-count "education_levels" "lookups.education_levels" "7"
    @just _check-count "medications" "lookups.medications" "15"
    @just _check-count "followup_types" "lookups.followup_types" "10"
    @just _check-count "test_types" "lookups.test_types" "15"
    @just _check-count "units" "lookups.units" "10"
    @echo "Verification complete!"

[private]
_check-count NAME TABLE EXPECTED: check-env
    @COUNT=$$(psql "${DATABASE_URL}" -t -c "SELECT COUNT(*) FROM {{TABLE}}" | xargs); \
    if [ "$$COUNT" = "{{EXPECTED}}" ]; then \
        echo "{{NAME}}: $$COUNT [OK]"; \
    else \
        echo "{{NAME}}: $$COUNT (expected {{EXPECTED}}) [FAIL]"; \
    fi

list-tables: check-env
    @echo "Tables by schema:"
    @psql "${DATABASE_URL}" -c "SELECT schemaname, COUNT(*) as table_count FROM pg_tables WHERE schemaname IN ('marts', 'staging', 'intermediate', 'seeds', 'audit', 'public') GROUP BY schemaname ORDER BY schemaname;"

check-failures: check-env
    @echo "Checking for failed migrations..."
    @psql "${DATABASE_URL}" -c "SELECT installed_rank, version, description, success FROM flyway_schema_history WHERE success = false ORDER BY installed_rank DESC;"

# ================================================================
# Development Workflows
# ================================================================

fresh: check-env
    @echo "WARNING: This will DELETE everything and start fresh!"
    @echo "Press Ctrl+C to cancel, or Enter to continue..."
    @read && just clean && just migrate && just verify-lookups

fresh-safe: check-env
    @just backup
    @just clean
    @just migrate
    @just verify-lookups
    @echo "Fresh installation complete with backup"

dev-reset: check-env
    @echo "Resetting development database..."
    @export PGPASSWORD="${DB_PASSWORD}"; \
    psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d postgres -c "DROP DATABASE IF EXISTS \"${DB_NAME}\";"; \
    psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d postgres -c "CREATE DATABASE \"${DB_NAME}\";"
    @just migrate
    @just verify-lookups
    @echo "Development database reset complete"

status: check-env
    @just info
    @echo ""
    @just verify-lookups

deploy: check-env
    @just validate
    @just migrate
    @just verify-lookups
    @echo "Deployment complete!"

# ================================================================
# Utility Commands
# ================================================================

new-migration NAME: check-env
    @bash -c 'NEXT=$$(ls -1 sql/V*.sql 2>/dev/null | sed "s/.*V0*//" | sed "s/__.*//" | sort -n | tail -1 | awk "{printf \"%03d\n\", \$$1+1}"); \
    [ -z "$$NEXT" ] && NEXT="017"; \
    FILE="sql/V$${NEXT}__{{NAME}}.sql"; \
    echo "-- Migration: V$$NEXT - {{NAME}}" > $$FILE; \
    echo "-- Description: " >> $$FILE; \
    echo "-- Date: $$(date +%Y-%m-%d)" >> $$FILE; \
    echo "" >> $$FILE; \
    echo "-- Your SQL here" >> $$FILE; \
    echo "" >> $$FILE; \
    echo "Created: $$FILE"'

version:
    @flyway -version

install-flyway:
    @echo "Installing Flyway..."
    @brew install flyway

# ================================================================
# Documentation
# ================================================================

help:
    @echo "Flyway Database Migration Commands"
    @echo "======================================"
    @echo ""
    @echo "Setup:"
    @echo "  just env              - Show environment configuration"
    @echo "  just test-connection  - Test database connection"
    @echo ""
    @echo "Migration:"
    @echo "  just info             - Show migration status"
    @echo "  just validate         - Validate migrations"
    @echo "  just migrate          - Run pending migrations"
    @echo "  just migrate-to VER   - Migrate to specific version"
    @echo "  just repair           - Repair migration history"
    @echo "  just baseline         - Baseline existing database"
    @echo ""
    @echo "Database:"
    @echo "  just psql             - Connect to database"
    @echo "  just query SQL        - Run SQL query"
    @echo "  just run-sql FILE     - Run SQL file"
    @echo "  just backup           - Create backup"
    @echo "  just restore FILE     - Restore from backup"
    @echo ""
    @echo "Verification:"
    @echo "  just verify-lookups   - Verify lookup data"
    @echo "  just list-tables      - List all tables"
    @echo "  just check-failures   - Check for failed migrations"
    @echo ""
    @echo "Workflows:"
    @echo "  just deploy           - Full deployment"
    @echo "  just fresh            - Fresh install (DANGEROUS!)"
    @echo "  just fresh-safe       - Fresh install with backup"
    @echo "  just dev-reset        - Reset dev database"
    @echo "  just status           - Quick status check"
    @echo ""
    @echo "Utility:"
    @echo "  just new-migration N  - Create new migration file"
    @echo "  just version          - Show Flyway version"
