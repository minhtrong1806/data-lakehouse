SELECT ROW_NUMBER() OVER (ORDER BY order_status) AS order_status_sk, order_status
FROM {{ ref('stg_orders') }} GROUP BY order_status