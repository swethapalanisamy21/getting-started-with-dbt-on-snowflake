{% macro render_models_yaml_block(grouped_data) %}
version: 2
models:
{%- for schema_name, tables in grouped_data.items() %}
  {%- for table_name, table_data in tables.items() %}
  - name: {{ table_name }}
    {%- if table_data.table_tests %}
    tests:
      {%- for test in table_data.table_tests %}
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
    {%- endif %}
    {%- if table_data.columns %}
    columns:
      {%- for col, tests in table_data.columns.items() %}
      - name: {{ col }}
        tests:
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
    {%- endif %}
  {%- endfor %}
{%- endfor %}
{% endmacro %}