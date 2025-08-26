{% macro generate_testing_yaml() %}
{% set source_name = 'TASTY_BYTES_DBT_DB_source' %}

{% set metadata_query %}
    SELECT schema_name, table_name, column_name, test_type, test_config
    FROM TASTY_BYTES_DBT_DB.TESTING.TEST_METADATA_TABLE
    ORDER BY schema_name, table_name, column_name
{% endset %}

{% set metadata = run_query(metadata_query) %}
{% if not metadata %}
  {{ log("No metadata found.", info=True) }}
  {{ return("No metadata found.") }}
{% endif %}

{% set metadata = metadata.rows %}
{% set grouped = {} %}

{# Step 1: Group data properly by schema > table > column #}
{% for row in metadata %}
  {% set schema = row[0] %}
  {% set table = row[1] %}
  {% set column = row[2] %}
  {% set test = row[3] %}
  {% set config = row[4] %}

  {% set schema_entry = grouped.get(schema, {}) %}
  {% set table_entry = schema_entry.get(table, {}) %}
  {% set column_tests = table_entry.get(column, []) %}

  {% if config %}
    {% do column_tests.append({test: fromjson(config)}) %}
  {% else %}
    {% do column_tests.append(test) %}
  {% endif %}

  {% do table_entry.update({(column): column_tests}) %}
  {% do schema_entry.update({(table): table_entry}) %}
  {% do grouped.update({(schema): schema_entry}) %}
{% endfor %}

{# Step 2: Build YAML output #}
{% set yaml_output %}
version: 2
sources:
- name: {{ source_name }}
  description: 'Auto-generated tests'
{%- for schema_name, tables in grouped.items() %}
  schema: {{ schema_name }}
  tables:
  {%- for table_name, columns in tables.items() %}
  - name: {{ table_name }}
    columns:
    {%- for column_name, tests in columns.items() %}
    - name: {{ column_name }}
      data_tests:
      {%- for test in tests %}
        {%- if test is mapping %}
        {%- for k, v in test.items() %}
        - {{ k }}: 
        {%- if v is mapping %}
        {%- for vk, vv in v.items() %}
            {{ vk }}: {{ vv }}
        {%- endfor %}
        {%- endif %}
        {%- endfor %}
        {%- else %}
        - {{ test }}
        {%- endif %}
      {%- endfor %}
    {%- endfor %}
  {%- endfor %}
{%- endfor %}
{% endset %}

{{ log(yaml_output, info=True) }}
{{ return(yaml_output) }}
{% endmacro %}
