{% macro auditlog_pre(model_name) %}

-- Check if model is already running
{% set in_progress_query %}
    SELECT COUNT(*) AS cnt
    FROM lcf.AuditLog
    WHERE TableName = '{{ model_name }}' AND Status = 'In Progress'
{% endset %}

{% set result = run_query(in_progress_query) %}
{% if result and result.columns[0].values()[0] | int > 0 %}
    {% do exceptions.raise_compiler_error("Model '{{ model_name }}' is already in progress. Please stop it.") %}
{% endif %}

-- Get HighWaterMark values safely
{% set hwm_query %}
    SELECT start_date AS start_date,
           end_date AS end_date
    FROM lcf.HighWaterMark
    WHERE Table_Name = '{{ model_name }}'
{% endset %}

{% set hwm_result = run_query(hwm_query) %}
{% if hwm_result and hwm_result.columns|length >= 2 %}
    {% set start_date = hwm_result.columns[0].values()[0] %}
    {% set end_date   = hwm_result.columns[1].values()[0] %}
{% else %}
    {% set start_date = '1900-01-01' %}
    {% set end_date   = current_timestamp() %}
{% endif %}

CREATE SEQUENCE IF NOT EXISTS lcf.AuditLogSeq START = 1 INCREMENT = 1;

INSERT INTO lcf.AuditLog (
    AuditLogId,
    TableName,
    StartDate,
    EndDate,
    LoadStartTime,
    Status,
    LoadedBy
)
VALUES (
    lcf.AuditLogSeq.NEXTVAL,
    '{{ model_name }}',
    '{{ start_date }}',
    '{{ end_date }}',
    CONVERT_TIMEZONE('Asia/Kolkata', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ,
    'In Progress',
    CURRENT_USER()
)

{% endmacro %}
