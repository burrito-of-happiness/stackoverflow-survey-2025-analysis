-- Fails if a role does not contain exactly five trust-level rows,
-- if respondent counts do not reconcile to the role denominator,
-- or if rounded shares do not sum to approximately 1.

SELECT
    developer_role,
    COUNT(*) AS trust_level_row_count,
    SUM(respondent_count) AS summed_respondent_count,
    MAX(role_respondent_count) AS role_respondent_count,
    SUM(respondent_share_within_role) AS summed_share

FROM {{ ref('mart_ai_trust_by_role') }}

GROUP BY
    developer_role

HAVING COUNT(*) <> 5
    OR SUM(respondent_count) <> MAX(role_respondent_count)
    OR ABS(SUM(respondent_share_within_role) - 1) > 0.001