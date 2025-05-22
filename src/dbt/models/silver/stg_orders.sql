WITH order_profit AS (
    SELECT 
        oi.order_id,
        SUM((oi.unit_price - p.product_price)* oi.quantity - oi.discount) AS profit_per_order
    FROM {{ ref('raw_order_items') }} oi
        JOIN {{ ref('raw_products') }} p 
        ON oi.product_id = p.product_id
    GROUP BY oi.order_id
)
SELECT 
    o.order_id,
    o.order_date,
    o.order_customer_id AS customer_id,
    o.store_id,
    o.order_status,
    o.order_city,
    o.order_state,
    o.order_country,
    o.order_region,
    o.order_market,
    o.sales,
    o.payment_type,
    COALESCE(op.profit_per_order, 0) AS profit_per_order
FROM {{ ref('raw_orders') }} o
LEFT JOIN order_profit op
    ON o.order_id = op.order_id
WHERE o.order_id IS NOT NULL