SELECT 
    ROW_NUMBER() OVER (ORDER BY shipping_mode) AS shipping_mode_sk, 
    shipping_mode
FROM {{ ref('stg_shipping') }} 
GROUP BY shipping_mode