SELECT 
    oi.order_item_id,
    oi.order_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    oi.discount,
    oi.total_price,
    CASE 
        WHEN oi.unit_price > 0 
        THEN (oi.unit_price - p.product_price - oi.discount/oi.quantity) / oi.unit_price
        ELSE 0 
    END AS profit_ratio
FROM {{ ref('raw_order_items') }} oi
 JOIN {{ ref('raw_products') }} p 
  ON oi.product_id = p.product_id
