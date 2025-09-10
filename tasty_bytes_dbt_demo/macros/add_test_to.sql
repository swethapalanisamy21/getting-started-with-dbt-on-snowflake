{% macro add_test_to(data, group_key, table, column, test_type, test_config) %}
  {% set table_entry = data.get(group_key, {}).get(table, {'columns': {}, 'table_tests': []}) %}

  {% if column %}
    {% set column_tests = table_entry['columns'].get(column, []) %}
    {% if test_config %}
      {% do column_tests.append({ test_type: fromjson(test_config) }) %}
    {% else %}
      {% do column_tests.append(test_type) %}
    {% endif %}
    {% do table_entry['columns'].update({ column: column_tests }) %}
  {% else %}
    {% if test_config %}
      {% do table_entry['table_tests'].append({ test_type: fromjson(test_config) }) %}
    {% else %}
      {% do table_entry['table_tests'].append(test_type) %}
    {% endif %}
  {% endif %}

  {% set updated_group = data.get(group_key, {}) %}
  {% do updated_group.update({ table: table_entry }) %}
  {% do data.update({ group_key: updated_group }) %}
{% endmacro %}
