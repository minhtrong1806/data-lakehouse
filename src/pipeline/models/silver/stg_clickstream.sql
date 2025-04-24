{{ config(
    materialized='incremental',
    incremental_strategy='append'
) }}

WITH source AS (
    SELECT * FROM {{ source('lakehouse', 'raw_clickstream') }}
    {% if is_incremental() %}
    WHERE ts > (SELECT MAX(ts) FROM {{ this }}) -- Chỉ lấy dữ liệu mới
    {% endif %}
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
