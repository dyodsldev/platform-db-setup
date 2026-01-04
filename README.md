# 🏥 DYODSL Database Setup

Database migration system for DYODSL diabetes patient management in Sri Lanka. 

---

## 📋 **Table of Contents**

- [Overview](#overview)
- [Database Schema Structure](#database-schema-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Migration Commands](#migration-commands)
- [Schema Details](#schema-details)
- [Security Features](#security-features)
- [Development Workflow](#development-workflow)
- [Troubleshooting](#troubleshooting)

---

## 🎯 **Overview**

This project provides a complete database infrastructure for a healthcare platform with:

- ✅ **Version-controlled migrations** using Flyway
- ✅ **Row-level security (RLS)** for multi-tenant data isolation
- ✅ **Comprehensive audit logging** for compliance
- ✅ **Lookup tables** for standardized reference data
- ✅ **Temporal versioning** for patient clinical data
- ✅ **Patient transfer workflow** between facilities
- ✅ **DBT integration** for data transformation from MongoDB

---

## 🗂️ **Database Schema Structure**

### **Schema Overview**

```
dyodsl_db
├── public              # Extensions and utility functions
├── platform            # Core application tables
├── lookups             # Reference/lookup tables
└── audit               # Audit trail tables
```

---

### **📊 Complete Schema Map**

```
platform         -- All application tables
  ├── facilities
  ├── users
  ├── user_facilities
  ├── patients
  ├── patient_versions
  ├── patient_transfers
  └── [all business tables]

lookups          -- Reference/lookup tables
  ├── roles
  ├── privileges
  ├── role_privileges
  ├── occupation_types
  ├── marital_statuses
  ├── diagnosis_types
  ├── complication_types
  ├── education_levels
  ├── medications
  ├── followup_types
  ├── test_types
  └── units

audit            -- System audit trail
  └── audit_log

public           -- Extensions & utility functions
  └── [shared functions]
```

---

## 🔧 **Prerequisites**

- **PostgreSQL** 14+
- **Flyway** 9.0+
- **DBT** 1.5+ (for data transformation)
- **Just** (optional, for commands)

---

## 🚀 **Quick Start**

```bash
# 1. Set database connection
cp env.example .env

# 2. Run migrations
just migrate

# 3. Verify
just info
```

---

## 📝 **Migration Commands**

```bash
just migrate          # Run all migrations
just info            # Check status
just validate        # Validate migrations
just psql            # Connect to database
just repair          # Fix checksums
just clean           # Clean database (⚠️ DESTRUCTIVE)
```

---

## 📋 **Migration Files (V001-V016)**

| Version | Description |
|---------|-------------|
| V001 | Extensions & functions |
| V002 | Schemas (public/platform/lookups/audit) |
| V003 | Database roles |
| V004 | Audit triggers |
| V005 | Update triggers |
| V006 | Enable RLS |
| V007 | RLS policies |
| V008 | App settings |
| V009 | Grants & permissions |
| V010 | Audit partitioning |
| V011 | Lookup tables |
| V012 | Lookup data |
| V013 | Core tables (facilities/users) |
| V014 | Patient tables |
| V015 | Constraints |
| V016 | Performance indexes |

---

## 🔒 **Security Features**

### **Row-Level Security (RLS)**

```sql
-- Set user context for RLS
SET app.current_user_id = 'user-uuid-here';

-- Now queries respect RLS policies
SELECT * FROM platform.patients;
```

### **Audit Trail**

```sql
-- View recent changes
SELECT * FROM audit.audit_log
WHERE table_name = 'patients'
ORDER BY changed_at DESC
LIMIT 10;
```

---

## 🛠️ **Troubleshooting**

### **RLS Blocks DBeaver GUI Editing**

```sql
-- Option 1: Use SQL instead
UPDATE platform.patients SET phone = '...' WHERE code = 'P001';

-- Option 2: Disable RLS (testing only)
ALTER TABLE platform.patients DISABLE ROW LEVEL SECURITY;
```

### **NULL Values Prevent Migration**

```sql
-- Fix NULL first_name/last_name
UPDATE platform.users
SET 
    first_name = COALESCE(first_name, username),
    last_name = COALESCE(last_name, 'User')
WHERE first_name IS NULL;
```

### **Phone Column Type Mismatch**

Update DBT model to cast to TEXT:

```sql
p.contact_number::TEXT AS phone
```

---

## 📚 **Resources**

- **Flyway**: https://flywaydb.org/
- **DBT**: https://docs.getdbt.com/
- **PostgreSQL RLS**: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
