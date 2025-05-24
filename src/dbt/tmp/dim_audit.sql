{{ config(materialized='incremental', unique_key='audit_sk') }}

{% if is_incremental() %}
    WITH source_counts AS (
        {% if target_table == 'customer_rfm' %}
            SELECT 
                COUNT(*) AS records_processed,
                COUNT(*) FILTER (WHERE expiration_date IS NULL) AS records_inserted,
                COUNT(*) FILTER (WHERE expiration_date IS NOT NULL) AS records_updated
            FROM {{ ref('customer_rfm') }}
            WHERE effective_date >= CURRENT_DATE
        {% elif target_table == 'dim_customer' %}
            SELECT 
                COUNT(*) AS records_processed,
                COUNT(*) FILTER (WHERE expiration_date IS NULL) AS records_inserted,
                COUNT(*) FILTER (WHERE expiration_date IS NOT NULL) AS records_updated
            FROM {{ ref('dim_customer') }}
            WHERE effective_date >= CURRENT_DATE
        {% elif target_table == 'dim_product' %}
            SELECT 
                COUNT(*) AS records_processed,
                COUNT(*) FILTER (WHERE expiration_date IS NULL) AS records_inserted,
                COUNT(*) FILTER (WHERE expiration_date IS NOT NULL) AS records_updated
            FROM {{ ref('dim_product') }}
            WHERE effective_date >= CURRENT_DATE
        {% elif target_table == 'dim_store' %}
            SELECT 
                COUNT(*) AS records_processed,
                COUNT(*) FILTER (WHERE expiration_date IS NULL) AS records_inserted,
                COUNT(*) FILTER (WHERE expiration_date IS NOT NULL) AS records_updated
            FROM {{ ref('dim_store') }}
            WHERE effective_date >= CURRENT_DATE
        {% else %}
            SELECT 0 AS records_processed, 0 AS records_inserted, 0 AS records_updated
        {% endif %}
    ),
    audit_data AS (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY CURRENT_TIMESTAMP(6)) 
            + COALESCE((SELECT MAX(audit_sk) FROM {{ this }}), 0) AS audit_sk,
            CONCAT(
                'AUDIT_', 
                DATE_FORMAT(CURRENT_DATE, '%Y%m%d'), 
                '_', 
                CAST(ROW_NUMBER() OVER (ORDER BY CURRENT_TIMESTAMP(6)) AS VARCHAR)
            ) AS audit_id,
            '{{ source_table }}' AS source_table,
            '{{ target_table }}' AS target_table,
            CURRENT_TIMESTAMP(6) AS run_timestamp,
            sc.records_processed,
            sc.records_inserted,
            sc.records_updated
        FROM source_counts sc
        WHERE sc.records_processed > 0
    )
    SELECT * FROM audit_data
{% else %}
    -- Khởi tạo bảng rỗng lần đầu tiên
    SELECT 
        CAST(1 AS BIGINT) AS audit_sk,
        'AUDIT_INITIAL' AS audit_id,
        '{{ source_table | default('unknown') }}' AS source_table,
        '{{ target_table | default('unknown') }}' AS target_table,
        CURRENT_TIMESTAMP(6) AS run_timestamp,
        0 AS records_processed,
        0 AS records_inserted,
        0 AS records_updated
    WHERE FALSE  -- Không thêm bản ghi nào, chỉ tạo bảng
{% endif %}
