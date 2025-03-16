SELECT 
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount,
    total_price,
    CASE 
        WHEN unit_price > 0 
        THEN unit_price / unit_price 
        ELSE 0 
    END AS profit_ratio
FROM {{ ref('raw_order_items') }} 