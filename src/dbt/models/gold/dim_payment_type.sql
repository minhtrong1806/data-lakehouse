SELECT 
    ROW_NUMBER() OVER (ORDER BY payment_type) AS payment_type_sk, 
    payment_type
FROM {{ ref('stg_orders') }} 
GROUP BY payment_type