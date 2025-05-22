WITH sales AS (
    SELECT
        o.order_customer_id,
        SUM(o.sales) AS total_sales
    FROM {{ref('raw_orders')}} o
    GROUP BY o.order_customer_id
)
SELECT
    c.customer_id,
    REGEXP_REPLACE(LOWER(c.customer_fname), '(^|\s)(\w)', x -> UPPER(x[2])) AS customer_fname,
    REGEXP_REPLACE(LOWER(c.customer_lname), '(^|\s)(\w)', x -> UPPER(x[2])) AS customer_lname,
    c.customer_email,
    s.total_sales AS sales_per_customer
FROM {{ref('raw_customers')}} c
LEFT JOIN sales s ON c.customer_id = s.order_customer_id
WHERE c.customer_email IS NOT NULL AND c.customer_email <> ''