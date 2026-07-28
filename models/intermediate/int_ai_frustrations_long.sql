{{ config(materialized='view') }}

WITH source AS (
    SELECT
        response_id,
        ai_frustrations
    FROM {{ ref('stg_survey_results') }}
    WHERE ai_frustrations IS NOT NULL

),

split_frustrations AS (
    -- The source field is a semicolon-separated multi-select response.
    -- Preserve the source position so the transformation remains auditable.
    SELECT
        source.response_id,
        split_value.index::INTEGER AS frustration_position,
        NULLIF(
            TRIM(split_value.value::STRING),
            ''
        ) AS raw_frustration
    FROM source,
        LATERAL SPLIT_TO_TABLE(
            source.ai_frustrations,
            ';'
        ) AS split_value

),

normalized_frustrations AS (
    SELECT
        response_id,
        frustration_position,
        CASE
            WHEN raw_frustration = 'Other (write in):'
                THEN 'Other'
            ELSE raw_frustration
        END AS ai_frustration
    FROM split_frustrations
    WHERE raw_frustration IS NOT NULL

)

SELECT
    response_id,
    ai_frustration,
    MIN(frustration_position) AS frustration_position,
    -- Keep one row per respondent and normalized frustration category.
    -- A value above 1 exposes repeated source selections instead of hiding them.
    COUNT(*) AS source_selection_count
FROM normalized_frustrations
GROUP BY
    response_id,
    ai_frustration