{{ config(materialized='incremental', unique_key='order_item_id') }}
{% if is_incremental() %}
    SELECT 
        oi.order_item_id, o.order_id, p.product_sk, c.customer_sk, st.store_sk, g.geography_sk,
        CAST(DATE_FORMAT(o.order_date, '%Y%m%d') AS INTEGER) AS order_date_key,
        CAST(DATE_FORMAT(s.shipping_date, '%Y%m%d') AS INTEGER) AS shipping_date_key,
        os.order_status_sk, sm.shipping_mode_sk, ds.delivery_status_sk, pt.payment_type_sk,
        oi.quantity, oi.unit_price, oi.discount, oi.total_price, o.sales, o.profit_per_order AS profit,
        s.days_for_shipping_real, s.days_for_shipment_scheduled, s.late_delivery_risk
    FROM {{ ref('stg_orders') }} o
    JOIN {{ ref('stg_order_items') }} oi ON o.order_id = oi.order_id
    JOIN {{ ref('stg_shipping') }} s ON o.order_id = s.order_id
    JOIN {{ ref('dim_product') }} p ON oi.product_id = p.product_id
        AND o.order_date BETWEEN p.effective_date AND COALESCE(p.expiration_date, DATE '9999-12-31')
    JOIN {{ ref('dim_customer') }} c ON o.customer_id = c.customer_id
        AND o.order_date BETWEEN c.effective_date AND COALESCE(c.expiration_date, DATE '9999-12-31')
    JOIN {{ ref('dim_store') }} st ON o.store_id = st.store_id
        AND o.order_date BETWEEN st.effective_date AND COALESCE(st.expiration_date, DATE '9999-12-31')
    JOIN {{ ref('dim_geography') }} g ON CONCAT(o.order_city, '_', o.order_state, '_', o.order_country) = g.geography_id
    JOIN {{ ref('dim_order_status') }} os ON o.order_status = os.order_status
    JOIN {{ ref('dim_shipping_mode') }} sm ON s.shipping_mode = sm.shipping_mode
    JOIN {{ ref('dim_delivery_status') }} ds ON s.delivery_status = ds.delivery_status
    JOIN {{ ref('dim_payment_type') }} pt ON o.payment_type = pt.payment_type
    WHERE o.order_date > (SELECT COALESCE(MAX(CAST(DATE_PARSE(CAST(order_date_key AS VARCHAR), '%Y%m%d') AS DATE)), DATE '1900-01-01') FROM {{ this }})
{% else %}
    SELECT 
        oi.order_item_id, o.order_id, p.product_sk, c.customer_sk, st.store_sk, g.geography_sk,
        CAST(DATE_FORMAT(o.order_date, '%Y%m%d') AS INTEGER) AS order_date_key,
        CAST(DATE_FORMAT(s.shipping_date, '%Y%m%d') AS INTEGER) AS shipping_date_key,
        os.order_status_sk, sm.shipping_mode_sk, ds.delivery_status_sk, pt.payment_type_sk,
        oi.quantity, oi.unit_price, oi.discount, oi.total_price, o.sales, o.profit_per_order AS profit,
        s.days_for_shipping_real, s.days_for_shipment_scheduled, s.late_delivery_risk
    FROM {{ ref('stg_orders') }} o
    JOIN {{ ref('stg_order_items') }} oi ON o.order_id = oi.order_id
    JOIN {{ ref('stg_shipping') }} s ON o.order_id = s.order_id
    JOIN {{ ref('dim_product') }} p ON oi.product_id = p.product_id
        AND o.order_date BETWEEN p.effective_date AND COALESCE(p.expiration_date, DATE '9999-12-31')
    JOIN {{ ref('dim_customer') }} c ON o.customer_id = c.customer_id
        AND o.order_date BETWEEN c.effective_date AND COALESCE(c.expiration_date, DATE '9999-12-31')
    JOIN {{ ref('dim_store') }} st ON o.store_id = st.store_id
        AND o.order_date BETWEEN st.effective_date AND COALESCE(st.expiration_date, DATE '9999-12-31')
    JOIN {{ ref('dim_geography') }} g ON CONCAT(o.order_city, '_', o.order_state, '_', o.order_country) = g.geography_id
    JOIN {{ ref('dim_order_status') }} os ON o.order_status = os.order_status
    JOIN {{ ref('dim_shipping_mode') }} sm ON s.shipping_mode = sm.shipping_mode
    JOIN {{ ref('dim_delivery_status') }} ds ON s.delivery_status = ds.delivery_status
    JOIN {{ ref('dim_payment_type') }} pt ON o.payment_type = pt.payment_type
{% endif %}