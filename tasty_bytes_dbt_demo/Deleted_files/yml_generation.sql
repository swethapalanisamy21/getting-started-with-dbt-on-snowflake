{% macro yml_generation() %}

  {% set config_query %}

    SELECT model_name, column_name, test_type, test_args

    FROM TASTY_BYTES_DBT_DB.TESTING.DBT_TESTS_CONFIG

  {% endset %}
 
  {% set results = run_query(config_query) %}
 
  {% if execute %}

    {% set yaml_lines = [] %}
 
    {% for row in results.rows %}

      {% set model_name = row[0] %}

      {% set column_name = row[1] %}

      {% set test_type = row[2] %}

      {% set test_args = row[3] %}
 
      {% set test_config = {} %}

      {% do test_config.update({test_type: test_args | as_native if test_args else {}}) %}
 
      {% set test_entry = {

        "name": model_name,

        "columns": [

          {

            "name": column_name,

            "tests": [test_config]

          }

        ]

      } %}
 
      {% do yaml_lines.append(test_entry) %}

    {% endfor %}
 
    {{ return(yaml_lines) }}

  {% endif %}
 
  {{ return([]) }}

{% endmacro %}
