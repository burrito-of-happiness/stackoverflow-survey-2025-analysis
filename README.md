# Stack Overflow Developer Survey 2025 Analysis

## 1. Objective

This project analyzes how developers evaluate AI tools, focusing on three areas:

1. The relationship between AI trust and task delegation.
2. AI-related frustrations across trust groups.
3. Differences in AI trust across developer roles.

The analysis complements the public Stack Overflow Developer Survey results by examining relationships between multiple survey questions at the respondent level.

## 2. Dataset

The analysis uses data from the **Stack Overflow Developer Survey 2025**, the 15th annual Stack Overflow survey.

The source files include:

* `results.csv` — survey responses, with one row per respondent;
* `schema.csv` — survey question definitions and column metadata;
* `survey.pdf` — survey structure and questionnaire documentation.

The dataset contains **172 raw columns** and several question types:

* **MC** — single-choice questions;
* **TE** — free-text fields, including numeric values stored as text;
* **Matrix** — multi-part questions such as technologies used or desired;
* **RO** — rank-ordering questions where each sub-column stores the position assigned to a particular option.

The 2025 survey includes an expanded AI section covering topics such as:

* AI trust;
* current and planned AI task delegation;
* AI-related frustrations;
* AI agents and agent-related tools;
* attitudes toward AI-generated outputs.

The public Stack Overflow results primarily present individual survey questions separately. This project instead focuses on respondent-level relationships between AI trust, AI task usage, frustrations, and developer roles.

## 3. Architecture

```text
Stack Overflow Developer Survey 2025
                |
                v
Snowflake
    raw survey results
                |
                v
dbt
                |
                v
staging
    stg_survey_results
        - cleans and standardizes survey responses
        - converts blank strings and literal 'NA' values to NULL
        - renames selected columns to snake_case
        - safely casts fields with unambiguous numeric meaning
        - preserves one row per respondent
                |
        +-------+----------------------+
        |                              |
        v                              v
intermediate                       intermediate
    int_ai_tasks_long                  int_ai_frustrations_long
        - converts AI task fields          - splits the AI-frustration
          from wide to long format           multi-select field
        - creates one row per              - normalizes response options
          respondent and AI task           - creates one row per respondent
        - retains current and                and normalized response option
          planned AI usage status          - preserves source position and
                                             repeated-selection information
        |                              |
        +---------------+--------------+
                        |
                        v
marts
    mart_ai_trust_by_task
        - analyzes current and planned AI task delegation
          by AI trust level

    mart_ai_trust_by_frustration
        - analyzes response options from the AI-frustration
          question by AI trust level
        - separates actual frustrations from answers indicating
          no regular AI use or no encountered problems
        - ranks actual frustrations by respondent count
          within each AI trust group

    mart_ai_trust_by_role
        - analyzes AI trust distribution
          by developer role
                        |
                        v
dbt tests and audit queries
        - validate model grain and uniqueness
        - check accepted values
        - validate counts, denominators, and percentage calculations
        - validate actual-frustration classification
        - validate dense frustration ranks within trust groups
        - identify unexpected or unmapped values
                        |
                        v
CSV exports of final mart tables
                        |
                        v
Tableau
        - uses the exported mart datasets
        - visualizes AI trust, task delegation,
          frustrations, and developer roles
```

### 3.1 Model layers

| Layer            | Purpose                                                                                                             |
| ---------------- | ------------------------------------------------------------------------------------------------------------------- |
| Raw              | Stores the original Stack Overflow Survey responses in Snowflake.                                                   |
| Staging          | Cleans, renames, standardizes, and safely casts source fields while preserving respondent-level grain.              |
| Intermediate     | Converts multi-column and multi-select survey questions into analysis-ready long-format datasets.                   |
| Marts            | Produces aggregated datasets used directly in Tableau.                                                              |
| Tests and audits | Validate grain, uniqueness, expected values, derived fields, denominator logic, ranks, and percentage calculations. |

### 3.2 Main analytical models

```text
models/
├── staging/
│   ├── stg_survey_results.sql
│   └── stg_survey_results.yml
│
├── intermediate/
│   ├── int_ai_tasks_long.sql
│   ├── int_ai_tasks_long.yml
│   ├── int_ai_frustrations_long.sql
│   └── int_ai_frustrations_long.yml
│
└── marts/
    ├── mart_ai_trust_by_task.sql
    ├── mart_ai_trust_by_task.yml
    ├── mart_ai_trust_by_frustration.sql
    ├── mart_ai_trust_by_frustration.yml
    ├── mart_ai_trust_by_role.sql
    └── mart_ai_trust_by_role.yml
```

The Tableau dashboard does not query the raw survey data directly. It uses only the final dbt mart outputs, ensuring that the visualizations rely on documented, tested, and reusable analytical logic.

## 4. Analytical Questions

The analysis focuses on the following questions:

1. How does trust in AI relate to developers' current and planned delegation of different tasks?
2. Which AI-related frustrations are most common within each AI trust group?
3. How does the distribution of AI trust vary across developer roles?

## 5. Data Transformation

The data was transformed using Snowflake SQL and dbt.

The transformation process includes:

* cleaning and standardizing raw survey responses;
* converting literal `NA` values and blank strings to SQL `NULL`;
* safely casting fields with clear numeric meaning;
* transforming wide AI task fields into a long-format dataset;
* splitting and normalizing the multi-select AI-frustration field;
* joining transformed responses with respondent-level AI trust and role attributes;
* aggregating distinct respondent counts and shares for dashboard use;
* separating actual AI frustrations from non-frustration response options;
* calculating dense frustration ranks within each AI trust group;
* validating model grain, accepted values, uniqueness, denominators, shares, classifications, and ranks.

Multi-select and multi-column survey questions are transformed in the intermediate layer rather than analyzed directly from the raw table. This makes the analytical grain explicit and reduces the risk of double counting respondents.

### 5.1 AI-frustration transformation

The source AI-frustration question is a multi-select field. The intermediate model creates one row per respondent and normalized response option.

The mart retains all response options, including:

* actual AI-related frustrations;
* `I don’t use AI tools regularly`;
* `I haven’t encountered any problems`.

The field `is_actual_frustration` distinguishes actual problem categories from the two response options that do not describe a frustration.

The denominator for `respondent_share_within_trust` includes respondents who:

1. provided an AI-trust response; and
2. selected at least one response option in the AI-frustration question.

Because the question is multi-select, one respondent may be counted under several response options. Therefore, shares within a trust group are not expected to sum to 100%.

The field `frustration_rank_within_trust` contains the dense rank of each actual frustration by respondent count within its AI trust group:

* rank `1` represents the most frequently selected actual frustration;
* frustrations with equal respondent counts receive the same rank;
* the two non-frustration response options have a `NULL` rank.

## 6. Data Quality Validation

The project includes schema tests, singular dbt tests, and audit queries.

The validation covers:

* source and model grain;
* uniqueness of business-key combinations;
* required and accepted values;
* respondent counts and denominators;
* calculated respondent shares;
* normalization of multi-select response options;
* classification of actual and non-actual frustrations;
* frustration ranks within each trust group.

The test `assert_mart_ai_trust_by_frustration_derived_fields.sql` validates the two derived fields in `mart_ai_trust_by_frustration`.

It verifies that:

1. `is_actual_frustration` is `FALSE` only for:

   * `I don’t use AI tools regularly`;
   * `I haven’t encountered any problems`.
2. `frustration_rank_within_trust` is `NULL` for those two response options.
3. Every actual frustration has a non-`NULL` dense rank.
4. The stored rank matches an independently calculated descending respondent-count rank within each AI trust group.

Like other singular dbt tests, it passes when the query returns zero rows.

## 7. Dashboard

The final dashboard was created in Tableau using CSV exports of the final dbt mart models.

The dashboard presents three analytical views:

1. **AI Task Delegation**

   Shows how current and planned AI usage for different tasks varies by AI trust level.

2. **AI Frustrations**

   Shows the prevalence and rank of actual AI-related frustrations within each trust group.

3. **AI Trust by Developer Role**

   Compares the distribution of AI trust across developer roles while displaying respondent counts for context.

Dashboard files are stored in the `dashboard/` folder.

Where available, the folder includes:

* the Tableau packaged workbook;
* a PDF export;
* PNG previews.

## 8. Key Findings

1. **Higher AI trust is associated with greater willingness to delegate tasks to AI.**

   Respondents with higher levels of AI trust are generally more likely to report that AI currently performs or is expected to perform at least part of a task.

2. **Willingness to delegate varies considerably by task type.**

   Developers are more open to using AI for supporting and knowledge-oriented activities than for tasks requiring broader context, accountability, or judgment.

3. **Trust does not eliminate frustration with AI tools.**

   Respondents across all trust groups report problems with AI-generated outputs. Even developers who generally trust AI experience issues related to accuracy, reliability, and the effort required to verify results.

4. **AI trust distributions vary across developer roles, but many differences are moderate.**

   Some roles have comparatively higher or lower shares of particular trust levels, while the overall distributions remain broadly similar across many role groups.

5. **Respondent counts are important when interpreting percentages.**

   Percentage differences for smaller roles and less common trust groups are more sensitive to changes in a relatively small number of respondents.

These findings describe associations in the survey data and should not be interpreted as evidence that AI trust directly causes particular usage patterns or frustrations.

## 9. Limitations

* Survey results are self-reported.
* The survey sample may not represent the entire global developer population.
* Not all respondents answered every relevant question.
* Some developer roles and trust groups contain relatively small numbers of respondents.
* Because the AI-frustration question is multi-select, one respondent may appear in several frustration categories.
* AI-frustration shares are calculated among respondents who answered the frustration question rather than among every survey respondent.
* The analysis identifies associations rather than causal relationships.
* Percentages should be interpreted together with respondent counts and denominator definitions.
* Structured response categories may not capture every nuance of respondents' experiences.

## 10. Repository Structure

```text
stackoverflow-survey-2025-analysis/
├── README.md
├── dbt_project.yml
├── macros/
│   └── clean_na.sql
├── models/
│   ├── staging/
│   │   ├── sources.yml
│   │   ├── stg_survey_results.sql
│   │   └── stg_survey_results.yml
│   ├── intermediate/
│   └── marts/
├── tests/
│   ├── intermediate/
│   └── marts/
├── analyses/
├── data_exports/
└── dashboard/
```

### 10.1 Repository contents

* `models/staging/` — cleaned and standardized respondent-level survey model;
* `models/intermediate/` — long-format models for AI tasks and AI frustrations;
* `models/marts/` — final analytical datasets used in Tableau;
* `macros/` — reusable dbt macros used to clean source values;
* `tests/` — singular dbt tests for grain, uniqueness, accepted values, counts, shares, classifications, and ranks;
* `analyses/` — audit queries used to inspect transformed data and investigate unexpected results;
* `data_exports/` — CSV exports of the final mart models;
* `dashboard/` — Tableau workbook and exported dashboard files;
* `README.md` — project objective, dataset description, architecture, methodology, validation, findings, and limitations.

## 11. How to Run

1. Load the Stack Overflow Developer Survey 2025 responses into Snowflake.
2. Configure the dbt connection to the relevant Snowflake database and schema.

3. Build the models and execute all configured schema and singular tests:

```bash
dbt build
```

4. Run the audit queries from the `analyses/` folder where additional manual validation is required.
5. Export the final mart tables to CSV.
6. Open or refresh the Tableau workbook using the exported mart datasets.

Connection credentials, local profiles, temporary dbt output, and source survey files are not stored in the repository.
