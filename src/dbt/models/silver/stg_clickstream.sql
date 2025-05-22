{{ config(
    materialized='incremental',
    incremental_strategy='append'
) }}

WITH max_ts AS (
    {% if is_incremental() %}
    SELECT COALESCE(MAX(timestamp), TIMESTAMP '1970-01-01 00:00:00') AS max_timestamp
    FROM {{ this }}
    {% else %}
    SELECT TIMESTAMP '1970-01-01 00:00:00' AS max_timestamp
    {% endif %}
),
source AS (
    SELECT * FROM {{ source('lakehouse', 'raw_clickstream') }}
    WHERE ts > (SELECT max_timestamp FROM max_ts) -- Chỉ lấy dữ liệu mới, sử dụng giá trị mặc định nếu không có dữ liệu
)
SELECT
    event_id, 
    ts AS timestamp,
    department,
    category,
    product,
    add_to_cart,
    country
    
FROM source
WHERE country IS NOT NULL
