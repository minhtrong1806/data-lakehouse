SELECT 
    shipping_id,
    order_id,
    shipping_date,
    shipping_mode,
    days_for_shipping_real,
    days_for_shipment_scheduled,
    delivery_status,
    CASE 
        WHEN days_for_shipping_real > days_for_shipment_scheduled 
        THEN 1 
        ELSE 0 
    END AS late_delivery_risk
FROM {{ ref('raw_shipping') }}