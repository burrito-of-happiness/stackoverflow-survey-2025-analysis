/*
Model: stg_survey_results

Grain: One row per survey respondent.

Purpose:
    Clean and standardize all columns from the Stack Overflow Developer Survey 2025 while preserving the source-level grain.

Transformations:
    - rename columns to snake_case;
    - convert 'NA' and blank strings to SQL NULL;
    - trim text values;
    - safely cast strictly numeric fields;
    - preserve raw multi-select and ranking structures.

Not included:
    - analytical groupings;
    - splitting multi-select values;
    - unpivoting ranking and matrix questions;
    - aggregations.
*/

SELECT

    -- Respondent identifier
    RESPONSEID AS response_id,

    -- Demographics
    {{ clean_na('MAINBRANCH') }} AS main_branch,
    {{ clean_na('AGE') }} AS age_group,
    {{ clean_na('EDLEVEL') }} AS education_level,
    {{ clean_na('COUNTRY') }} AS country,

    -- Employment, career and compensation
    {{ clean_na('EMPLOYMENT') }} AS employment,
    {{ clean_na('EMPLOYMENTADDL') }} AS additional_employment,
    TRY_CAST({{ clean_na('WORKEXP') }} AS NUMBER(38, 0)) AS years_professional,
    TRY_CAST({{ clean_na('YEARSCODE') }} AS NUMBER(38, 0)) AS years_coding_total, 
    {{ clean_na('DEVTYPE') }} AS developer_role,
    {{ clean_na('ORGSIZE') }} AS organization_size,
    {{ clean_na('ICORPM') }} AS ic_or_manager,
    {{ clean_na('REMOTEWORK') }} AS remote_work,
    {{ clean_na('INDUSTRY') }} AS industry,
    {{ clean_na('CURRENCY') }} AS currency,
    TRY_CAST({{ clean_na('COMPTOTAL') }} AS NUMBER(38, 2)) AS compensation_total_local,
    TRY_CAST({{ clean_na('CONVERTEDCOMPYEARLY') }} AS NUMBER(38, 2)) AS compensation_yearly_usd,

    -- Learning and professional development
    {{ clean_na('LEARNCODECHOOSE') }} AS coding_learning_status_past_year,
    {{ clean_na('LEARNCODE') }} AS learning_resources_used_past_year,
    {{ clean_na('LEARNCODEAI') }} AS ai_learning_status_past_year,
    {{ clean_na('AILEARNHOW') }} AS ai_learning_methods_used_past_year,

    -- Technology influence and selection context
    {{ clean_na('PURCHASEINFLUENCE') }} AS purchase_influence,
    {{ clean_na('TECHENDORSEINTRO') }} AS technology_selection_context,

    -- Technology endorsement rankings
    TRY_CAST({{ clean_na('TECHENDORSE_1') }} AS NUMBER(38, 0)) AS tech_endorse_ai_capabilities_rank,
    TRY_CAST({{ clean_na('TECHENDORSE_2') }} AS NUMBER(38, 0)) AS tech_endorse_easy_api_rank,
    TRY_CAST({{ clean_na('TECHENDORSE_3') }} AS NUMBER(38, 0)) AS tech_endorse_robust_api_rank,
    TRY_CAST({{ clean_na('TECHENDORSE_4') }} AS NUMBER(38, 0)) AS tech_endorse_customizable_codebase_rank,
    TRY_CAST({{ clean_na('TECHENDORSE_5') }} AS NUMBER(38, 0)) AS tech_endorse_quality_reputation_rank,
    TRY_CAST({{ clean_na('TECHENDORSE_6') }} AS NUMBER(38, 0)) AS tech_endorse_open_source_rank,
    TRY_CAST({{ clean_na('TECHENDORSE_7') }} AS NUMBER(38, 0)) AS tech_endorse_brand_image_rank,
    TRY_CAST({{ clean_na('TECHENDORSE_8') }} AS NUMBER(38, 0)) AS tech_endorse_reliability_low_latency_rank,
    TRY_CAST({{ clean_na('TECHENDORSE_9') }} AS NUMBER(38, 0)) AS tech_endorse_manageable_cost_rank,
    TRY_CAST({{ clean_na('TECHENDORSE_13') }} AS NUMBER(38, 0)) AS tech_endorse_other_rank,
    {{ clean_na('TECHENDORSE_13_TEXT') }} AS tech_endorse_other_text,

    -- Technology rejection rankings
    TRY_CAST({{ clean_na('TECHOPPOSE_1') }} AS NUMBER(38, 0)) AS tech_reject_lack_of_ai_rank,
    TRY_CAST({{ clean_na('TECHOPPOSE_2') }} AS NUMBER(38, 0)) AS tech_reject_poor_usability_rank,
    TRY_CAST({{ clean_na('TECHOPPOSE_3') }} AS NUMBER(38, 0)) AS tech_reject_poor_api_rank,
    TRY_CAST({{ clean_na('TECHOPPOSE_5') }} AS NUMBER(38, 0)) AS tech_reject_inefficient_or_time_costly_rank,
    TRY_CAST({{ clean_na('TECHOPPOSE_7') }} AS NUMBER(38, 0)) AS tech_reject_prohibitive_pricing_rank,
    TRY_CAST({{ clean_na('TECHOPPOSE_9') }} AS NUMBER(38, 0)) AS tech_reject_security_or_privacy_rank,
    TRY_CAST({{ clean_na('TECHOPPOSE_11') }} AS NUMBER(38, 0)) AS tech_reject_better_alternatives_rank,
    TRY_CAST({{ clean_na('TECHOPPOSE_13') }} AS NUMBER(38, 0)) AS tech_reject_outdated_technology_rank,
    TRY_CAST({{ clean_na('TECHOPPOSE_16') }} AS NUMBER(38, 0)) AS tech_reject_ethical_concerns_rank,
    TRY_CAST({{ clean_na('TECHOPPOSE_15') }} AS NUMBER(38, 0)) AS tech_reject_other_rank,
    {{ clean_na('TECHOPPOSE_15_TEXT') }} AS tech_reject_other_text,


-- Job satisfaction and career sentiment
    TRY_CAST({{ clean_na('JOBSAT') }} AS NUMBER(38, 0)) AS job_satisfaction_score,
    {{ clean_na('AITHREAT') }} AS ai_threat_perception,
    {{ clean_na('NEWROLE') }} AS career_change_status,
    TRY_CAST({{ clean_na('TOOLCOUNTWORK') }} AS NUMBER(38, 0)) AS workplace_tool_count,
    TRY_CAST({{ clean_na('TOOLCOUNTPERSONAL') }} AS NUMBER(38, 0)) AS personal_tool_count,
    TRY_CAST({{ clean_na('JOBSATPOINTS_1') }} AS NUMBER(38, 0)) AS job_satisfaction_quality_control_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_2') }} AS NUMBER(38, 0)) AS job_satisfaction_autonomy_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_3') }} AS NUMBER(38, 0)) AS job_satisfaction_team_collaboration_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_4') }} AS NUMBER(38, 0)) AS job_satisfaction_expert_mentors_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_5') }} AS NUMBER(38, 0)) AS job_satisfaction_mentoring_others_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_6') }} AS NUMBER(38, 0)) AS job_satisfaction_specialized_expertise_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_7') }} AS NUMBER(38, 0)) AS job_satisfaction_real_world_problems_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_8') }} AS NUMBER(38, 0)) AS job_satisfaction_job_stability_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_9') }} AS NUMBER(38, 0)) AS job_satisfaction_innovation_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_10') }} AS NUMBER(38, 0)) AS job_satisfaction_new_technologies_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_11') }} AS NUMBER(38, 0)) AS job_satisfaction_pay_benefits_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_13') }} AS NUMBER(38, 0)) AS job_satisfaction_peer_recognition_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_14') }} AS NUMBER(38, 0)) AS job_satisfaction_leadership_recognition_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_16') }} AS NUMBER(38, 0)) AS job_satisfaction_like_manager_rank,
    TRY_CAST({{ clean_na('JOBSATPOINTS_15') }} AS NUMBER(38, 0)) AS job_satisfaction_other_rank,
    {{ clean_na('JOBSATPOINTS_15_TEXT') }} AS job_satisfaction_other_text,
 

    -- Programming languages
    {{ clean_na('LANGUAGECHOICE') }} AS language_choice,
    {{ clean_na('LANGUAGEHAVEWORKEDWITH') }} AS languages_have_worked_with,
    {{ clean_na('LANGUAGEWANTTOWORKWITH') }} AS languages_want_to_work_with,
    {{ clean_na('LANGUAGEADMIRED') }} AS languages_admired,
    {{ clean_na('LANGUAGESHAVEENTRY') }} AS languages_have_worked_with_other,
    {{ clean_na('LANGUAGESWANTENTRY') }} AS languages_want_to_work_with_other,

    -- Databases
    {{ clean_na('DATABASECHOICE') }} AS database_choice,
    {{ clean_na('DATABASEHAVEWORKEDWITH') }} AS databases_have_worked_with,
    {{ clean_na('DATABASEWANTTOWORKWITH') }} AS databases_want_to_work_with,
    {{ clean_na('DATABASEADMIRED') }} AS databases_admired,
    {{ clean_na('DATABASEHAVEENTRY') }} AS databases_have_worked_with_other,
    {{ clean_na('DATABASEWANTENTRY') }} AS databases_want_to_work_with_other,

    -- Cloud and development platforms
    {{ clean_na('PLATFORMCHOICE') }} AS platform_choice,
    {{ clean_na('PLATFORMHAVEWORKEDWITH') }} AS platforms_have_worked_with,
    {{ clean_na('PLATFORMWANTTOWORKWITH') }} AS platforms_want_to_work_with,
    {{ clean_na('PLATFORMADMIRED') }} AS platforms_admired,
    {{ clean_na('PLATFORMHAVEENTRY') }} AS platforms_have_worked_with_other,
    {{ clean_na('PLATFORMWANTENTRY') }} AS platforms_want_to_work_with_other,

    -- Web frameworks and technologies
    {{ clean_na('WEBFRAMECHOICE') }} AS web_framework_choice,
    {{ clean_na('WEBFRAMEHAVEWORKEDWITH') }} AS web_frameworks_have_worked_with,
    {{ clean_na('WEBFRAMEWANTTOWORKWITH') }} AS web_frameworks_want_to_work_with,
    {{ clean_na('WEBFRAMEADMIRED') }} AS web_frameworks_admired,
    {{ clean_na('WEBFRAMEHAVEENTRY') }} AS web_frameworks_have_worked_with_other,
    {{ clean_na('WEBFRAMEWANTENTRY') }} AS web_frameworks_want_to_work_with_other,

    -- Development environments
    {{ clean_na('DEVENVSCHOICE') }} AS development_environment_choice,
    {{ clean_na('DEVENVSHAVEWORKEDWITH') }} AS development_environments_have_worked_with,
    {{ clean_na('DEVENVSWANTTOWORKWITH') }} AS development_environments_want_to_work_with,
    {{ clean_na('DEVENVSADMIRED') }} AS development_environments_admired,
    {{ clean_na('DEVENVHAVEENTRY') }} AS development_environments_have_worked_with_other,
    {{ clean_na('DEVENVWANTENTRY') }} AS development_environments_want_to_work_with_other,

    -- Stack Overflow tags
    {{ clean_na('SOTAGSHAVEWORKEDWITH') }} AS so_tags_have_worked_with,
    {{ clean_na('SOTAGSWANTTOWORKWITH') }} AS so_tags_want_to_work_with,
    {{ clean_na('SOTAGSADMIRED') }} AS so_tags_admired,
    {{ clean_na('SOTAGSHAVEENTRY') }} AS so_tags_have_worked_with_other,
    {{ clean_na('SOTAGSWANTENTRY') }} AS so_tags_want_to_work_with_other,

    -- Operating systems
    {{ clean_na('OPSYSPERSONALUSE') }} AS operating_systems_personal_use,
    {{ clean_na('OPSYSPROFESSIONALUSE') }} AS operating_systems_professional_use,

    -- Collaboration tools
    {{ clean_na('OFFICESTACKASYNCHAVEWORKEDWITH') }} AS collaboration_tools_have_worked_with,
    {{ clean_na('OFFICESTACKASYNCWANTTOWORKWITH') }} AS collaboration_tools_want_to_work_with,
    {{ clean_na('OFFICESTACKASYNCADMIRED') }} AS collaboration_tools_admired,
    {{ clean_na('OFFICESTACKHAVEENTRY') }} AS collaboration_tools_have_worked_with_other,
    {{ clean_na('OFFICESTACKWANTENTRY') }} AS collaboration_tools_want_to_work_with_other,

    -- Community platforms
    {{ clean_na('COMMPLATFORMHAVEWORKEDWITH') }} AS community_platforms_have_worked_with,
    {{ clean_na('COMMPLATFORMWANTTOWORKWITH') }} AS community_platforms_want_to_work_with,
    {{ clean_na('COMMPLATFORMADMIRED') }} AS community_platforms_admired,
    {{ clean_na('COMMPLATFORMHAVEENTR') }} AS community_platforms_have_worked_with_other,
    {{ clean_na('COMMPLATFORMWANTENTR') }} AS community_platforms_want_to_work_with_other,

    -- AI models
    {{ clean_na('AIMODELSCHOICE') }} AS ai_model_choice,
    {{ clean_na('AIMODELSHAVEWORKEDWITH') }} AS ai_models_have_worked_with,
    {{ clean_na('AIMODELSWANTTOWORKWITH') }} AS ai_models_want_to_work_with,
    {{ clean_na('AIMODELSADMIRED') }} AS ai_models_admired,
    {{ clean_na('AIMODELSHAVEENTRY') }} AS ai_models_have_worked_with_other,
    {{ clean_na('AIMODELSWANTENTRY') }} AS ai_models_want_to_work_with_other,

    -- Stack Overflow engagement
    {{ clean_na('SOACCOUNT') }} AS so_account_status,
    {{ clean_na('SOVISITFREQ') }} AS so_visit_frequency,
    {{ clean_na('SODURATION') }} AS so_usage_duration,
    {{ clean_na('SOPARTFREQ') }} AS so_participation_frequency,
    {{ clean_na('SO_DEV_CONTENT') }} AS so_developer_content_preferences,
       {{ clean_na('SO_ACTIONS_1') }} AS so_action_browse_recent_related_content_rank,
    {{ clean_na('SO_ACTIONS_16') }} AS so_action_read_vote_comments_rank,
    {{ clean_na('SO_ACTIONS_3') }} AS so_action_bookmark_posts_rank,
    {{ clean_na('SO_ACTIONS_4') }} AS so_action_direct_open_post_rank,
    {{ clean_na('SO_ACTIONS_5') }} AS so_action_ask_question_rank,
    {{ clean_na('SO_ACTIONS_6') }} AS so_action_answer_question_rank,
    {{ clean_na('SO_ACTIONS_9') }} AS so_action_comment_on_posts_rank,
    {{ clean_na('SO_ACTIONS_7') }} AS so_action_upvote_downvote_posts_rank,
    {{ clean_na('SO_ACTIONS_10') }} AS so_action_use_chat_feature_rank,
    {{ clean_na('SO_ACTIONS_15') }} AS so_action_other_rank,
    {{ clean_na('SO_ACTIONS_15_TEXT') }} AS so_action_other_text,
    {{ clean_na('SOCOMM') }} AS so_community_belonging,
    {{ clean_na('SOFRICTION') }} AS so_friction,

    -- AI usage, sentiment and trust
    {{ clean_na('AISELECT') }} AS ai_usage_status,
    {{ clean_na('AISENT') }} AS ai_sentiment,
    {{ clean_na('AIACC') }} AS ai_trust_level,
    {{ clean_na('AICOMPLEX') }} AS ai_complex_task_rating,
    {{ clean_na('AIFRUSTRATION') }} AS ai_frustrations,
    {{ clean_na('AIEXPLAIN') }} AS vibe_coding_explanation,
    {{ clean_na('AIHUMAN') }} AS ai_human_help_situations,
    {{ clean_na('AIOPEN') }} AS future_developer_skills,

    -- AI task delegation matrix
    {{ clean_na('AITOOLCURRENTLYPARTIALLYAI') }} AS ai_tasks_currently_partially_ai,
    {{ clean_na('AITOOLDONTPLANTOUSEAIFORTHISTASK') }} AS ai_tasks_do_not_plan_to_use,
    {{ clean_na('AITOOLPLANTOPARTIALLYUSEAI') }} AS ai_tasks_plan_to_partially_use,
    {{ clean_na('AITOOLPLANTOMOSTLYUSEAI') }} AS ai_tasks_plan_to_mostly_use,
    {{ clean_na('AITOOLCURRENTLYMOSTLYAI') }} AS ai_tasks_currently_mostly_ai,

    -- AI agents
    {{ clean_na('AIAGENTS') }} AS ai_agent_usage,
    {{ clean_na('AIAGENTCHANGE') }} AS ai_agent_workflow_change,
    {{ clean_na('AIAGENT_USES') }} AS ai_agent_uses,
    {{ clean_na('AGENTUSESGENERAL') }} AS ai_agent_general_uses,
    {{ clean_na('AIAGENTIMPACTSOMEWHATAGREE') }} AS ai_agent_impact_somewhat_agree,
    {{ clean_na('AIAGENTIMPACTNEUTRAL') }} AS ai_agent_impact_neutral,
    {{ clean_na('AIAGENTIMPACTSOMEWHATDISAGREE') }} AS ai_agent_impact_somewhat_disagree,
    {{ clean_na('AIAGENTIMPACTSTRONGLYAGREE') }} AS ai_agent_impact_strongly_agree,
    {{ clean_na('AIAGENTIMPACTSTRONGLYDISAGREE') }} AS ai_agent_impact_strongly_disagree,
    {{ clean_na('AIAGENTCHALLENGESNEUTRAL') }} AS ai_agent_challenges_neutral,
    {{ clean_na('AIAGENTCHALLENGESSOMEWHATDISAGREE') }} AS ai_agent_challenges_somewhat_disagree,
    {{ clean_na('AIAGENTCHALLENGESSTRONGLYAGREE') }} AS ai_agent_challenges_strongly_agree,
    {{ clean_na('AIAGENTCHALLENGESSOMEWHATAGREE') }} AS ai_agent_challenges_somewhat_agree,
    {{ clean_na('AIAGENTCHALLENGESSTRONGLYDISAGREE') }} AS ai_agent_challenges_strongly_disagree,
    {{ clean_na('AIAGENTKNOWLEDGE') }} AS ai_agent_memory_tools,
    {{ clean_na('AIAGENTKNOWWRITE') }} AS ai_agent_memory_tools_other,
    {{ clean_na('AIAGENTORCHESTRATION') }} AS ai_agent_orchestration_tools,
    {{ clean_na('AIAGENTORCHWRITE') }} AS ai_agent_orchestration_tools_other,
    {{ clean_na('AIAGENTOBSERVESECURE') }} AS ai_agent_observability_security_tools,
    {{ clean_na('AIAGENTOBSWRITE') }} AS ai_agent_observability_security_tools_other,
    {{ clean_na('AIAGENTEXTERNAL') }} AS ai_agent_external_tools,
    {{ clean_na('AIAGENTEXTWRITE') }} AS ai_agent_external_tools_other

FROM {{ source('survey_raw', 'survey_results') }}