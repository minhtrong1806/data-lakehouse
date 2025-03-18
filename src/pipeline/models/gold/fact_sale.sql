SELECT 
    oi.order_item_id,
    o.order_id,
    oi.product_id,
    o.customer_id,
    o.store_id,
    CAST(DATE_FORMAT(o.order_date, '%Y%m%d') AS INTEGER) AS order_date_key, -- Sửa thành DATE_FORMAT
    CAST(DATE_FORMAT(s.shipping_date, '%Y%m%d') AS INTEGER) AS shipping_date_key, -- Sửa thành DATE_FORMAT
    o.order_status AS order_status_id,
    s.shipping_mode AS shipping_mode_id,
    s.delivery_status AS delivery_status_id,
    o.payment_type AS payment_type_id,
    oi.quantity,
    oi.unit_price,
    oi.discount,
    oi.total_price,
    o.sales,
    o.profit_per_order AS profit,
    s.days_for_shipping_real,
    s.days_for_shipment_scheduled,
    s.late_delivery_risk
FROM {{ ref('silver_orders') }} o
JOIN {{ ref('silver_order_items') }} oi
    ON o.order_id = oi.order_id
JOIN {{ ref('silver_shipping') }} s
    ON o.order_id = s.order_id