-- Singular dbt test: validates the mart grain.
-- Each AI trust level and normalized response option must appear only once.
-- The test fails if duplicate combinations are found.
-- Expected result: zero rows.

SELECT
    ai_trust_level,
    ai_frustration,
    COUNT(*) AS row_count

FROM {{ ref('mart_ai_trust_by_frustration') }}

GROUP BY
    ai_trust_level,
    ai_frustration

HAVING COUNT(*) > 1