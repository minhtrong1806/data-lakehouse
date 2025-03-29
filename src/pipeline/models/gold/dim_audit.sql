{{ config(materialized='incremental', unique_key='audit_sk') }}

{% if is_incremental() %}
    WITH audit_data AS (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY CURRENT_TIMESTAMP) + (SELECT COALESCE(MAX(audit_sk), 0) FROM {{ this }}) AS audit_sk,
            CONCAT('AUDIT_', DATE_FORMAT(CURRENT_DATE, '%Y%m%d'), '_', ROW_NUMBER() OVER (ORDER BY CURRENT_TIMESTAMP)) AS audit_id,
            '{{ source_table }}' AS source_table,
            '{{ target_table }}' AS target_table,
            CURRENT_TIMESTAMP AS run_timestamp,
            {% if target_table == 'customer_rfm' %}
                (SELECT COUNT(*) FROM {{ ref('customer_rfm') }} WHERE effective_date >= CURRENT_DATE) AS records_processed,
                (SELECT COUNT(*) FROM {{ ref('customer_rfm') }} WHERE effective_date >= CURRENT_DATE AND expiration_date IS NULL) AS records_inserted,
                (SELECT COUNT(*) FROM {{ ref('customer_rfm') }} WHERE effective_date >= CURRENT_DATE AND expiration_date IS NOT NULL) AS records_updated
            {% elif target_table == 'dim_customer' %}
                (SELECT COUNT(*) FROM {{ ref('dim_customer') }} WHERE effective_date >= CURRENT_DATE) AS records_processed,
                (SELECT COUNT(*) FROM {{ ref('dim_customer') }} WHERE effective_date >= CURRENT_DATE AND expiration_date IS NULL) AS records_inserted,
                (SELECT COUNT(*) FROM {{ ref('dim_customer') }} WHERE effective_date >= CURRENT_DATE AND expiration_date IS NOT NULL) AS records_updated
            {% elif target_table == 'dim_product' %}
                (SELECT COUNT(*) FROM {{ ref('dim_product') }} WHERE effective_date >= CURRENT_DATE) AS records_processed,
                (SELECT COUNT(*) FROM {{ ref('dim_product') }} WHERE effective_date >= CURRENT_DATE AND expiration_date IS NULL) AS records_inserted,
                (SELECT COUNT(*) FROM {{ ref('dim_product') }} WHERE effective_date >= CURRENT_DATE AND expiration_date IS NOT NULL) AS records_updated
            {% elif target_table == 'dim_store' %}
                (SELECT COUNT(*) FROM {{ ref('dim_store') }} WHERE effective_date >= CURRENT_DATE) AS records_processed,
                (SELECT COUNT(*) FROM {{ ref('dim_store') }} WHERE effective_date >= CURRENT_DATE AND expiration_date IS NULL) AS records_inserted,
                (SELECT COUNT(*) FROM {{ ref('dim_store') }} WHERE effective_date >= CURRENT_DATE AND expiration_date IS NOT NULL) AS records_updated
            {% endif %}
        FROM (SELECT 1 AS dummy)  -- Thêm nguồn dữ liệu giả để truy vấn hợp lệ
        LIMIT 1
    )
    SELECT * FROM audit_data WHERE records_processed > 0
{% else %}
    -- Khởi tạo bảng rỗng lần đầu tiên
    SELECT 
        CAST(1 AS BIGINT) AS audit_sk,
        'AUDIT_INITIAL' AS audit_id,
        '{{ source_table | default('unknown') }}' AS source_table,
        '{{ target_table | default('unknown') }}' AS target_table,
        CURRENT_TIMESTAMP AS run_timestamp,
        0 AS records_processed,
        0 AS records_inserted,
        0 AS records_updated
    WHERE FALSE  -- Không thêm bản ghi nào, chỉ tạo bảng
{% endif %}