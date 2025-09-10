{% macro generate_test_yamls() %}
{# === Configuration === #}
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
{% set models_data = {} %}
{% set sources_data = {} %}

{# === Get list of all model names from dbt project === #}
{% set dbt_models = graph.nodes.values()
    | selectattr('resource_type', 'equalto', 'model')
    | map(attribute='alias') 
    | list %}

{# === Process metadata rows === #}
{% for row in metadata %}
  {% set schema = row[0] %}
  {% set table = row[1] %}
  {% set column = row[2] %}
  {% set test_type = row[3] %}
  {% set test_config = row[4] %}

 {% if table | lower in dbt_models | map('lower') %}
    {% do add_test_to(models_data, schema, table, column, test_type, test_config) %}
  {% else %}
    {% do add_test_to(sources_data, schema, table, column, test_type, test_config) %}
  {% endif %}
{% endfor %}

{# === Compose YAML output === #}
version: 2


{# Prepare source YAML output #}
{% set full_sources_yaml = render_sources_yaml_block(sources_data) %}

{# Log sources YAML #}
{{ log("=== SOURCES YAML ===", info=True) }}
{{ log(full_sources_yaml, info=True) }}

{# Prepare models YAML output #}
{% set models_yaml = render_models_yaml_block(models_data) %}

{# Log models YAML #}
{{ log("=== MODELS YAML ===", info=True) }}
{{ log(models_yaml, info=True) }}

{# Output combined YAML #}
{{ full_sources_yaml }}

{{ models_yaml }}

{% endmacro %}
