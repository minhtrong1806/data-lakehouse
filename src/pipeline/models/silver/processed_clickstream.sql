{{ config(
    incremental_strategy='append'
) }}

WITH source AS (
    SELECT * FROM {{ source('lakehouse', 'raw_clickstream') }}
    {% if is_incremental() %}
    WHERE ts > (SELECT MAX(ts) FROM {{ this }}) -- Chỉ lấy dữ liệu mới
    {% endif %}
),

extracted_data AS (
    SELECT 
        event_id,  
        ts,
        ip,
        url,
        regexp_extract(url, '^/department/([^/]+)/category/([^/]+)/product/(.*)', 1) AS department,
        regexp_extract(url, '^/department/([^/]+)/category/([^/]+)/product/(.*)', 2) AS category,
        regexp_extract(url, '^/department/([^/]+)/category/([^/]+)/product/(.*)', 3) AS product
    FROM source
)

SELECT
    event_id, 
    ts,
    ip, 
    regexp_replace(department, '%20', ' ') AS department,
    regexp_replace(category, '%20', ' ') AS category,
    regexp_replace(product, '%20', ' ') AS product
FROM extracted_data
WHERE regexp_replace(product, '%20', ' ') IS NOT NULL
