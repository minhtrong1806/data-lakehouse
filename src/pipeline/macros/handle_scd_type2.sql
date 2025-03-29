{% macro handle_scd_type2(source_table, target_table, natural_key, attributes, surrogate_key_name) %}
    {% if is_incremental() %}
        WITH source_data AS (
            SELECT 
                {{ natural_key }},
                {{ attributes | join(', ') }},
                CAST('2015-01-01 00:00:00.000' AS timestamp(6)) AS effective_date,
                CAST(NULL AS timestamp(6) with time zone) AS expiration_date,
                1 AS is_current
            FROM {{ source_table }}
        ),
        current_records AS (
            SELECT
                {{ surrogate_key_name }},
                {{ natural_key }},
                {{ attributes | join(', ') }},
                effective_date,
                expiration_date,
                is_current
            FROM {{ target_table }}
            WHERE is_current = 1
        ),
        change_detection AS (
            SELECT
                s.{{ natural_key }},
                c.{{ surrogate_key_name }},
                CASE 
                    WHEN c.{{ natural_key }} IS NULL THEN TRUE  -- Nếu không tìm thấy natural_key, tức là bản ghi mới
                    WHEN (
                        {% for attribute in attributes %}
                            s.{{ attribute }} IS DISTINCT FROM c.{{ attribute }}{% if not loop.last %} OR {% endif %}
                        {% endfor %}
                    ) THEN TRUE  -- Nếu có bất kỳ sự thay đổi nào
                    ELSE FALSE
                END AS has_changed
            FROM source_data s
            LEFT JOIN current_records c ON s.{{ natural_key }} = c.{{ natural_key }}
        ),
        records_to_close AS (
            SELECT
                c.{{ surrogate_key_name }},
                c.{{ natural_key }},
                {{ attributes | join(', ') }},
                c.effective_date,
                CURRENT_TIMESTAMP(6) - INTERVAL '1' SECOND AS expiration_date,
                0 AS is_current
            FROM current_records c
            JOIN change_detection cd ON c.{{ natural_key }} = cd.{{ natural_key }}
            WHERE cd.has_changed = TRUE
        ),
        new_records AS (
            SELECT
                ROW_NUMBER() OVER (ORDER BY s.{{ natural_key }})
                    + COALESCE((SELECT MAX(c.{{ surrogate_key_name }}) FROM current_records AS c), 0)
                    AS {{ surrogate_key_name }},
                s.{{ natural_key }},
                {{ attributes | join(', ') }},
                CURRENT_TIMESTAMP(6) AS effective_date,
                CAST(NULL AS timestamp(6) with time zone) AS expiration_date,
                1 AS is_current
            FROM source_data s
            JOIN change_detection cd ON s.{{ natural_key }} = cd.{{ natural_key }}
            WHERE cd.has_changed = TRUE
        )
        SELECT * FROM records_to_close
        UNION ALL
        SELECT * FROM new_records
    {% else %}
        SELECT 
            ROW_NUMBER() OVER (ORDER BY {{ natural_key }}) AS {{ surrogate_key_name }},
            {{ natural_key }},
            {{ attributes | join(', ') }},
            CAST('2015-01-01 00:00:00.000' AS timestamp(6)) AS effective_date,
            CAST(NULL AS timestamp(6) with time zone) AS expiration_date,
            1 AS is_current
        FROM {{ source_table }}
    {% endif %}
{% endmacro %}
