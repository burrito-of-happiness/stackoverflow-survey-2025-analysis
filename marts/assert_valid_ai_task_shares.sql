SELECT
    ai_trust_level,
    ai_task,
    ai_task_status,
    respondent_share_within_trust,
    respondent_share_within_trust_task

FROM {{ ref('mart_ai_trust_by_task') }}

WHERE respondent_share_within_trust NOT BETWEEN 0 AND 1
   OR respondent_share_within_trust_task NOT BETWEEN 0 AND 1