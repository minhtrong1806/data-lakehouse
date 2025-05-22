{% macro run_audit(source_table, target_table) %}
    INSERT INTO {{ ref('dim_audit') }}
    SELECT * FROM {{ ref('dim_audit') }} 
    WHERE source_table = '{{ source_table }}' AND target_table = '{{ target_table }}'
{% endmacro %}