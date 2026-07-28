{{ config(materialized='table') }}

WITH respondent_response_options AS (

    -- One row per respondent and normalized response option from the
    -- AI-frustration question. Not every option denotes an actual frustration.

    SELECT
        frustrations.response_id,
        survey.ai_trust_level,

        CASE survey.ai_trust_level
            WHEN 'Highly trust' THEN 1
            WHEN 'Somewhat trust' THEN 2
            WHEN 'Neither trust nor distrust' THEN 3
            WHEN 'Somewhat distrust' THEN 4
            WHEN 'Highly distrust' THEN 5
        END AS ai_trust_order,

        frustrations.ai_frustration,

        CASE
            WHEN frustrations.ai_frustration IN (
                'I don’t use AI tools regularly',
                'I haven’t encountered any problems'
            )
                THEN FALSE
            ELSE TRUE
        END AS is_actual_frustration

    FROM {{ ref('int_ai_frustrations_long') }} AS frustrations

    INNER JOIN {{ ref('stg_survey_results') }} AS survey
        ON frustrations.response_id = survey.response_id

    WHERE survey.ai_trust_level IS NOT NULL

),

trust_group_totals AS (

    -- Denominator: respondents with an AI-trust response and at least one
    -- response option recorded for the AI-frustration question.

    SELECT
        ai_trust_level,
        ai_trust_order,
        COUNT(DISTINCT response_id) AS trust_group_respondent_count

    FROM respondent_response_options

    GROUP BY
        ai_trust_level,
        ai_trust_order

),

response_option_counts AS (

    -- Numerator: respondents who selected each response option.

    SELECT
        ai_trust_level,
        ai_trust_order,
        ai_frustration,
        is_actual_frustration,
        COUNT(DISTINCT response_id) AS respondent_count

    FROM respondent_response_options

    GROUP BY
        ai_trust_level,
        ai_trust_order,
        ai_frustration,
        is_actual_frustration

),

response_option_metrics AS (

    SELECT
        response_option_counts.ai_trust_level,
        response_option_counts.ai_trust_order,
        response_option_counts.ai_frustration,
        response_option_counts.is_actual_frustration,
        response_option_counts.respondent_count,
        trust_group_totals.trust_group_respondent_count,

        ROUND(
            response_option_counts.respondent_count
            / NULLIF(
                trust_group_totals.trust_group_respondent_count,
                0
            ),
            4
        ) AS respondent_share_within_trust

    FROM response_option_counts

    INNER JOIN trust_group_totals
        ON response_option_counts.ai_trust_level
            = trust_group_totals.ai_trust_level
        AND response_option_counts.ai_trust_order
            = trust_group_totals.ai_trust_order

),

final AS (

    SELECT
        ai_trust_level,
        ai_trust_order,
        ai_frustration,
        is_actual_frustration,
        respondent_count,
        trust_group_respondent_count,
        respondent_share_within_trust,

        CASE
            WHEN is_actual_frustration THEN
                DENSE_RANK() OVER (
                    PARTITION BY
                        ai_trust_level,
                        is_actual_frustration
                    ORDER BY respondent_count DESC
                )
        END AS frustration_rank_within_trust

    FROM response_option_metrics

)

SELECT
    ai_trust_level,
    ai_trust_order,
    ai_frustration,
    is_actual_frustration,
    respondent_count,
    trust_group_respondent_count,
    respondent_share_within_trust,
    frustration_rank_within_trust

FROM final