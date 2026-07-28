-- Independently rebuilds the expected mart from its two upstream models and
-- compares every published row and metric with mart_ai_trust_by_task.
-- Expected result: zero rows.

WITH respondent_tasks AS (

    SELECT
        tasks.response_id,
        survey.ai_trust_level,

        CASE survey.ai_trust_level
            WHEN 'Highly trust' THEN 1
            WHEN 'Somewhat trust' THEN 2
            WHEN 'Neither trust nor distrust' THEN 3
            WHEN 'Somewhat distrust' THEN 4
            WHEN 'Highly distrust' THEN 5
        END AS ai_trust_order,

        tasks.ai_task,
        tasks.ai_task_status,
        tasks.ai_task_status_order

    FROM {{ ref('int_ai_tasks_long') }} AS tasks

    INNER JOIN {{ ref('stg_survey_results') }} AS survey
        ON tasks.response_id = survey.response_id

    WHERE survey.ai_trust_level IS NOT NULL

),

trust_group_totals AS (

    SELECT
        ai_trust_level,
        ai_trust_order,
        COUNT(DISTINCT response_id) AS trust_group_respondent_count

    FROM respondent_tasks

    GROUP BY
        ai_trust_level,
        ai_trust_order

),

trust_task_totals AS (

    SELECT
        ai_trust_level,
        ai_trust_order,
        ai_task,
        COUNT(DISTINCT response_id) AS trust_task_respondent_count

    FROM respondent_tasks

    GROUP BY
        ai_trust_level,
        ai_trust_order,
        ai_task

),

status_counts AS (

    SELECT
        ai_trust_level,
        ai_trust_order,
        ai_task,
        ai_task_status,
        ai_task_status_order,
        COUNT(DISTINCT response_id) AS respondent_count

    FROM respondent_tasks

    GROUP BY
        ai_trust_level,
        ai_trust_order,
        ai_task,
        ai_task_status,
        ai_task_status_order

),

expected AS (

    SELECT
        status.ai_trust_level,
        status.ai_trust_order,
        status.ai_task,
        status.ai_task_status,
        status.ai_task_status_order,
        status.respondent_count,
        groups.trust_group_respondent_count,
        tasks.trust_task_respondent_count,

        ROUND(
            status.respondent_count::FLOAT
            / NULLIF(groups.trust_group_respondent_count, 0),
            4
        ) AS respondent_share_within_trust,

        ROUND(
            status.respondent_count::FLOAT
            / NULLIF(tasks.trust_task_respondent_count, 0),
            4
        ) AS respondent_share_within_trust_task

    FROM status_counts AS status

    INNER JOIN trust_group_totals AS groups
        ON status.ai_trust_level = groups.ai_trust_level
       AND status.ai_trust_order = groups.ai_trust_order

    INNER JOIN trust_task_totals AS tasks
        ON status.ai_trust_level = tasks.ai_trust_level
       AND status.ai_trust_order = tasks.ai_trust_order
       AND status.ai_task = tasks.ai_task

),

actual AS (

    SELECT
        ai_trust_level,
        ai_trust_order,
        ai_task,
        ai_task_status,
        ai_task_status_order,
        respondent_count,
        trust_group_respondent_count,
        trust_task_respondent_count,
        respondent_share_within_trust,
        respondent_share_within_trust_task

    FROM {{ ref('mart_ai_trust_by_task') }}

),

missing_rows AS (

    SELECT * FROM expected

    EXCEPT

    SELECT * FROM actual

),

unexpected_rows AS (

    SELECT * FROM actual

    EXCEPT

    SELECT * FROM expected

)

SELECT
    'missing_from_mart' AS reconciliation_issue,
    *

FROM missing_rows

UNION ALL

SELECT
    'unexpected_in_mart' AS reconciliation_issue,
    *

FROM unexpected_rows