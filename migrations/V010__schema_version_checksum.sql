-- =============================================================================
-- DieVix - Database Migration V010
-- Add CHECKSUM column to SCHEMA_VERSION for migration integrity verification
-- =============================================================================

ALTER TABLE SCHEMA_VERSION ADD CHECKSUM VARCHAR(64);
