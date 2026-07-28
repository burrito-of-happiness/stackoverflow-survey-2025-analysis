{{ config(materialized='view') }}

WITH source AS (
    SELECT
        response_id,
        ai_tasks_currently_mostly_ai,
        ai_tasks_currently_partially_ai,
        ai_tasks_plan_to_mostly_use,
        ai_tasks_plan_to_partially_use,
        ai_tasks_do_not_plan_to_use
    FROM {{ ref('stg_survey_results') }}
),

task_statuses AS (
    -- Reproduce the status mapping used by int_ai_tasks_long.
    SELECT
        response_id,
        'Currently mostly AI' AS ai_task_status,
        1 AS ai_task_status_order,
        ai_tasks_currently_mostly_ai AS ai_task_list
    FROM source
    UNION ALL

    SELECT
        response_id,
        'Currently partially AI' AS ai_task_status,
        2 AS ai_task_status_order,
        ai_tasks_currently_partially_ai AS ai_task_list
    FROM source
    UNION ALL

    SELECT
        response_id,
        'Plan to mostly use AI' AS ai_task_status,
        3 AS ai_task_status_order,
        ai_tasks_plan_to_mostly_use AS ai_task_list
    FROM source
    UNION ALL

    SELECT
        response_id,
        'Plan to partially use AI' AS ai_task_status,
        4 AS ai_task_status_order,
        ai_tasks_plan_to_partially_use AS ai_task_list
    FROM source
    UNION ALL

    SELECT
        response_id,
        'Do not plan to use AI' AS ai_task_status,
        5 AS ai_task_status_order,
        ai_tasks_do_not_plan_to_use AS ai_task_list
    FROM source
),

split_tasks AS (
    -- Apply the same splitting and label normalization as the model.
    SELECT
        task_statuses.response_id,
        task_statuses.ai_task_status,
        task_statuses.ai_task_status_order,
        split_value.index AS task_position,
        CASE
            WHEN TRIM(split_value.value) = 'Other (write in):'
                THEN 'Other'
            ELSE NULLIF(TRIM(split_value.value), '')
        END AS ai_task
    FROM task_statuses,
        LATERAL SPLIT_TO_TABLE(
            task_statuses.ai_task_list,
            ';'
        ) AS split_value
    WHERE task_statuses.ai_task_list IS NOT NULL
),

expected_long AS (
    -- Apply the same grain and duplicate handling as int_ai_tasks_long.
    SELECT
        response_id,
        ai_task,
        ai_task_status,
        ai_task_status_order,
        MIN(task_position) AS task_position
    FROM split_tasks
    WHERE ai_task IS NOT NULL
    GROUP BY
        response_id,
        ai_task,
        ai_task_status,
        ai_task_status_order
),

actual_long AS (
    SELECT
        response_id,
        ai_task,
        ai_task_status,
        ai_task_status_order,
        task_position
    FROM {{ ref('int_ai_tasks_long') }}

),

expected_stats AS (
    SELECT
        COUNT(*) AS expected_long_row_count,
        COUNT(DISTINCT response_id) AS expected_respondent_count,
        COUNT(DISTINCT ai_task_status) AS expected_status_count,
        COUNT(DISTINCT ai_task) AS expected_distinct_task_count
    FROM expected_long
),

actual_stats AS (
    SELECT
        COUNT(*) AS actual_long_row_count,
        COUNT(DISTINCT response_id) AS actual_respondent_count,
        COUNT(DISTINCT ai_task_status) AS actual_status_count,
        COUNT(DISTINCT ai_task) AS actual_distinct_task_count,
        COUNT_IF(response_id IS NULL) AS null_response_id_count,
        COUNT_IF(ai_task IS NULL) AS null_task_count,
        COUNT_IF(ai_task_status IS NULL) AS null_status_count,
        COUNT_IF(ai_task_status_order IS NULL) AS null_status_order_count,
        COUNT_IF(task_position IS NULL) AS null_task_position_count
    FROM actual_long
),

duplicate_stats AS (
    SELECT
        COUNT(*) AS duplicate_grain_count
    FROM (
        SELECT
            response_id,
            ai_task,
            ai_task_status
        FROM actual_long
        GROUP BY
            response_id,
            ai_task,
            ai_task_status
        HAVING COUNT(*) > 1
    )

),

multiple_status_stats AS (
    SELECT
        COUNT(*) AS multiple_status_selection_count
    FROM (
        SELECT
            response_id,
            ai_task
        FROM actual_long
        GROUP BY
            response_id,
            ai_task
        HAVING COUNT(DISTINCT ai_task_status) > 1
    )

),

missing_rows AS (
    SELECT
        COUNT(*) AS missing_row_count
    FROM (
        SELECT
            response_id,
            ai_task,
            ai_task_status,
            ai_task_status_order,
            task_position
        FROM expected_long
        EXCEPT
        SELECT
            response_id,
            ai_task,
            ai_task_status,
            ai_task_status_order,
            task_position
        FROM actual_long
    )
),

unexpected_rows AS (
    SELECT
        COUNT(*) AS unexpected_row_count
    FROM (

        SELECT
            response_id,
            ai_task,
            ai_task_status,
            ai_task_status_order,
            task_position
        FROM actual_long
        EXCEPT
        SELECT
            response_id,
            ai_task,
            ai_task_status,
            ai_task_status_order,
            task_position
        FROM expected_long
    )
)

SELECT
    expected.expected_respondent_count,
    actual.actual_respondent_count,

    expected.expected_long_row_count,
    actual.actual_long_row_count,
    actual.actual_long_row_count
        - expected.expected_long_row_count AS row_count_difference,

    expected.expected_status_count,
    actual.actual_status_count,

    expected.expected_distinct_task_count,
    actual.actual_distinct_task_count,

    missing.missing_row_count,
    unexpected.unexpected_row_count,
    duplicates.duplicate_grain_count,
    multiple_statuses.multiple_status_selection_count,

    actual.null_response_id_count,
    actual.null_task_count,
    actual.null_status_count,
    actual.null_status_order_count,
    actual.null_task_position_count

FROM expected_stats AS expected
CROSS JOIN actual_stats AS actual
CROSS JOIN duplicate_stats AS duplicates
CROSS JOIN multiple_status_stats AS multiple_statuses
CROSS JOIN missing_rows AS missing
CROSS JOIN unexpected_rows AS unexpected