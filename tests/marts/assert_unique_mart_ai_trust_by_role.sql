-- Fails if the mart contains more than one row for the same
-- developer role and AI trust level.

SELECT
    developer_role,
    ai_trust_level,
    COUNT(*) AS row_count

FROM {{ ref('mart_ai_trust_by_role') }}

GROUP BY
    developer_role,
    ai_trust_level

HAVING COUNT(*) > 1