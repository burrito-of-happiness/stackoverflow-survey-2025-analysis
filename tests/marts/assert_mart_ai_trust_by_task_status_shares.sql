-- For each trust-level/task combination, respondents should be distributed
-- across mutually exclusive statuses. Rounded shares should sum to about 1,
-- and summed status counts should equal the task denominator.
-- Expected result: zero rows.

SELECT
    ai_trust_level,
    ai_task,
    SUM(respondent_count) AS summed_status_respondent_count,
    MIN(trust_task_respondent_count) AS minimum_task_denominator,
    MAX(trust_task_respondent_count) AS maximum_task_denominator,
    SUM(respondent_share_within_trust_task) AS summed_status_share

FROM {{ ref('mart_ai_trust_by_task') }}

GROUP BY
    ai_trust_level,
    ai_task

HAVING MIN(trust_task_respondent_count)
        <> MAX(trust_task_respondent_count)
    OR SUM(respondent_count)
        <> MAX(trust_task_respondent_count)
    OR ABS(
        SUM(respondent_share_within_trust_task) - 1
       ) > 0.0005