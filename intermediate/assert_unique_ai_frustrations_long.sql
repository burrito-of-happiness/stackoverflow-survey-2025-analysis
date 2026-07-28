-- Enforces the documented model grain:
-- one row per response_id and normalized ai_frustration.
-- The test passes when the query returns zero rows.

SELECT
    response_id,
    ai_frustration,
    COUNT(*) AS row_count

FROM {{ ref('int_ai_frustrations_long') }}

GROUP BY
    response_id,
    ai_frustration

HAVING COUNT(*) > 1