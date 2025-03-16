{{ config(
    incremental_strategy='insert_overwrite',
    on_table_exists='replace'
) }}

{% if is_incremental() %}
    WITH audit_data AS (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY CURRENT_TIMESTAMP) + (SELECT COALESCE(MAX(audit_sk), 0) FROM {{ this }}) AS audit_sk,
            CONCAT('AUDIT_', DATE_FORMAT(CURRENT_DATE, '%Y%m%d'), '_', ROW_NUMBER() OVER (ORDER BY CURRENT_TIMESTAMP)) AS audit_id,
            '{{ source_table }}' AS source_table,
            '{{ target_table }}' AS target_table,
            CURRENT_TIMESTAMP AS run_timestamp,
            (SELECT COUNT(*) FROM {{ ref(target_table) }} WHERE effective_date >= CURRENT_DATE) AS records_processed,
            (SELECT COUNT(*) FROM {{ ref(target_table) }} WHERE effective_date >= CURRENT_DATE AND expiration_date IS NULL) AS records_inserted,
            (SELECT COUNT(*) FROM {{ ref(target_table) }} WHERE effective_date >= CURRENT_DATE AND expiration_date IS NOT NULL) AS records_updated
        FROM {{ ref(target_table) }}
        WHERE effective_date >= CURRENT_DATE
        LIMIT 1
    )
    SELECT * FROM audit_data WHERE records_processed > 0
{% else %}
    SELECT 
        ROW_NUMBER() OVER (ORDER BY CURRENT_TIMESTAMP) AS audit_sk,
        CONCAT('AUDIT_', DATE_FORMAT(CURRENT_DATE, '%Y%m%d'), '_', ROW_NUMBER() OVER (ORDER BY CURRENT_TIMESTAMP)) AS audit_id,
        '{{ source_table }}' AS source_table,
        '{{ target_table }}' AS target_table,
        CURRENT_TIMESTAMP AS run_timestamp,
        COUNT(*) AS records_processed,
        COUNT(*) AS records_inserted,
        0 AS records_updated
    FROM {{ ref(target_table) }}
{% endif %}