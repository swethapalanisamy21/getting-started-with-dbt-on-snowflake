{% macro render_sources_yaml_block(sources_data) %}
version: 2
sources:
{%- for source_schema, tables in sources_data.items() %}
  - name: {{ source_schema | lower | replace('_', '') }}
    description: ''
    database: tasty_bytes_dbt_db
    schema: {{ source_schema }}
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
        {%- if table_data.columns %}
        columns:
          {%- for col, tests in table_data.columns.items() %}
          - name: {{ col }}
            description: ''
            {%- if tests %}
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
            {%- endif %}
          {%- endfor %}
        {%- endif %}
      {%- endfor %}
{%- endfor %}
{% endmacro %}