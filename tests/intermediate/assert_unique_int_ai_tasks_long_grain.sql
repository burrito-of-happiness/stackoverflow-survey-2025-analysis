-- Singular dbt test: validates that int_ai_tasks_long contains no duplicate
-- rows at its declared grain: one row per response_id, ai_task and ai_task_status.
-- Expected result: zero rows.

SELECT
    response_id,
    ai_task,
    ai_task_status,
    COUNT(*) AS row_count

FROM {{ ref('int_ai_tasks_long') }}

GROUP BY
    response_id,
    ai_task,
    ai_task_status

HAVING COUNT(*) > 1