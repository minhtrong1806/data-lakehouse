{{ config(
    materialized='incremental',
    incremental_strategy='append'
) }}

WITH clickstream_data AS (
    SELECT * FROM {{ ref('stg_clickstream') }}
    {% if is_incremental() %}
    WHERE timestamp > (SELECT MAX(timestamp) FROM {{ this }}) -- Chỉ lấy dữ liệu mới
    {% endif %}
)
SELECT
    d.date_key,
    g.geography_key,
    c.category_key,
    p.product_key,
    COUNT(*) AS total_events,
    SUM(CASE WHEN add_to_cart = TRUE THEN 1 ELSE 0 END) AS total_add_to_cart
FROM clickstream_data cs
LEFT JOIN {{ ref('dim_date') }} d ON DATE(cs.timestamp) = d.date
LEFT JOIN {{ ref('dim_geography') }} g ON cs.country = g.country
LEFT JOIN {{ ref('dim_category') }} c ON cs.department = c.department AND cs.category = c.category
LEFT JOIN {{ ref('dim_product') }} p ON cs.product = p.product_name
GROUP BY 
    d.date_key,
    g.geography_key,
    c.category_key,
    p.product_key