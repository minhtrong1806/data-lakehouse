SELECT ROW_NUMBER() OVER (ORDER BY delivery_status) AS delivery_status_sk, delivery_status
FROM {{ ref('stg_shipping') }} GROUP BY delivery_status