-- Fails if the mart contains more than one row
-- for the same trust level, task and AI adoption status.
SELECT
    ai_trust_level,
    ai_task,
    ai_task_status,
    COUNT(*) AS row_count

FROM {{ ref('mart_ai_trust_by_task') }}

GROUP BY
    ai_trust_level,
    ai_task,
    ai_task_status

HAVING COUNT(*) > 1