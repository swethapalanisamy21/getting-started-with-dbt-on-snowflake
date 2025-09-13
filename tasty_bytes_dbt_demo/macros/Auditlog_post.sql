{% macro auditlog_post(model_name,raw_table,date_column) %}

-- 🟢 auditlog_post started for model: {{ model_name,raw_table,date_column }}

-- Get the most recent LoadStartTime of current run from AuditLog
{% set load_start_query %}
    SELECT LoadStartTime
    FROM lcf.AuditLog
    WHERE TableName = '{{ model_name }}'
      AND Status = 'In Progress'
    ORDER BY LoadStartTime DESC
    LIMIT 1
{% endset %}

{% set load_start_result = run_query(load_start_query) %}

{% if load_start_result and load_start_result.columns|length > 0 and load_start_result.columns[0].values()[0] is not none %}
    {% set load_start_time = load_start_result.columns[0].values()[0] %}
{% else %}
    {% set load_start_time = '1900-01-01 00:00:00.000' %}
{% endif %}

-- Get HighWatermark start and end timestamps for this model
{% set hwm_query %}
    SELECT start_date, end_date
    FROM lcf.HighWaterMark
    WHERE Table_Name = '{{ model_name }}'
{% endset %}

{% set hwm_result = run_query(hwm_query) %}

{% if hwm_result and hwm_result.columns|length >= 2 %}
    {% set hwm_start = hwm_result.columns[0].values()[0] %}
    {% set hwm_end   = hwm_result.columns[1].values()[0] %}
{% else %}
    {% set hwm_start = '1900-01-01 00:00:00.000' %}
    {% set hwm_end   = '9999-12-31 23:59:59.999' %}
{% endif %}

-- Count total records from model within HighWatermark date range
{% set total_count_query %}
    SELECT COUNT(*) AS cnt
    FROM {{ source('tb_101', raw_table) }}
    WHERE {{ date_column }} BETWEEN TO_TIMESTAMP_NTZ('{{ hwm_start }}')
                         AND TO_TIMESTAMP_NTZ('{{ hwm_end }}')
{% endset %}

-- Count inserted records (ActionType = 'I') since this run started
{% set inserted_count_query %}
    SELECT COUNT(*) AS cnt
    FROM {{ this }}
    WHERE ActionType = 'I' 
      AND InsertDate >= TO_TIMESTAMP_NTZ('{{ load_start_time }}')
{% endset %}

-- Count updated records (ActionType = 'U') since this run started
{% set updated_count_query %}
    SELECT COUNT(*) AS cnt
    FROM {{ this }}
    WHERE ActionType = 'U' 
      AND ActionDate >= TO_TIMESTAMP_NTZ('{{ load_start_time }}')
{% endset %}

-- Run the queries
{% set total_result    = run_query(total_count_query) %}
{% set inserted_result = run_query(inserted_count_query) %}
{% set updated_result  = run_query(updated_count_query) %}

-- Safely extract counts
{% set total_count    = total_result.columns[0].values()[0] | int if total_result and total_result.columns|length > 0 else 0 %}
{% set inserted_count = inserted_result.columns[0].values()[0] | int if inserted_result and inserted_result.columns|length > 0 else 0 %}
{% set updated_count  = updated_result.columns[0].values()[0] | int if updated_result and updated_result.columns|length > 0 else 0 %}

-- 🟢 Counts for {{ model_name }}: Total={{ total_count }}, Inserted={{ inserted_count }}, Updated={{ updated_count }}

-- Update AuditLog safely
UPDATE lcf.AuditLog
SET
    LoadEndTime     = CONVERT_TIMEZONE('Asia/Kolkata', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ,
    TotalRecords    = {{ total_count }},
    RecordsInserted = {{ inserted_count }},
    RecordsUpdated  = {{ updated_count }},
    RecordsDeleted  = 0,
    Status          = 'Completed',
    Error           = NULL
WHERE TableName = '{{ model_name }}'
  AND Status = 'In Progress'
  AND LoadStartTime = (
      SELECT MAX(LoadStartTime)
      FROM lcf.AuditLog
      WHERE TableName = '{{ model_name }}'
        AND Status = 'In Progress'
  );

-- 🟢 auditlog_post completed for model: {{ model_name }}

{% endmacro %}
