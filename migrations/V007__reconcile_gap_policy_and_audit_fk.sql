/* =============================================================================
   DieVix – Migration V007: Reconcile Gap Policy & Audit Log FK Removal
   Target: Firebird 5.0
   Encoding: UTF8

   Description:
     1. Drop legacy WARN_AROUND_GAP_UM from APP_SETTING if present, as gap
        policy is defined strictly by MIN_AROUND_GAP_UM and HARD_BLOCK_GAP_UM.
     2. Drop foreign key constraint on DIE_AUDIT_LOG(DIE_ID) so deleting a die
        leaves its audit log rows completely intact with original DIE_ID.
     3. Add index on DIE_AUDIT_LOG(DIE_ID) to support fast audit lookups.
     4. Recreate V_DIE_CATALOG with exact TGapResult alignment:
        - Gap >= MIN_AROUND_GAP_UM: APPROVED
        - Gap < HARD_BLOCK_GAP_UM (when > 0) or Gap < 0: REJECTED_MECHANICAL
        - Hard block 0: disabled (warning only)
        - Otherwise: WARNING_SUB3MM
============================================================================= */

-- 1. Drop view dependent on APP_SETTING and DIE
DROP VIEW V_DIE_CATALOG;

-- 2. Remove obsolete / duplicate warning setting key if present
DELETE FROM APP_SETTING WHERE SETTING_KEY = 'WARN_AROUND_GAP_UM';

-- 3. Drop foreign key on DIE_AUDIT_LOG dynamically to preserve audit history on delete
SET TERM ^ ;

EXECUTE BLOCK AS
DECLARE VARIABLE CNAME VARCHAR(63);
BEGIN
  FOR SELECT TRIM(RDB$CONSTRAINT_NAME)
      FROM RDB$RELATION_CONSTRAINTS
      WHERE RDB$RELATION_NAME = 'DIE_AUDIT_LOG'
        AND RDB$CONSTRAINT_TYPE = 'FOREIGN KEY'
      INTO :CNAME DO
  BEGIN
    EXECUTE STATEMENT 'ALTER TABLE DIE_AUDIT_LOG DROP CONSTRAINT ' || CNAME;
  END
END ^

SET TERM ; ^

-- 4. Create index on DIE_AUDIT_LOG (DIE_ID) for fast historical lookups
CREATE INDEX IDX_DIE_AUDIT_DIE_ID ON DIE_AUDIT_LOG (DIE_ID);

-- 5. Recreate V_DIE_CATALOG with unified gap policy semantics
CREATE VIEW V_DIE_CATALOG AS
SELECT
    D.ID,
    D.SERIAL_NO,
    D.CUSTOMER_ID,
    C.NAME AS CUSTOMER_NAME,
    D.MEDIA_ID,
    M.NAME AS MEDIA_NAME,
    D.TEETH,
    D.PITCH_UM,
    D.COMPUTED_REPEAT_MM AS REPEAT_MM,
    CAST(D.COMPUTED_REPEAT_MM / 25.400 AS NUMERIC(18,3)) AS REPEAT_INCH,
    D.AROUND_SIZE_MM,
    D.ACROSS_SIZE_MM,
    D.AROUND_UPS,
    D.ACROSS_UPS,
    D.COMPUTED_AROUND_GAP_MM AS AROUND_GAP_MM,
    D.ACROSS_GAP_MM,
    D.CORNER_RADIUS_MM,
    D.SHAPE,
    D.CUT_TYPE,
    D.STORAGE_LOCATION,
    D.STORAGE_RACK,
    D.STORAGE_SHELF,
    D.STORAGE_BIN,
    D.STATUS_CODE,
    S.DESCRIPTION AS STATUS_NAME,
    S.BADGE_COLOR,
    D.OVERRIDE_REASON,
    CASE 
        WHEN D.COMPUTED_AROUND_GAP_MM IS NULL THEN NULL
        WHEN D.COMPUTED_AROUND_GAP_MM < 0.000 THEN 'REJECTED_MECHANICAL'
        WHEN (COALESCE((SELECT CAST(SETTING_VALUE AS INTEGER) FROM APP_SETTING WHERE SETTING_KEY = 'HARD_BLOCK_GAP_UM'), 0) > 0)
             AND (D.COMPUTED_AROUND_GAP_MM < (SELECT CAST(SETTING_VALUE AS NUMERIC(18,3)) FROM APP_SETTING WHERE SETTING_KEY = 'HARD_BLOCK_GAP_UM') / 1000.000) THEN 'REJECTED_MECHANICAL'
        WHEN D.COMPUTED_AROUND_GAP_MM < (COALESCE((SELECT CAST(SETTING_VALUE AS NUMERIC(18,3)) FROM APP_SETTING WHERE SETTING_KEY = 'MIN_AROUND_GAP_UM'), 3000.000) / 1000.000) THEN 'WARNING_SUB3MM'
        ELSE 'APPROVED'
    END AS GAP_POLICY_STATUS,
    D.PURCHASE_DATE,
    D.RECEIVED_DATE,
    D.DIE_MAKER,
    D.SUPPLIER_REF,
    D.TOTAL_RUN_METRES,
    D.DESCRIPTION,
    D.INTERNAL_REF,
    D.CUSTOMER_REF,
    D.NOTES,
    D.VERSION,
    D.CREATED_BY,
    D.CREATED_AT,
    D.UPDATED_BY,
    D.UPDATED_AT
FROM DIE D
LEFT JOIN CUSTOMER C ON D.CUSTOMER_ID = C.ID
LEFT JOIN MEDIA M ON D.MEDIA_ID = M.ID
LEFT JOIN DIE_STATUS S ON D.STATUS_CODE = S.CODE;
