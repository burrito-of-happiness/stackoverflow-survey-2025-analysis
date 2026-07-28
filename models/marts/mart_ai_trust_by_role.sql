{{ config(materialized='table') }}

WITH trust_levels AS (
    -- Complete ordered list of valid AI trust levels.
    -- It is used to retain zero-count trust levels for every role.
    SELECT
        column1::VARCHAR AS ai_trust_level,
        column2::INTEGER AS ai_trust_order
    FROM VALUES
        ('Highly trust', 1),
        ('Somewhat trust', 2),
        ('Neither trust nor distrust', 3),
        ('Somewhat distrust', 4),
        ('Highly distrust', 5)
),

respondent_base AS (

    -- One row per respondent with a reported developer role
    -- and a non-null AI trust response.

    SELECT
        response_id,
        developer_role,
        ai_trust_level
    FROM {{ ref('stg_survey_results') }}
    WHERE developer_role IS NOT NULL
      AND ai_trust_level IS NOT NULL

),

role_totals AS (
    -- Denominator: respondents within each developer role who provided an AI trust response.
    SELECT
        developer_role,
        COUNT(DISTINCT response_id) AS role_respondent_count
    FROM respondent_base
    GROUP BY
        developer_role
),

trust_counts AS (
    -- Numerator: respondents with each AI trust level within each developer role.

    SELECT
        developer_role,
        ai_trust_level,
        COUNT(DISTINCT response_id) AS respondent_count
    FROM respondent_base
    GROUP BY
        developer_role,
        ai_trust_level

),

role_trust_matrix AS (
    -- Create all five trust-level rows for every developer role, including combinations with zero respondents.
    SELECT
        role_totals.developer_role,
        trust_levels.ai_trust_level,
        trust_levels.ai_trust_order,
        role_totals.role_respondent_count
    FROM role_totals
    CROSS JOIN trust_levels
),

final AS (
    SELECT
        role_trust_matrix.developer_role,
        role_trust_matrix.ai_trust_level,
        role_trust_matrix.ai_trust_order,
        COALESCE(trust_counts.respondent_count, 0)
            AS respondent_count,
        role_trust_matrix.role_respondent_count,
        ROUND(
            COALESCE(trust_counts.respondent_count, 0)::FLOAT
            / NULLIF(role_trust_matrix.role_respondent_count, 0),
            4
        ) AS respondent_share_within_role
    FROM role_trust_matrix
    LEFT JOIN trust_counts
        ON role_trust_matrix.developer_role
            = trust_counts.developer_role
        AND role_trust_matrix.ai_trust_level
            = trust_counts.ai_trust_level
)

SELECT
    developer_role,
    ai_trust_level,
    ai_trust_order,
    respondent_count,
    role_respondent_count,
    respondent_share_within_roleSONAR_TASK.ANALYTICS.MART_AI_TRUST_BY_ROLE
FROM final