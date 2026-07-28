{{ config(materialized='view') }}

WITH expected_categories AS (

    SELECT column1::STRING AS ai_frustration

    FROM VALUES
        ('AI solutions that are almost right, but not quite'),
        ('Debugging AI-generated code is more time-consuming'),
        ('I’ve become less confident in my own problem-solving'),
        ('It’s hard to understand how or why the code works'),
        ('I don’t use AI tools regularly'),
        ('I haven’t encountered any problems'),
        ('Other')

),

source_long AS (

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

normalized_source AS (

    SELECT
        response_id,
        frustration_position,
        raw_frustration,

        CASE
            WHEN raw_frustration = 'Other (write in):'
                THEN 'Other'
            ELSE raw_frustration
        END AS ai_frustration

    FROM source_long

    WHERE raw_frustration IS NOT NULL

),

expected_rows AS (

    SELECT
        response_id,
        ai_frustration,
        MIN(frustration_position) AS frustration_position,
        COUNT(*) AS source_selection_count

    FROM normalized_source

    GROUP BY
        response_id,
        ai_frustration

),

source_stats AS (

    SELECT
        COUNT(DISTINCT response_id) AS source_respondent_count,
        COUNT(*) AS nonblank_source_token_count,
        COUNT_IF(raw_frustration = 'Other (write in):')
            AS exact_other_label_count,
        COUNT_IF(
            raw_frustration ILIKE 'Other (write in):%'
            AND raw_frustration <> 'Other (write in):'
        ) AS inline_other_text_token_count

    FROM normalized_source

),

expected_stats AS (

    SELECT
        COUNT(*) AS expected_model_row_count,
        COUNT_IF(source_selection_count > 1)
            AS expected_rows_with_repeated_source_selection,
        COALESCE(SUM(GREATEST(source_selection_count - 1, 0)), 0)
            AS repeated_source_token_count

    FROM expected_rows

),

actual_stats AS (

    SELECT
        COUNT(*) AS actual_model_row_count,
        COUNT(DISTINCT response_id) AS actual_respondent_count,
        COUNT(DISTINCT ai_frustration) AS distinct_frustration_count,
        COUNT_IF(response_id IS NULL) AS null_response_id_count,
        COUNT_IF(ai_frustration IS NULL) AS null_frustration_count,
        COUNT_IF(frustration_position IS NULL) AS null_position_count,
        COUNT_IF(source_selection_count IS NULL) AS null_selection_count_count,
        COUNT_IF(source_selection_count > 1)
            AS actual_rows_with_repeated_source_selection,
        COALESCE(SUM(GREATEST(source_selection_count - 1, 0)), 0)
            AS exposed_repeated_source_token_count,
        COUNT_IF(ai_frustration = 'Other') AS normalized_other_row_count,
        COUNT_IF(ai_frustration = 'I haven’t encountered any problems')
            AS no_problems_row_count

    FROM {{ ref('int_ai_frustrations_long') }}

),

source_category_stats AS (

    SELECT
        COUNT(DISTINCT source.ai_frustration)
            AS source_distinct_frustration_count,
        COUNT(DISTINCT CASE
            WHEN expected.ai_frustration IS NULL
                THEN source.ai_frustration
        END) AS unexpected_source_category_count

    FROM normalized_source AS source

    LEFT JOIN expected_categories AS expected
        ON source.ai_frustration = expected.ai_frustration

),

actual_category_stats AS (

    SELECT
        COUNT(DISTINCT CASE
            WHEN expected.ai_frustration IS NULL
                THEN actual.ai_frustration
        END) AS unexpected_model_category_count

    FROM {{ ref('int_ai_frustrations_long') }} AS actual

    LEFT JOIN expected_categories AS expected
        ON actual.ai_frustration = expected.ai_frustration

),

reconciliation AS (

    SELECT
        expected.response_id AS expected_response_id,
        actual.response_id AS actual_response_id,
        expected.ai_frustration AS expected_ai_frustration,
        actual.ai_frustration AS actual_ai_frustration,
        expected.frustration_position AS expected_position,
        actual.frustration_position AS actual_position,
        expected.source_selection_count AS expected_selection_count,
        actual.source_selection_count AS actual_selection_count

    FROM expected_rows AS expected

    FULL OUTER JOIN {{ ref('int_ai_frustrations_long') }} AS actual
        ON expected.response_id = actual.response_id
       AND expected.ai_frustration = actual.ai_frustration

),

reconciliation_stats AS (

    SELECT
        COUNT_IF(actual_response_id IS NULL) AS missing_model_row_count,
        COUNT_IF(expected_response_id IS NULL) AS unexpected_model_row_count,
        COUNT_IF(
            expected_response_id IS NOT NULL
            AND actual_response_id IS NOT NULL
            AND (
                expected_position <> actual_position
                OR expected_selection_count <> actual_selection_count
            )
        ) AS mismatched_model_row_count

    FROM reconciliation

)

SELECT
    source.source_respondent_count,
    actual.actual_respondent_count,
    source.nonblank_source_token_count,
    expected.expected_model_row_count,
    actual.actual_model_row_count,
    actual.actual_model_row_count - expected.expected_model_row_count
        AS model_row_count_difference,
    expected.expected_rows_with_repeated_source_selection,
    actual.actual_rows_with_repeated_source_selection,
    expected.repeated_source_token_count,
    actual.exposed_repeated_source_token_count,
    source_categories.source_distinct_frustration_count,
    actual.distinct_frustration_count AS model_distinct_frustration_count,
    source_categories.unexpected_source_category_count,
    actual_categories.unexpected_model_category_count,
    actual.null_response_id_count,
    actual.null_frustration_count,
    actual.null_position_count,
    actual.null_selection_count_count,
    source.exact_other_label_count,
    source.inline_other_text_token_count,
    actual.normalized_other_row_count,
    actual.no_problems_row_count,
    reconciliation.missing_model_row_count,
    reconciliation.unexpected_model_row_count,
    reconciliation.mismatched_model_row_count

FROM source_stats AS source
CROSS JOIN expected_stats AS expected
CROSS JOIN actual_stats AS actual
CROSS JOIN source_category_stats AS source_categories
CROSS JOIN actual_category_stats AS actual_categories
CROSS JOIN reconciliation_stats AS reconciliation