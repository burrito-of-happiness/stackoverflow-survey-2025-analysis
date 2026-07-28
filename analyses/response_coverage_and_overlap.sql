-- Response coverage and overlap validation for Stack Overflow 2025 survey analysis
-- Co-authored with CoCo
/*
Purpose:
    Check response coverage and intersections between the survey questions used in the analysis.
Why:
    A respondent may answer only 1 question of 2 questions (just skip another). 
    The analysis must use the number of respondents who answered both questions as its denominator.
Missing values:
       Missing source values were converted to SQL NULL in stg_survey_results.
A respondent is considered to have answered a matrix or
    ranking question when at least one related field is populated.
*/

WITH response_flags AS (

    SELECT
        response_id,

        -- AI trust and frustrations
        ai_trust_level IS NOT NULL
            AS has_ai_trust,

        ai_frustrations IS NOT NULL
            AS has_ai_frustrations,

        -- AI task-delegation matrix
        COALESCE(
            ai_tasks_currently_partially_ai,
            ai_tasks_currently_mostly_ai,
            ai_tasks_plan_to_partially_use,
            ai_tasks_plan_to_mostly_use,
            ai_tasks_do_not_plan_to_use
        ) IS NOT NULL
            AS has_ai_task_delegation,

        -- Role and experience
        developer_role IS NOT NULL
            AS has_developer_role,

        years_professional IS NOT NULL
            AS has_work_experience,

        -- Technology influence
        purchase_influence IS NOT NULL
            AS has_purchase_influence,

        -- Technology endorsement ranking
        COALESCE(
            tech_endorse_ai_capabilities_rank,
            tech_endorse_easy_api_rank,
            tech_endorse_robust_api_rank,
            tech_endorse_customizable_codebase_rank,
            tech_endorse_quality_reputation_rank,
            tech_endorse_open_source_rank,
            tech_endorse_brand_image_rank,
            tech_endorse_reliability_low_latency_rank,
            tech_endorse_manageable_cost_rank,
            tech_endorse_other_rank
        ) IS NOT NULL
            AS has_technology_endorsement,

        -- Technology rejection ranking
        COALESCE(
            tech_reject_lack_of_ai_rank,
            tech_reject_poor_usability_rank,
            tech_reject_poor_api_rank,
            tech_reject_inefficient_or_time_costly_rank,
            tech_reject_prohibitive_pricing_rank,
            tech_reject_security_or_privacy_rank,
            tech_reject_better_alternatives_rank,
            tech_reject_outdated_technology_rank,
            tech_reject_ethical_concerns_rank,
            tech_reject_other_rank
        ) IS NOT NULL
            AS has_technology_rejection

    FROM {{ ref('stg_survey_results') }}

)

SELECT
    COUNT(*) AS total_respondents,

    -- AI question coverage
    COUNT_IF(has_ai_trust)
        AS ai_trust_answers,

    COUNT_IF(has_ai_frustrations)
        AS ai_frustration_answers,

    COUNT_IF(has_ai_task_delegation)
        AS ai_task_delegation_answers,

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
        AND has_work_experience
    ) AS trust_role_experience_overlap,

    -- Technology decision coverage
    COUNT_IF(has_purchase_influence)
        AS purchase_influence_answers,

    COUNT_IF(has_technology_endorsement)
        AS technology_endorsement_answers,

    COUNT_IF(has_technology_rejection)
        AS technology_rejection_answers,

    COUNT_IF(
        has_purchase_influence
        AND has_technology_endorsement
    ) AS purchase_endorsement_overlap,

    COUNT_IF(
        has_purchase_influence
        AND has_technology_rejection
    ) AS purchase_rejection_overlap

FROM response_flags