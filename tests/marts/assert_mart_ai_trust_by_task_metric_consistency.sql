-- Validates count hierarchy, share bounds and the two published share formulas.
-- Expected result: zero rows.

SELECT
    ai_trust_level,
    ai_task,
    ai_task_status,
    respondent_count,
    trust_task_respondent_count,
    trust_group_respondent_count,
    respondent_share_within_trust,
    respondent_share_within_trust_task

FROM {{ ref('mart_ai_trust_by_task') }}

WHERE respondent_count < 0
   OR trust_task_respondent_count <= 0
   OR trust_group_respondent_count <= 0
   OR respondent_count > trust_task_respondent_count
   OR trust_task_respondent_count > trust_group_respondent_count
   OR respondent_share_within_trust < 0
   OR respondent_share_within_trust > 1
   OR respondent_share_within_trust_task < 0
   OR respondent_share_within_trust_task > 1
   OR ABS(
        respondent_share_within_trust
        - ROUND(
            respondent_count::FLOAT
            / NULLIF(trust_group_respondent_count, 0),
            4
        )
      ) > 0.00005
   OR ABS(
        respondent_share_within_trust_task
        - ROUND(
            respondent_count::FLOAT
            / NULLIF(trust_task_respondent_count, 0),
            4
        )
      ) > 0.00005