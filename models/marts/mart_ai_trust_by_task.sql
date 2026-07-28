{{ config(materialized='table') }}

WITH respondent_tasks AS (

    -- One row per respondent, development task and AI adoption status.
    -- Upstream tests enforce a unique response_id in stg_survey_results and
    -- one row per response_id, ai_task and ai_task_status in int_ai_tasks_long.

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
-- Denominator 1: respondents in each trust group who answered at least one item in the AI task matrix.
    SELECT
        ai_trust_level,
        ai_trust_order,
        COUNT(DISTINCT response_id)
            AS trust_group_respondent_count
    FROM respondent_tasks
    GROUP BY
        ai_trust_level,
        ai_trust_order
),

trust_task_totals AS (
    -- Denominator 2: respondents in each trust group who assigned any AI adoption status to the specific development task.
    SELECT
        ai_trust_level,
        ai_trust_order,
        ai_task,
        COUNT(DISTINCT response_id)
            AS trust_task_respondent_count
    FROM respondent_tasks
    GROUP BY
        ai_trust_level,
        ai_trust_order,
        ai_task

),

status_counts AS (
    -- Numerator: respondents in the trust group who assigned the specific status to the specific task.
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

final AS (
    SELECT
        status_counts.ai_trust_level,
        status_counts.ai_trust_order,
        status_counts.ai_task,
        status_counts.ai_task_status,
        status_counts.ai_task_status_order,
        status_counts.respondent_count,
        trust_group_totals.trust_group_respondent_count,
        trust_task_totals.trust_task_respondent_count,

         ROUND(
            status_counts.respondent_count::FLOAT
            / NULLIF(trust_group_totals.trust_group_respondent_count, 0),
            4
        ) AS respondent_share_within_trust,

        ROUND(
            status_counts.respondent_count::FLOAT
            / NULLIF(trust_task_totals.trust_task_respondent_count, 0),
            4
        ) AS respondent_share_within_trust_task

    FROM status_counts

    INNER JOIN trust_group_totals
        ON status_counts.ai_trust_level
            = trust_group_totals.ai_trust_level
        AND status_counts.ai_trust_order
            = trust_group_totals.ai_trust_order

    INNER JOIN trust_task_totals
        ON status_counts.ai_trust_level
            = trust_task_totals.ai_trust_level
        AND status_counts.ai_trust_order
            = trust_task_totals.ai_trust_order
        AND status_counts.ai_task
            = trust_task_totals.ai_task

)

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

FROM final