{% macro update_highwatermark(hw_table, stg_table, raw_table, date_column) %}
-- This macro updates the high watermark table for a given staging table.

merge into {{ hw_table }} as h
using (
    select 
        '{{ stg_table }}' as table_name,
        max({{ date_column }}) as start_date
    from {{ source('tb_101', raw_table) }}
) as s
on h.table_name = s.table_name

when matched then update set
    start_date = s.start_date,
    end_date   = to_timestamp_ntz('9999-12-31')

when not matched then insert (table_name, start_date, end_date)
values (s.table_name, s.start_date, to_timestamp_ntz('9999-12-31'));

{% endmacro %}
