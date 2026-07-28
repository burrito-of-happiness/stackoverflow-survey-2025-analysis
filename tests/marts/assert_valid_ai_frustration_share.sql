-- Singular dbt test: validates the counts and calculated share for every
-- response option in the mart.
-- The test fails when counts are non-positive, the numerator exceeds the
-- denominator, the share falls outside 0 to 1, or the stored share does not
-- equal respondent_count / trust_group_respondent_count rounded to 4 decimals.
-- Expected result: zero rows.

SELECT
    ai_trust_level,
    ai_frustration,
    respondent_count,
    trust_group_respondent_count,
    respondent_share_within_trust

FROM {{ ref('mart_ai_trust_by_frustration') }}

WHERE respondent_count IS NULL
   OR trust_group_respondent_count IS NULL
   OR respondent_share_within_trust IS NULL
   OR respondent_count <= 0
   OR trust_group_respondent_count <= 0
   OR respondent_count > trust_group_respondent_count
   OR respondent_share_within_trust < 0
   OR respondent_share_within_trust > 1
   OR ABS(
        respondent_share_within_trust
        - ROUND(
            respondent_count
            / NULLIF(trust_group_respondent_count, 0),
            4
        )
   ) > 0.00001