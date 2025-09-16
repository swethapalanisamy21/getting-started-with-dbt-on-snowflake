{% macro concat_keys(keys) %}
    CONCAT(
    {%- for key in keys %}
        {{ key }}{{ ", '-'," if not loop.last else "" }}
    {%- endfor %}
    )
{% endmacro %}

{% test source_to_target_range(model, source_table, source_key_list, source_timestamp, auditlog_table, target_key) %}

WITH last_run AS (
    SELECT 
           startdate AS start_date,
           enddate   AS end_date
    FROM {{ auditlog_table }}
    WHERE TableName = '{{ model.name }}'
      AND Status = 'Completed'
    ORDER BY LoadEndTime DESC
    LIMIT 1
),

source_data AS (
    SELECT 
        {{ concat_keys(source_key_list) }} AS key
    FROM {{ source_table }}
    WHERE {{ source_timestamp }} BETWEEN
          (SELECT start_date FROM last_run)
      AND (SELECT end_date FROM last_run)
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
