/* =============================================================================
   DieVix – Migration V006: Audit Log Integrity & Non-Cascading Foreign Key
   Target: Firebird 5.0
   Encoding: UTF8

   Description:
     1. Drop legacy foreign key on DIE_AUDIT_LOG that had ON DELETE CASCADE.
     2. Add explicit non-cascading foreign key (NO ACTION) so deleting a die
        never silently erases its historical audit records.
============================================================================= */

-- 1. Drop existing foreign key constraint on DIE_AUDIT_LOG dynamically
SET TERM ^ ;

EXECUTE BLOCK AS
DECLARE VARIABLE CNAME VARCHAR(63);
BEGIN
  SELECT TRIM(RDB$CONSTRAINT_NAME)
  FROM RDB$RELATION_CONSTRAINTS
  WHERE RDB$RELATION_NAME = 'DIE_AUDIT_LOG'
    AND RDB$CONSTRAINT_TYPE = 'FOREIGN KEY'
  INTO :CNAME;

  IF (CNAME IS NOT NULL) THEN
    EXECUTE STATEMENT 'ALTER TABLE DIE_AUDIT_LOG DROP CONSTRAINT ' || CNAME;
END ^

SET TERM ; ^

-- 2. Add non-cascading foreign key (NO ACTION)
ALTER TABLE DIE_AUDIT_LOG ADD CONSTRAINT FK_DIE_AUDIT_LOG_DIE
  FOREIGN KEY (DIE_ID) REFERENCES DIE(ID);
