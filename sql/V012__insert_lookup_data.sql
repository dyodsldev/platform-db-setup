-- ================================================================
-- Migration: V012 - Insert Lookup Data
-- Description: Insert all reference data into lookup tables
--              Complete dataset for fresh installations
-- ================================================================

-- ----------------------------------------------------------------
-- INSERT: roles (10 rows)
-- ----------------------------------------------------------------
INSERT INTO lookups.roles (id, code, name, description, level, is_system_role, can_access_all_facilities, created_at, updated_at) VALUES
(1, 'SYS_ADMIN', 'System Administrator', 'Full system access across all facilities', 1, true, true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(2, 'FAC_ADMIN', 'Facility Administrator', 'Manage facility users and settings', 2, false, false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(3, 'DOCTOR', 'Doctor', 'Full patient care access within assigned facilities', 3, false, false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(4, 'NURSE', 'Nurse', 'Patient care and data entry', 3, false, false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(5, 'LAB_TECH', 'Laboratory Technician', 'Lab results entry and management', 4, false, false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(6, 'PHARMACIST', 'Pharmacist', 'Medication management and dispensing', 4, false, false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(7, 'DATA_ENTRY', 'Data Entry Clerk', 'Patient data entry and basic updates', 5, false, false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(8, 'RECEPTIONIST', 'Receptionist', 'Patient registration and appointment scheduling', 5, false, false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(9, 'ANALYST', 'Data Analyst', 'Read-only access for analytics and reporting', 6, false, true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(10, 'NUTRITIONIST', 'Nutritionist', 'Diet planning and nutrition counseling', 4, false, false, '2024-01-01 00:00:00', '2024-01-01 00:00:00')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------
-- INSERT: privileges (25 rows)
-- ----------------------------------------------------------------
INSERT INTO lookups.privileges (id, code, name, category, description, is_sensitive, created_at, updated_at) VALUES
(1, 'VIEW_PATIENT', 'View Patient Records', 'patients', 'Can view patient demographic and medical information', true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(2, 'CREATE_PATIENT', 'Create Patient Records', 'patients', 'Can register new patients in the system', false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(3, 'EDIT_PATIENT', 'Edit Patient Records', 'patients', 'Can modify patient demographic information', true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(4, 'DELETE_PATIENT', 'Delete Patient Records', 'patients', 'Can delete patient records (restricted)', true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(5, 'VIEW_MEDICAL_HISTORY', 'View Medical History', 'medical', 'Can view patient medical history and clinical notes', true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(6, 'EDIT_MEDICAL_HISTORY', 'Edit Medical History', 'medical', 'Can add/edit medical history entries', true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(7, 'VIEW_LAB_RESULTS', 'View Lab Results', 'lab', 'Can view laboratory test results', true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(8, 'ENTER_LAB_RESULTS', 'Enter Lab Results', 'lab', 'Can enter and update lab test results', false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(9, 'VIEW_PRESCRIPTIONS', 'View Prescriptions', 'medications', 'Can view patient prescriptions', true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(10, 'CREATE_PRESCRIPTION', 'Create Prescriptions', 'medications', 'Can write new prescriptions', false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(11, 'DISPENSE_MEDICATION', 'Dispense Medications', 'medications', 'Can mark medications as dispensed', false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(12, 'MANAGE_APPOINTMENTS', 'Manage Appointments', 'appointments', 'Can schedule and manage appointments', false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(13, 'TRANSFER_PATIENT', 'Transfer Patient', 'transfers', 'Can initiate patient transfers between facilities', false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(14, 'APPROVE_TRANSFER', 'Approve Patient Transfer', 'transfers', 'Can approve incoming patient transfers', false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(15, 'MANAGE_USERS', 'Manage Users', 'administration', 'Can create and manage user accounts', true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(16, 'MANAGE_FACILITY', 'Manage Facility Settings', 'administration', 'Can configure facility-level settings', false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(17, 'VIEW_AUDIT_LOGS', 'View Audit Logs', 'administration', 'Can view system audit trail', true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(18, 'EXPORT_DATA', 'Export Data', 'data', 'Can export patient data (GDPR compliance)', true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(19, 'VIEW_ANALYTICS', 'View Analytics Dashboard', 'analytics', 'Can access reports and analytics dashboards', false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(20, 'MANAGE_LOOKUPS', 'Manage Lookup Tables', 'administration', 'Can edit lookup tables and reference data', false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(21, 'VIEW_ALL_FACILITIES', 'View All Facilities Data', 'administration', 'Can view data across all facilities', true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(22, 'CREATE_DIET_PLAN', 'Create Diet Plans', 'nutrition', 'Can create and manage patient diet plans', false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(23, 'VIEW_DOCUMENTS', 'View Patient Documents', 'documents', 'Can view uploaded patient documents', true, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(24, 'UPLOAD_DOCUMENTS', 'Upload Patient Documents', 'documents', 'Can upload patient-related documents', false, '2024-01-01 00:00:00', '2024-01-01 00:00:00'),
(25, 'ANONYMIZE_PATIENT', 'Anonymize Patient Data', 'administration', 'Can anonymize patient data (GDPR right to be forgotten)', true, '2024-01-01 00:00:00', '2024-01-01 00:00:00')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------
-- INSERT: role_privileges (93 rows)
-- ----------------------------------------------------------------
INSERT INTO lookups.role_privileges (id, role_id, privilege_id, granted_at) VALUES
-- System Administrator (all 25 privileges)
(1,1,1,'2024-01-01'),(2,1,2,'2024-01-01'),(3,1,3,'2024-01-01'),(4,1,4,'2024-01-01'),(5,1,5,'2024-01-01'),
(6,1,6,'2024-01-01'),(7,1,7,'2024-01-01'),(8,1,8,'2024-01-01'),(9,1,9,'2024-01-01'),(10,1,10,'2024-01-01'),
(11,1,11,'2024-01-01'),(12,1,12,'2024-01-01'),(13,1,13,'2024-01-01'),(14,1,14,'2024-01-01'),(15,1,15,'2024-01-01'),
(16,1,16,'2024-01-01'),(17,1,17,'2024-01-01'),(18,1,18,'2024-01-01'),(19,1,19,'2024-01-01'),(20,1,20,'2024-01-01'),
(21,1,21,'2024-01-01'),(22,1,22,'2024-01-01'),(23,1,23,'2024-01-01'),(24,1,24,'2024-01-01'),(25,1,25,'2024-01-01'),
-- Facility Administrator
(26,2,1,'2024-01-01'),(27,2,2,'2024-01-01'),(28,2,3,'2024-01-01'),(29,2,5,'2024-01-01'),(30,2,7,'2024-01-01'),
(31,2,9,'2024-01-01'),(32,2,12,'2024-01-01'),(33,2,13,'2024-01-01'),(34,2,14,'2024-01-01'),(35,2,15,'2024-01-01'),
(36,2,16,'2024-01-01'),(37,2,19,'2024-01-01'),(38,2,23,'2024-01-01'),(39,2,24,'2024-01-01'),
-- Doctor
(40,3,1,'2024-01-01'),(41,3,2,'2024-01-01'),(42,3,3,'2024-01-01'),(43,3,5,'2024-01-01'),(44,3,6,'2024-01-01'),
(45,3,7,'2024-01-01'),(46,3,9,'2024-01-01'),(47,3,10,'2024-01-01'),(48,3,12,'2024-01-01'),(49,3,13,'2024-01-01'),
(50,3,14,'2024-01-01'),(51,3,19,'2024-01-01'),(52,3,23,'2024-01-01'),(53,3,24,'2024-01-01'),
-- Nurse
(54,4,1,'2024-01-01'),(55,4,2,'2024-01-01'),(56,4,3,'2024-01-01'),(57,4,5,'2024-01-01'),(58,4,6,'2024-01-01'),
(59,4,7,'2024-01-01'),(60,4,8,'2024-01-01'),(61,4,9,'2024-01-01'),(62,4,12,'2024-01-01'),(63,4,23,'2024-01-01'),
(64,4,24,'2024-01-01'),
-- Lab Technician
(65,5,1,'2024-01-01'),(66,5,7,'2024-01-01'),(67,5,8,'2024-01-01'),(68,5,23,'2024-01-01'),
-- Pharmacist
(69,6,1,'2024-01-01'),(70,6,9,'2024-01-01'),(71,6,11,'2024-01-01'),(72,6,23,'2024-01-01'),
-- Data Entry Clerk
(73,7,1,'2024-01-01'),(74,7,2,'2024-01-01'),(75,7,3,'2024-01-01'),(76,7,5,'2024-01-01'),(77,7,6,'2024-01-01'),
(78,7,23,'2024-01-01'),
-- Receptionist
(79,8,1,'2024-01-01'),(80,8,2,'2024-01-01'),(81,8,12,'2024-01-01'),
-- Analyst
(82,9,1,'2024-01-01'),(83,9,5,'2024-01-01'),(84,9,7,'2024-01-01'),(85,9,9,'2024-01-01'),(86,9,19,'2024-01-01'),
(87,9,21,'2024-01-01'),(88,9,23,'2024-01-01'),
-- Nutritionist
(89,10,1,'2024-01-01'),(90,10,5,'2024-01-01'),(91,10,7,'2024-01-01'),(92,10,22,'2024-01-01'),(93,10,23,'2024-01-01')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------
-- INSERT: occupation_types (40 rows)
-- ----------------------------------------------------------------
INSERT INTO lookups.occupation_types (id, code, name, category, description, is_active) VALUES
(1,'PROFESSIONAL','Professional','professional','Professional occupations requiring higher education',true),
(2,'DOCTOR','Doctor/Physician','professional','Medical doctors and physicians',true),
(3,'NURSE','Nurse','professional','Registered nurses and nursing professionals',true),
(4,'TEACHER','Teacher/Educator','professional','School teachers and educators',true),
(5,'ENGINEER','Engineer','professional','Engineering professionals',true),
(6,'ACCOUNTANT','Accountant','professional','Accountants and financial professionals',true),
(7,'LAWYER','Lawyer/Attorney','professional','Legal professionals',true),
(8,'GOVERNMENT','Government Employee','government','Government service workers',true),
(9,'MANAGER','Manager/Executive','professional','Management and executive positions',true),
(10,'IT_PROFESSIONAL','IT Professional','professional','Information technology professionals',true),
(11,'BUSINESS_OWNER','Business Owner','business','Self-employed business owners',true),
(12,'MERCHANT','Merchant/Trader','business','Merchants and traders',true),
(13,'SHOPKEEPER','Shopkeeper','business','Shop and retail store owners',true),
(14,'FARMER','Farmer','agriculture','Agricultural farmers',true),
(15,'FISHERMAN','Fisherman','agriculture','Fishing industry workers',true),
(16,'PLANTATION_WORKER','Plantation Worker','agriculture','Tea/rubber plantation workers',true),
(17,'DRIVER','Driver','service','Drivers (taxi car bus truck)',true),
(18,'SECURITY','Security Guard','service','Security personnel',true),
(19,'CLEANER','Cleaner/Janitor','service','Cleaning and janitorial staff',true),
(20,'COOK','Cook/Chef','service','Cooking professionals',true),
(21,'WAITER','Waiter/Server','service','Restaurant and hospitality servers',true),
(22,'FACTORY_WORKER','Factory Worker','labor','Manufacturing and factory workers',true),
(23,'CONSTRUCTION','Construction Worker','labor','Construction industry workers',true),
(24,'MASON','Mason','labor','Masonry workers',true),
(25,'CARPENTER','Carpenter','labor','Carpentry workers',true),
(26,'ELECTRICIAN','Electrician','labor','Electrical workers',true),
(27,'PLUMBER','Plumber','labor','Plumbing workers',true),
(28,'MECHANIC','Mechanic','labor','Vehicle and machinery mechanics',true),
(29,'DOMESTIC_WORKER','Domestic Worker','service','Household domestic workers',true),
(30,'HOMEMAKER','Homemaker/Housewife','non_employed','Full-time homemaker',true),
(31,'STUDENT','Student','non_employed','Full-time students',true),
(32,'RETIRED','Retired','non_employed','Retired individuals',true),
(33,'UNEMPLOYED','Unemployed','non_employed','Currently unemployed',true),
(34,'DISABLED','Disabled/Unable to Work','non_employed','Medically unable to work',true),
(35,'ARMED_FORCES','Armed Forces','government','Military and defense personnel',true),
(36,'POLICE','Police Officer','government','Law enforcement officers',true),
(37,'RELIGIOUS','Religious Worker','other','Monks priests religious leaders',true),
(38,'ARTIST','Artist/Creative','other','Artists and creative professionals',true),
(39,'ATHLETE','Athlete/Sports','other','Professional athletes and sports workers',true),
(40,'OTHER','Other','other','Other occupations not listed',true)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------
-- INSERT: marital_statuses (7 rows)
-- ----------------------------------------------------------------
INSERT INTO lookups.marital_statuses (id, code, name, description, is_active, sort_order) VALUES
(1,'SINGLE','Single','Never married',true,1),
(2,'MARRIED','Married','Currently married',true,2),
(3,'DIVORCED','Divorced','Legally divorced',true,3),
(4,'WIDOWED','Widowed','Spouse deceased',true,4),
(5,'SEPARATED','Separated','Separated but not divorced',true,5),
(6,'DOMESTIC_PARTNERSHIP','Domestic Partnership','Living together not legally married',true,6),
(7,'UNKNOWN','Unknown/Prefer Not to Say','Status unknown or not disclosed',true,7)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------
-- INSERT: diagnosis_types (6 rows)
-- ----------------------------------------------------------------
INSERT INTO lookups.diagnosis_types (id, code, name, category, description, is_active, created_at, updated_at) VALUES
(1, 'T1DM', 'Type 1 Diabetes Mellitus', 'diabetes', 'Insulin-dependent diabetes', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(2, 'T2DM', 'Type 2 Diabetes Mellitus', 'diabetes', 'Non-insulin-dependent diabetes', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(3, 'GDM', 'Gestational Diabetes Mellitus', 'diabetes', 'Diabetes during pregnancy', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(4, 'PREDIABETES', 'Prediabetes', 'diabetes', 'Impaired glucose tolerance', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(5, 'MODY', 'Maturity Onset Diabetes of the Young', 'diabetes', 'Genetic form of diabetes', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(6, 'SECONDARY', 'Secondary Diabetes', 'diabetes', 'Diabetes due to other conditions', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------
-- INSERT: complication_types (9 rows)
-- ----------------------------------------------------------------
INSERT INTO lookups.complication_types (id, code, name, category, severity_levels, is_active, created_at, updated_at) VALUES
(1, 'RETINOPATHY', 'Diabetic Retinopathy', 'eye', 'mild,moderate,severe,proliferative', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(2, 'NEUROPATHY', 'Diabetic Neuropathy', 'nerve', 'mild,moderate,severe', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(3, 'NEPHROPATHY', 'Diabetic Nephropathy', 'kidney', 'stage_1,stage_2,stage_3,stage_4,stage_5', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(4, 'CVD', 'Cardiovascular Disease', 'heart', 'mild,moderate,severe', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(5, 'FOOT_ULCER', 'Diabetic Foot Ulcer', 'foot', 'grade_1,grade_2,grade_3,grade_4,grade_5', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(6, 'HYPOGLYCEMIA', 'Severe Hypoglycemia', 'metabolic', 'mild,moderate,severe', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(7, 'KETOACIDOSIS', 'Diabetic Ketoacidosis', 'metabolic', 'mild,moderate,severe', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(8, 'HYPEROSMOLAR', 'Hyperosmolar Hyperglycemic State', 'metabolic', 'mild,moderate,severe', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(9, 'OTHER', 'Other Complication', 'other', 'mild,moderate,severe', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------
-- INSERT: education_levels (7 rows)
-- ----------------------------------------------------------------
INSERT INTO lookups.education_levels (id, code, name, description, sort_order, is_active, created_at, updated_at) VALUES
(1, 'NO_FORMAL', 'No Formal Education', 'No formal education', 1, true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(2, 'PRIMARY', 'Primary Education', 'Primary education', 2, true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(3, 'SECONDARY', 'Secondary Education', 'Secondary education', 3, true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(4, 'O_LEVEL', 'O Level', 'O Level', 4, true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(5, 'A_LEVEL', 'A Level', 'A Level', 5, true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(6, 'DIPLOMA', 'Diploma', 'Diploma', 6, true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(7, 'DEGREE_PLUS', 'Degree or Higher', 'Degree or higher', 7, true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------
-- INSERT: medications (15 rows)
-- ----------------------------------------------------------------
INSERT INTO lookups.medications (id, code, name, generic_name, dosage_forms, common_dosages, category, description, is_active, created_at, updated_at) VALUES
(1, 'METFORMIN_500', 'Metformin 500mg', 'Metformin', 'tablet', '500mg', 'oral_antidiabetic', 'Biguanide - Glucophage', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(2, 'METFORMIN_850', 'Metformin 850mg', 'Metformin', 'tablet', '850mg', 'oral_antidiabetic', 'Biguanide - Glucophage', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(3, 'METFORMIN_1000', 'Metformin 1000mg', 'Metformin', 'tablet', '1000mg', 'oral_antidiabetic', 'Biguanide - Glucophage', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(4, 'GLIBENCLAMIDE_5', 'Glibenclamide 5mg', 'Glibenclamide', 'tablet', '5mg', 'oral_antidiabetic', 'Sulfonylurea - Daonil', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(5, 'GLICLAZIDE_80', 'Gliclazide 80mg', 'Gliclazide', 'tablet', '80mg', 'oral_antidiabetic', 'Sulfonylurea - Diamicron', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(6, 'GLIMEPIRIDE_2', 'Glimepiride 2mg', 'Glimepiride', 'tablet', '2mg', 'oral_antidiabetic', 'Sulfonylurea - Amaryl', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(7, 'SITAGLIPTIN_100', 'Sitagliptin 100mg', 'Sitagliptin', 'tablet', '100mg', 'oral_antidiabetic', 'DPP-4 Inhibitor - Januvia', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(8, 'EMPAGLIFLOZIN_10', 'Empagliflozin 10mg', 'Empagliflozin', 'tablet', '10mg', 'oral_antidiabetic', 'SGLT2 Inhibitor - Jardiance', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(9, 'INSULIN_REGULAR', 'Insulin Regular', 'Insulin Regular', 'injection', 'variable', 'injectable', 'Insulin - Actrapid', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(10, 'INSULIN_NPH', 'Insulin NPH', 'Insulin NPH', 'injection', 'variable', 'injectable', 'Insulin - Insulatard', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(11, 'INSULIN_GLARGINE', 'Insulin Glargine', 'Insulin Glargine', 'injection', 'variable', 'injectable', 'Long-acting Insulin - Lantus', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(12, 'ATORVASTATIN_20', 'Atorvastatin 20mg', 'Atorvastatin', 'tablet', '20mg', 'lipid_lowering', 'Statin - Lipitor', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(13, 'ASPIRIN_75', 'Aspirin 75mg', 'Aspirin', 'tablet', '75mg', 'cardiovascular', 'Antiplatelet - Cardiprin', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(14, 'RAMIPRIL_5', 'Ramipril 5mg', 'Ramipril', 'tablet', '5mg', 'antihypertensive', 'ACE Inhibitor - Tritace', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(15, 'AMLODIPINE_5', 'Amlodipine 5mg', 'Amlodipine', 'tablet', '5mg', 'antihypertensive', 'Calcium Channel Blocker - Norvasc', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------
-- INSERT: followup_types (10 rows)
-- ----------------------------------------------------------------
INSERT INTO lookups.followup_types (id, code, name, description, is_active, created_at, updated_at) VALUES
(1, 'BASELINE', 'Baseline Visit', 'Initial baseline visit', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(2, 'FOLLOWUP_1M', '1 Month Follow-up', '1 month routine follow-up', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(3, 'FOLLOWUP_3M', '3 Month Follow-up', '3 month routine follow-up', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(4, 'FOLLOWUP_6M', '6 Month Follow-up', '6 month routine follow-up', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(5, 'FOLLOWUP_1Y', 'Annual Follow-up', 'Annual routine follow-up', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(6, 'EMERGENCY', 'Emergency Visit', 'Emergency visit', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(7, 'SPECIALIST', 'Specialist Consultation', 'Specialist referral consultation', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(8, 'LAB_ONLY', 'Lab Results Review', 'Lab results review only', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(9, 'MEDICATION_REVIEW', 'Medication Review', 'Medication review appointment', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530'),
(10, 'COMPLICATION', 'Complication Assessment', 'Complication assessment visit', true, '2025-12-27 00:29:29.490 +0530', '2025-12-27 00:29:29.490 +0530')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------
-- INSERT: test_types (15 rows)
-- ----------------------------------------------------------------
INSERT INTO lookups.test_types (id, code, name, category, unit_of_measure, normal_range, description, is_active, created_at, updated_at) VALUES
(1, 'HBA1C', 'Hemoglobin A1c', 'blood_glucose', '%', '4.0-5.6', 'Long-term glucose control indicator', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(2, 'FBS', 'Fasting Blood Sugar', 'blood_glucose', 'mg/dL', '70-100', 'Fasting blood glucose test', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(3, 'PPBS', 'Post Prandial Blood Sugar', 'blood_glucose', 'mg/dL', '80-140', 'Post-meal blood glucose', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(4, 'RBS', 'Random Blood Sugar', 'blood_glucose', 'mg/dL', '80-140', 'Random blood glucose test', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(5, 'CREATININE', 'Serum Creatinine', 'kidney', 'mg/dL', '0.6-1.2', 'Kidney function indicator', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(6, 'UREA', 'Blood Urea Nitrogen', 'kidney', 'mg/dL', '7-20', 'Kidney function test', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(7, 'CHOLESTEROL', 'Total Cholesterol', 'lipid', 'mg/dL', '0-200', 'Total cholesterol level', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(8, 'HDL', 'HDL Cholesterol', 'lipid', 'mg/dL', '40-60', 'High-density lipoprotein', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(9, 'LDL', 'LDL Cholesterol', 'lipid', 'mg/dL', '0-100', 'Low-density lipoprotein', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(10, 'TRIGLYCERIDES', 'Triglycerides', 'lipid', 'mg/dL', '0-150', 'Triglyceride levels', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(11, 'ALT', 'Alanine Aminotransferase', 'liver', 'U/L', '7-56', 'Liver enzyme', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(12, 'AST', 'Aspartate Aminotransferase', 'liver', 'U/L', '10-40', 'Liver enzyme', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(13, 'MICROALBUMIN', 'Urine Microalbumin', 'kidney', 'mg/dL', '0-30', 'Kidney damage indicator', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(14, 'TSH', 'Thyroid Stimulating Hormone', 'thyroid', 'mIU/L', '0.4-4.0', 'Thyroid function test', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(15, 'VITAMIN_D', 'Vitamin D', 'vitamin', 'ng/mL', '20-50', 'Vitamin D levels', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------
-- INSERT: units (10 rows)
-- ----------------------------------------------------------------
INSERT INTO lookups.units (id, code, name, symbol, category, description, is_active, created_at, updated_at) VALUES
(1, 'MG_DL', 'Milligrams per Deciliter', 'mg/dL', 'blood', 'Common blood test unit', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(2, 'MMOL_L', 'Millimoles per Liter', 'mmol/L', 'blood', 'Alternative blood glucose unit', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(3, 'PERCENT', 'Percentage', '%', 'general', 'Percentage measurement', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(4, 'KG', 'Kilograms', 'kg', 'weight', 'Weight measurement', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(5, 'CM', 'Centimeters', 'cm', 'length', 'Height/length measurement', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(6, 'MMHG', 'Millimeters of Mercury', 'mmHg', 'pressure', 'Blood pressure unit', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(7, 'UNITS', 'Units', 'U', 'general', 'Generic unit measurement', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(8, 'G_L', 'Grams per Liter', 'g/L', 'blood', 'Blood component measurement', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(9, 'MG_L', 'Milligrams per Liter', 'mg/L', 'blood', 'Blood component measurement', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530'),
(10, 'UMOL_L', 'Micromoles per Liter', 'μmol/L', 'blood', 'Blood component measurement', true, '2025-12-27 00:29:29.596 +0530', '2025-12-27 00:29:29.596 +0530')
ON CONFLICT (id) DO NOTHING;