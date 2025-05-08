{{ config(
    materialized='incremental',
    incremental_strategy='append'
) }}

WITH max_ts AS (
    {% if is_incremental() %}
    SELECT COALESCE(MAX(timestamp), TIMESTAMP '1970-01-01 00:00:00') AS max_ts
    FROM {{ this }}
    {% else %}
    SELECT TIMESTAMP '1970-01-01 00:00:00' AS max_ts
    {% endif %}
),

source AS (
    SELECT 
        event_id,
        "timestamp",
        department,
        category,
        product,
        add_to_cart,
        country
    FROM {{ source('silver', 'stg_clickstream') }}
    WHERE DATE(timestamp) > (SELECT max_ts FROM max_ts)
),

clickstream_data AS (
    SELECT 
        event_id,
        "timestamp",
        department,
        category,
        product,
        add_to_cart,
        country
    FROM source
    WHERE country IS NOT NULL
),

dim_date AS (
    SELECT date_key, date
    FROM {{ source('gold', 'dim_date') }}
),

dim_category AS (
    SELECT category_sk, category_name
    FROM {{ source('gold', 'dim_category') }}
),

dim_product AS (
    SELECT product_sk, product_name
    FROM {{ source('gold', 'dim_product') }}
)

SELECT 
    cd.event_id,
    cd."timestamp",
    d.date_key,
    dc.category_sk,
    dp.product_sk,
    CASE
        WHEN cd.add_to_cart = 1 THEN 'ADD TO CART'
        ELSE 'VIEW PRODUCT'
    END AS add_to_cart,
    cd.country,
    HOUR(cd."timestamp") AS event_hour
FROM clickstream_data cd
JOIN dim_date d ON DATE(cd."timestamp") = d.date
JOIN dim_category dc ON LOWER(cd.category) = LOWER(dc.category_name)
JOIN dim_product dp ON LOWER(cd.product) = LOWER(dp.product_name)
