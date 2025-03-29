{% macro handle_scd_type2(source_table, target_table, natural_key, attributes) %}
    {% if is_incremental() %}
        -- Lấy dữ liệu từ source
        WITH source_data AS (
            SELECT 
                {{ natural_key }} AS {{ natural_key }}, 
                {% for attribute in attributes %}{{ attribute }},{% endfor %}
                CURRENT_TIMESTAMP AS effective_date, 
                CAST(NULL AS TIMESTAMP) AS expiration_date, 
                1 AS is_current
            FROM {{ source_table }}
        ),
        -- So sánh với dữ liệu hiện tại để phát hiện thay đổi
        existing_data AS (
            SELECT 
                t.*, 
                s.{{ natural_key }} AS source_{{ natural_key }}
            FROM {{ this }} t
            LEFT JOIN source_data s 
                ON t.{{ natural_key }} = s.{{ natural_key }} 
                AND t.is_current = 1
        ),
        -- Đóng bản ghi cũ nếu có thay đổi
        close_old_records AS (
            SELECT 
                surrogate_key, 
                e.{{ natural_key }} AS {{ natural_key }}, 
                {% for attribute in attributes %}e.{{ attribute }},{% endfor %}
                e.effective_date AS effective_date,
                CASE 
                    WHEN source_{{ natural_key }} IS NOT NULL 
                         AND ({% for attribute in attributes %}e.{{ attribute }} != s.{{ attribute }}{% if not loop.last %} OR {% endif %}{% endfor %})
                    THEN CURRENT_TIMESTAMP - INTERVAL '1' SECOND
                    ELSE CAST(e.expiration_date AS TIMESTAMP)
                END AS expiration_date,
                CASE 
                    WHEN source_{{ natural_key }} IS NOT NULL 
                         AND ({% for attribute in attributes %}e.{{ attribute }} != s.{{ attribute }}{% if not loop.last %} OR {% endif %}{% endfor %})
                    THEN 0 
                    ELSE e.is_current  -- Thêm alias e.
                END AS is_current
            FROM existing_data e
            LEFT JOIN source_data s 
                ON e.{{ natural_key }} = s.{{ natural_key }}
        ),
        -- Thêm bản ghi mới nếu có thay đổi
        new_records AS (
            SELECT 
                ROW_NUMBER() OVER (ORDER BY s.{{ natural_key }}) + (SELECT COALESCE(MAX(surrogate_key), 0) FROM {{ this }}) AS surrogate_key,
                s.{{ natural_key }} AS {{ natural_key }}, 
                {% for attribute in attributes %}s.{{ attribute }},{% endfor %}
                s.effective_date AS effective_date,
                CAST(NULL AS TIMESTAMP) AS expiration_date, 
                1 AS is_current
            FROM source_data s
            LEFT JOIN close_old_records e 
                ON s.{{ natural_key }} = e.{{ natural_key }} 
                AND e.is_current = 1
            WHERE e.{{ natural_key }} IS NULL 
               OR ({% for attribute in attributes %}s.{{ attribute }} != e.{{ attribute }}{% if not loop.last %} OR {% endif %}{% endfor %})
        )
        -- Kết hợp bản ghi cũ đã cập nhật và bản ghi mới
        SELECT * FROM close_old_records
        UNION ALL
        SELECT * FROM new_records
    {% else %}
        -- Full load lần đầu tiên
        SELECT 
            ROW_NUMBER() OVER (ORDER BY {{ natural_key }}) AS surrogate_key,
            {{ natural_key }} AS {{ natural_key }}, 
            {{ attributes | join(', ') }}, 
            CURRENT_TIMESTAMP AS effective_date, 
            CAST(NULL AS TIMESTAMP) AS expiration_date, 
            1 AS is_current
        FROM {{ source_table }}
    {% endif %}
{% endmacro %}