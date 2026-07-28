-- Singular dbt test: validates the 2 derived fields in mart_ai_trust_by_frustration.

-- The test verifies that:
--   1. is_actual_frustration is FALSE only for the two response options that do not describe an actual AI-related frustration;
--   2. frustration_rank_within_trust is NULL for those two options;
--   3. every actual frustration has a non-NULL dense rank;
--   4. the stored rank matches the descending respondent-count rank
--      calculated independently within each AI trust group.
--
-- The test fails by returning rows with an incorrect classification or rank.
-- Expected result: zero rows.

WITH mart AS (

    SELECT
        ai_trust_level,
        ai_frustration,
        is_actual_frustration,
        respondent_count,
        frustration_rank_within_trust,

        CASE
            WHEN ai_frustration IN (
                'I don’t use AI tools regularly',
                'I haven’t encountered any problems'
            )
                THEN FALSE
            ELSE TRUE
        END AS expected_is_actual_frustration

    FROM {{ ref('mart_ai_trust_by_frustration') }}

),

expected_actual_frustration_ranks AS (

    SELECT
        ai_trust_level,
        ai_frustration,

        DENSE_RANK() OVER (
            PARTITION BY ai_trust_level
            ORDER BY respondent_count DESC
        ) AS expected_frustration_rank_within_trust

    FROM mart

    WHERE expected_is_actual_frustration = TRUE

),

validation AS (

    SELECT
        mart.ai_trust_level,
        mart.ai_frustration,
        mart.respondent_count,
        mart.is_actual_frustration,
        mart.expected_is_actual_frustration,
        mart.frustration_rank_within_trust,
        expected_ranks.expected_frustration_rank_within_trust

    FROM mart

    LEFT JOIN expected_actual_frustration_ranks AS expected_ranks
        ON mart.ai_trust_level = expected_ranks.ai_trust_level
        AND mart.ai_frustration = expected_ranks.ai_frustration

)

SELECT
    ai_trust_level,
    ai_frustration,
    respondent_count,
    is_actual_frustration,
    expected_is_actual_frustration,
    frustration_rank_within_trust,
    expected_frustration_rank_within_trust

FROM validation

WHERE is_actual_frustration IS NULL
   OR is_actual_frustration <> expected_is_actual_frustration
   OR (
        expected_is_actual_frustration = TRUE
        AND frustration_rank_within_trust IS NULL
   )
   OR (
        expected_is_actual_frustration = FALSE
        AND frustration_rank_within_trust IS NOT NULL
   )
   OR (
        expected_is_actual_frustration = TRUE
        AND frustration_rank_within_trust
            <> expected_frustration_rank_within_trust
   )