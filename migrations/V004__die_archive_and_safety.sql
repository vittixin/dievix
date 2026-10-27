/* =============================================================================
   DieVix – Migration V004: Safe Tooling Archiving & Deletion Safeguards
   Target: Firebird 5.0
   Encoding: UTF8
============================================================================= */

-- 1. Ensure ARCHIVED status code exists in DIE_STATUS master
UPDATE OR INSERT INTO DIE_STATUS (CODE, DESCRIPTION, IS_USABLE, BADGE_COLOR, SORT_ORDER)
VALUES ('ARCHIVED', 'Archived Tooling (Historical)', 0, 'Gray', 60)
MATCHING (CODE);
