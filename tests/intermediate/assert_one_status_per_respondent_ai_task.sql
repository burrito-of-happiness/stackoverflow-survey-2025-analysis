-- Validates that a respondent did not assign more than one AI usage status to the same development task.
-- Expected result: zero rows.

SELECT
    response_id,
    ai_task,
    COUNT(DISTINCT ai_task_status) AS status_count
FROM {{ ref('int_ai_tasks_long') }}
GROUP BY
    response_id,
    ai_task
HAVING COUNT(DISTINCT ai_task_status) > 1