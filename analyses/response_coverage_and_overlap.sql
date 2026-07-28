-- Response coverage and overlap validation
-- for the final Stack Overflow Developer Survey 2025 analysis.

/*
Purpose:
    Summarize respondent coverage for the survey questions used in the
    three final analytical marts:

        - mart_ai_trust_by_task
        - mart_ai_trust_by_frustration
        - mart_ai_trust_by_role

    The query also calculates the respondent intersections used to explain
    why the marts have different population sizes and denominators.

Missing values:
    Missing source values are converted to SQL NULL in stg_survey_results.

Response definitions:
    - AI trust: ai_trust_level is populated.
    - AI frustrations: the respondent selected at least one option in the
      AI-frustration question.
    - AI task delegation: at least one field in the AI-task matrix is populated.
    - Developer role: developer_role is populated.

This is a diagnostic analysis query. It is not materialized as a database
relation and is not used as a Tableau data source.
*/

WITH response_flags AS (

    SELECT
        response_id,

        -- Required by all three final analytical marts.
        ai_trust_level IS NOT NULL
            AS has_ai_trust,

        -- Used by mart_ai_trust_by_frustration.
        ai_frustrations IS NOT NULL
            AS has_ai_frustrations,

        -- Used by mart_ai_trust_by_task.
        COALESCE(
            ai_tasks_currently_partially_ai,
            ai_tasks_currently_mostly_ai,
            ai_tasks_plan_to_partially_use,
            ai_tasks_plan_to_mostly_use,
            ai_tasks_do_not_plan_to_use
        ) IS NOT NULL
            AS has_ai_task_delegation,

        -- Used by mart_ai_trust_by_role.
        developer_role IS NOT NULL
            AS has_developer_role

    FROM {{ ref('stg_survey_results') }}

)

SELECT
    COUNT(*) AS total_respondents,

    -- Individual question coverage.
    COUNT_IF(has_ai_trust)
        AS ai_trust_answers,

    COUNT_IF(has_ai_frustrations)
        AS ai_frustration_answers,

    COUNT_IF(has_ai_task_delegation)
        AS ai_task_delegation_answers,

    COUNT_IF(has_developer_role)
        AS developer_role_answers,

    -- Respondent populations used by the final marts.
    COUNT_IF(
        has_ai_trust
        AND has_ai_frustrations
    ) AS trust_frustration_overlap,

    COUNT_IF(
        has_ai_trust
        AND has_ai_task_delegation
    ) AS trust_task_delegation_overlap,

    COUNT_IF(
        has_ai_trust
        AND has_developer_role
    ) AS trust_role_overlap

FROM response_flags;