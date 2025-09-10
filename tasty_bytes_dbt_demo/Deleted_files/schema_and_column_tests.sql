{% macro generate__testing_yaml() %}
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

{# Step 1: Group data by schema > table > column, handling table-level tests when column_name is null #}
{% for row in metadata %}
  {% set schema = row[0] %}
  {% set table = row[1] %}
  {% set column = row[2] %}
  {% set test = row[3] %}
  {% set config = row[4] %}

  {% set schema_entry = grouped.get(schema, {}) %}
  {% set table_entry = schema_entry.get(table, {'columns': {}, 'table_tests': []}) %}

  {% if column %}
    {% set column_tests = table_entry['columns'].get(column, []) %}
    {% if config %}
      {% do column_tests.append({test: fromjson(config)}) %}
    {% else %}
      {% do column_tests.append(test) %}
    {% endif %}
    {% do table_entry['columns'].update({(column): column_tests}) %}
  {% else %}
    {# Table-level test #}
    {% if config %}
      {% do table_entry['table_tests'].append({test: fromjson(config)}) %}
    {% else %}
      {% do table_entry['table_tests'].append(test) %}
    {% endif %}
  {% endif %}

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
  {%- for table_name, table_data in tables.items() %}
  - name: {{ table_name }}
    {%- if table_data.table_tests %}
    tests:
    {%- for test in table_data.table_tests %}
      {%- if test is mapping %}
        {%- for k, v in test.items() %}
        - {{ k }}:
          {%- for vk, vv in v.items() %}
            {{ vk }}: {{ vv }}
          {%- endfor %}
        {%- endfor %}
      {%- else %}
      - {{ test }}
      {%- endif %}
    {%- endfor %}
    {%- endif %}
    columns:
    {%- for column_name, tests in table_data.columns.items() %}
    - name: {{ column_name }}
      data_tests:
      {%- for test in tests %}
        {%- if test is mapping %}
          {%- for k, v in test.items() %}
        - {{ k }}:
            {%- for vk, vv in v.items() %}
              {{ vk }}: {{ vv }}
            {%- endfor %}
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
