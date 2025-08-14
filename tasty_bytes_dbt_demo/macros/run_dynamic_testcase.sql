{% macro dynamic_tests() %}
  {% set query %}
    SELECT model_name, column_name, test_type, test_args
    FROM TASTY_BYTES_DBT_DB.TESTING.DBT_TESTS_CONFIG
    ORDER BY model_name, column_name
  {% endset %}
 
  {% set results = run_query(query) %}
 
  {% if execute %}
    {% set failures = [] %}
    {{ log("🚀 Starting dynamic tests...", info=True) }}
 
    {% for row in results.rows %}
      {% set model_name = row[0] %}
      {% set column_name = row[1] %}
      {% set test_type = row[2] %}
      {% set test_args = row[3] %}
 
      {% set quoted_model =   model_name   %}
      {% set full_table = 'TASTY_BYTES_DBT_DB.DEV.' ~ quoted_model %}
 
      {% set test_sql %}
        {% if test_type == 'not_null' %}
          SELECT COUNT(*) AS fail_count
          FROM {{ full_table }}
          WHERE {{ column_name }} IS NULL
 
        {% elif test_type == 'unique' %}
          SELECT COUNT(*) - COUNT(DISTINCT {{ column_name }}) AS fail_count
          FROM {{ full_table }}
          WHERE {{ column_name }} IS NOT NULL
 
        {% elif test_type == 'accepted_values' and test_args %}
          {% set values_list = test_args.split(',') | map('trim') | list %}
          SELECT COUNT(*) AS fail_count
          FROM {{ full_table }}
          WHERE {{ column_name }} IS NOT NULL
            AND {{ column_name }} NOT IN ({{ values_list | map('repr') | join(', ') }})
 
        {% else %}
          {{ log("⚠️ Unsupported test: " ~ test_type ~ " on " ~ model_name ~ "." ~ column_name, info=True) }}
          {% continue %}
        {% endif %}
      {% endset %}
 
      {% set test_result = run_query(test_sql) %}
      {% set fail_count = test_result.columns[0].values()[0] %}
 
      {% if fail_count > 0 %}
        {% set failure_msg = "❌ FAIL " ~ test_type ~ " on " ~ model_name ~ "." ~ column_name ~ " → " ~ fail_count ~ " failures" %}
        {{ log(failure_msg, info=True) }}
        {% do failures.append(failure_msg) %}
      {% else %}
        {{ log("✅ PASS " ~ test_type ~ " on " ~ model_name ~ "." ~ column_name, info=True) }}
      {% endif %}
    {% endfor %}
 
    {{ log("", info=True) }}
    {% if failures %}
      {{ log("💥 " ~ failures | length ~ " test(s) failed!", info=True) }}
      {% for msg in failures %}
        {{ log(msg, info=True) }}
      {% endfor %}
      {{ exceptions.raise_compiler_error("🚨 Dynamic tests failed. See above for details.") }}
    {% else %}
      {{ log("🎉 All dynamic tests passed!", info=True) }}
    {% endif %}
  {% endif %}
{% endmacro %}