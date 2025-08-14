{% macro debug_yml_generation() %}

  {% set tests = yml_generation() %}
 
  {% if execute %}

    {{ log(".updateDynamic_tests() output:", info=True) }}

    {% for model in tests %}

      {{ log("Model: " ~ model["name"], info=True) }}

      {% for column in model["columns"] %}

        {{ log("  Column: " ~ column["name"], info=True) }}

        {% for test in column["tests"] %}

          {{ log("    Test: " ~ test | tojson, info=True) }}

        {% endfor %}

      {% endfor %}

    {% endfor %}
 
    {{ log("", info=True) }}

    {{ log("Full structure (as compact JSON):", info=True) }}

    {{ log(tests | tojson, info=True) }}  {# ← Removed 'indent' #}

  {% endif %}

{% endmacro %}
 