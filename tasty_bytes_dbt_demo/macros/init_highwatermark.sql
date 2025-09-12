{% macro init_highwatermark(table_name) %}

{% set hw_table = 'tasty_bytes_dbt_db.lcf.highwatermark' %}

-- Step 1: Create high watermark table if it doesn't exist
create table if not exists {{ hw_table }} (
    table_name string,
    start_date timestamp_ntz,
    end_date timestamp_ntz
);

-- Step 2: Insert default record if not already present
merge into {{ hw_table }} as h
using (
    select '{{ table_name }}' as table_name,
           TO_TIMESTAMP_NTZ('1900-01-01 00:00:00') as start_date,
           TO_TIMESTAMP_NTZ('9999-12-31 00:00:00') as end_date
) as s
on h.table_name = s.table_name
when not matched then insert (table_name, start_date, end_date)
values (s.table_name, s.start_date, s.end_date);

{% endmacro %}
