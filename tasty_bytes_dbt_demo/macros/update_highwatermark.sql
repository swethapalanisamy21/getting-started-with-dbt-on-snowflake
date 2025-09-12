{% macro update_highwatermark(hw_table, stg_table, raw_table, date_column) %}

-- Calculate new_start_date as max date from raw_table
{% set new_start_date_query %}
    SELECT MAX({{ date_column }}) 
    FROM tasty_bytes_dbt_db.raw.country
{% endset %}

{% set new_start_date = "(" ~ new_start_date_query | trim ~ ")" %}

merge into {{ hw_table }} as h
using (
    select 
        '{{ stg_table }}' as table_name,
        {{ new_start_date }} as start_date
) as s
on h.table_name = s.table_name

when matched then update set
    start_date = s.start_date,
    end_date   = TO_TIMESTAMP_NTZ('9999-12-31');

{% endmacro %}
