{% macro run_column_tests(model, test_cases) %}

  {% for test_case in test_cases %}

    {% set test = test_case.test %}

    {% set column = test_case.column %}

    {% if test == 'not_null' %}

        {{ log("Running test: not_null on " ~ model ~ "." ~ column, info=True) }}

        {{ test_not_null(model=model, column_name=column) }}

    {% elif test == 'unique' %}

        {{ log("Running test: unique on " ~ model ~ "." ~ column, info=True) }}

        {{ test_unique(model=model, column_name=column) }}

    {% elif test == 'accepted_values' %}

        {{ log("Running test: accepted_values on " ~ model ~ "." ~ column, info=True) }}

        {{ test_accepted_values(model=model, column_name=column, values=test_case.values) }}

    {% else %}

        {{ log("Unknown test: " ~ test, info=True) }}

    {% endif %}

  {% endfor %}

{% endmacro %}

 