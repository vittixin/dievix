/* =============================================================================
   DieVix – Migration V008: Audit Serial Column & Multi-ups Pool Gap Policy
   Target: Firebird 5.0
   Encoding: UTF8

   Description:
     1. Add nullable column DIE_SERIAL_NO VARCHAR(30) to DIE_AUDIT_LOG.
        (Nullable without NOT NULL constraint so legacy rows remain valid).
     2. Backfill DIE_SERIAL_NO for all existing audit rows from DIE.SERIAL_NO
        where DIE_ID still resolves.
============================================================================= */

-- Enable FireDAC script autocommit so column metadata changes are committed before backfill DML
SET AUTOCOMMIT ON;

-- 1. Add nullable DIE_SERIAL_NO column to DIE_AUDIT_LOG
ALTER TABLE DIE_AUDIT_LOG ADD DIE_SERIAL_NO VARCHAR(30);

-- 2. Backfill DIE_SERIAL_NO for existing rows from DIE.SERIAL_NO where DIE_ID resolves
UPDATE DIE_AUDIT_LOG A
SET A.DIE_SERIAL_NO = (SELECT D.SERIAL_NO FROM DIE D WHERE D.ID = A.DIE_ID)
WHERE A.DIE_SERIAL_NO IS NULL
  AND A.DIE_ID IS NOT NULL
  AND EXISTS (SELECT 1 FROM DIE D WHERE D.ID = A.DIE_ID);

-- Restore autocommit state to transactional
SET AUTOCOMMIT OFF;
