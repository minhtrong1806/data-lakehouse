SELECT 
    ROW_NUMBER() OVER (ORDER BY geography_id) AS geography_sk,
    geography_id, 
    city, 
    state, 
    country, 
    region, 
    market
FROM (
    SELECT DISTINCT
        CONCAT(order_city, '_', order_state, '_', order_country) AS geography_id,
        order_city AS city, 
        order_state AS state, 
        order_country AS country,
        order_region AS region, 
        order_market AS market
    FROM {{ ref('stg_orders') }}
) AS geo_data