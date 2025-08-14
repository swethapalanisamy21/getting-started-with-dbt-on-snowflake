	{% macro run_dynamic_tests() %}
   {% set results = [] %}
   {% set test_configs %}
     SELECT model_name, column_name, test_type, test_args

     FROM TASTY_BYTES_DBT_DB.TESTING.DBT_TESTS_CONFIG
   {% endset %}
   {% set rows = run_query(test_configs).rows %}
   {{ log("Number of tests to run: " ~ rows | length, info=True) }}
   {% for row in rows %}
     {% set model = row[0] %}
     {% set column = row[1] %}
     {% set test = row[2] %}
     {% set args = row[3] %}
     {{ log("Running test: " ~ test ~ " on " ~ model ~ "." ~ column, info=True) }}
     {% if test == 'not_null' %}
       {{ test_not_null(model=model, column_name=column) }}
       {{ log('not_null success on ' ~ column, info=True) }}
     {% elif test == 'unique' %}
       {{ test_unique(model=model, column_name=column) }}
       {{ log('unique success on ' ~ column, info=True) }}
 
     {% elif test == 'accepted_values' %}
       {{ test_accepted_values(model=model, column_name=column, values=args) }}
       {{ log('accepted_values success on ' ~ column, info=True) }}
     {% else %}
       {{ log("Unsupported test type: " ~ test, info=True) }}
     {% endif %}
   {% endfor %}
{% endmacro %}