{% macro write_to_table() %}
{% set results = run_query("SELECT schema_name, table_name, column_name, test_type, test_params FROM TASTY_BYTES_DBT_DB.TESTING.TEST_METADATA WHERE enabled = TRUE ORDER BY schema_name, table_name, column_name") %}
{% set rows = results.rows %}

{% set models = {} %}

{# Group data in a dictionary #}
{% for row in rows %}
  {% set schema = row[0] %}
  {% set table = row[1] %}
  {% set column = row[2] %}
  {% set test_type = row[3] %}
  {% set test_params = row[4] %}

  {% set model_key = schema ~ '.' ~ table %}
  {% if model_key not in models %}
    {% set _ = models.update({model_key: {'table': table, 'schema': schema, 'columns': {}}}) %}
  {% endif %}

  {% set model = models[model_key] %}
  {% if column not in model['columns'] %}
    {% set _ = model['columns'].update({column: []}) %}
  {% endif %}

  {% if test_params %}
    {% set _ = model['columns'][column].append({test_type: test_params}) %}
  {% else %}
    {% set _ = model['columns'][column].append(test_type) %}
  {% endif %}
{% endfor %}

{# Build YAML output #}
{% set yaml_output %}
version: 2
models:
{% for model_key, model in models.items() %}
  - name: {{ model.table }}
    description: "Tests for {{ model.schema }}.{{ model.table }}"
    columns:
    {% for column_name, tests in model.columns.items() %}
      - name: {{ column_name }}
        tests:
        {% for test in tests %}
          {% if test is mapping %}
          {% for k, v in test.items() %}
          - {{ k }}: {{ v }}
          {% endfor %}
          {% else %}
          - {{ test }}
          {% endif %}
        {% endfor %}
    {% endfor %}
{% endfor %}
{% endset %}

{# Optional logging #}
{{ log(yaml_output, info=True) }}

{# Escape single quotes for safe SQL insertion #}
{% set escaped_yaml = yaml_output.replace("'", "''") %}

{# Insert into Snowflake table #}
{% set insert_sql %}
INSERT INTO TASTY_BYTES_DBT_DB.TESTING.YAML_LOGS (generated_at, yaml_text)
VALUES (CURRENT_TIMESTAMP, '{{ escaped_yaml }}')
{% endset %}

{{ log("Inserting YAML output into YAML_LOGS table", info=True) }}
{% do run_query(insert_sql) %}

{{ return(yaml_output) }}
{% endmacro %}
