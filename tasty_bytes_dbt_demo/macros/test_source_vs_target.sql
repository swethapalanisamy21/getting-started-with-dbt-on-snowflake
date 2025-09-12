-- macros/test_source_vs_target.sql
{% test source_vs_target(model, source_name, source_table, source_key, target_key) %}

WITH source_data AS (
    SELECT {{ source_key }} AS key
    FROM {{ source(source_name, source_table) }}
),

target_data AS (
    SELECT {{ target_key }} AS key
    FROM {{ model }}
)

SELECT s.key
FROM source_data s
LEFT JOIN target_data t
    ON s.key = t.key
WHERE t.key IS NULL

{% endtest %}
