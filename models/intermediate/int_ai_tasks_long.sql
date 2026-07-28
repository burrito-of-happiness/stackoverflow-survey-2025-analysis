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
 -- Convert the five matrix columns into one status/list structure.
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
 -- Split each semicolon-separated list and standardize the write-in label.
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
)

SELECT
    response_id,
    ai_task,
    ai_task_status,
    ai_task_status_order,
    MIN(task_position) AS task_position

FROM split_tasks

WHERE ai_task IS NOT NULL
-- Remove duplicate selections within the same respondent-task-status grain,
-- while preserving the earliest source-list position.
GROUP BY
    response_id,
    ai_task,
    ai_task_status,
    ai_task_status_order