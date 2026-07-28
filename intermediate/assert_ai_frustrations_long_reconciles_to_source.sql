-- Independently rebuilds the expected long rows from staging and compares them with int_ai_frustrations_long. 
-- Checks row coverage, earliest source position, and exposure of repeated source selections.
-- The test passes when the query returns zero rows.

WITH source_long AS (

    SELECT
        source.response_id,
        split_value.index::INTEGER AS frustration_position,
        NULLIF(
            TRIM(split_value.value::STRING),
            ''
        ) AS raw_frustration

    FROM {{ ref('stg_survey_results') }} AS source,
        LATERAL SPLIT_TO_TABLE(
            source.ai_frustrations,
            ';'
        ) AS split_value

    WHERE source.ai_frustrations IS NOT NULL

),

expected AS (

    SELECT
        response_id,

        CASE
            WHEN raw_frustration = 'Other (write in):'
                THEN 'Other'
            ELSE raw_frustration
        END AS ai_frustration,

        MIN(frustration_position) AS frustration_position,
        COUNT(*) AS source_selection_count

    FROM source_long

    WHERE raw_frustration IS NOT NULL

    GROUP BY
        response_id,
        CASE
            WHEN raw_frustration = 'Other (write in):'
                THEN 'Other'
            ELSE raw_frustration
        END

),

actual AS (

    SELECT
        response_id,
        ai_frustration,
        frustration_position,
        source_selection_count

    FROM {{ ref('int_ai_frustrations_long') }}

)

SELECT
    COALESCE(expected.response_id, actual.response_id) AS response_id,
    COALESCE(expected.ai_frustration, actual.ai_frustration) AS ai_frustration,
    expected.frustration_position AS expected_frustration_position,
    actual.frustration_position AS actual_frustration_position,
    expected.source_selection_count AS expected_source_selection_count,
    actual.source_selection_count AS actual_source_selection_count

FROM expected

FULL OUTER JOIN actual
    ON expected.response_id = actual.response_id
   AND expected.ai_frustration = actual.ai_frustration

WHERE expected.response_id IS NULL
   OR actual.response_id IS NULL
   OR expected.frustration_position <> actual.frustration_position
   OR expected.source_selection_count <> actual.source_selection_count