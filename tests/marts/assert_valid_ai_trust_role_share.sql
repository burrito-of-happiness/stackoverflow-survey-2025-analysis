-- Fails if a calculated respondent share is null or falls
-- outside the valid range from 0 to 1.

SELECT
    developer_role,
    ai_trust_level,
    respondent_share_within_role

FROM {{ ref('mart_ai_trust_by_role') }}

WHERE respondent_share_within_role IS NULL
   OR respondent_share_within_role NOT BETWEEN 0 AND 1