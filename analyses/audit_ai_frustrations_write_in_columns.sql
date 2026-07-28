{% set survey_relation = ref('stg_survey_results') %}

-- Lists all AI-frustration-related columns in the resolved staging relation and
-- classifies plausible write-in fields separately from other related fields.

SELECT
    table_catalog,
    table_schema,
    table_name,
    column_name,
    data_type,
    ordinal_position,

    CASE
        WHEN column_name = 'AI_FRUSTRATIONS'
            THEN 'primary multi-select field'
        WHEN (
            column_name ILIKE '%OTHER%'
            OR column_name ILIKE '%WRITE%'
            OR column_name ILIKE '%TEXT%'
            OR column_name ILIKE '%COMMENT%'
            OR column_name ILIKE '%FREE%'
        )
            THEN 'possible AI-frustration write-in field'
        ELSE 'other AI-frustration-related field'
    END AS column_role

FROM {{ survey_relation.database }}.information_schema.columns

WHERE table_catalog = UPPER('{{ survey_relation.database }}')
  AND table_schema = UPPER('{{ survey_relation.schema }}')
  AND table_name = UPPER('{{ survey_relation.identifier }}')
  AND (
      column_name ILIKE '%AI%FRUSTR%'
      OR column_name ILIKE '%FRUSTR%AI%'
  )

ORDER BY ordinal_position