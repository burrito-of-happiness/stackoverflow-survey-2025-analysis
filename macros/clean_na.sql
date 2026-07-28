{% macro clean_na(column_name) %}

    NULLIF(
        NULLIF(TRIM({{ column_name }}), ''),
        'NA'
    )

{% endmacro %}