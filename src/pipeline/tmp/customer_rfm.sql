{{ config(materialized='incremental', unique_key='rfm_sk') }}

{% if is_incremental() %}
    WITH rfm_data AS (
        SELECT 
            fs.customer_id,
            DATEDIFF('day', MAX(CAST(DATE_PARSE(CAST(fs.order_date_key AS VARCHAR), '%Y%m%d') AS DATE)), CURRENT_DATE) AS recency,
            COUNT(DISTINCT fs.order_id) AS frequency,
            SUM(fs.sales) AS monetary,
            MAX(c.sales_per_customer) AS sales_per_customer,
            SUM(fs.sales) / COUNT(DISTINCT fs.order_id) AS avg_order_value,
            CURRENT_TIMESTAMP AS effective_date
        FROM {{ ref('fact_sales') }} fs
        JOIN {{ ref('dim_customer') }} c ON fs.customer_id = c.customer_id
            AND fs.order_date_key BETWEEN CAST(DATE_FORMAT(c.effective_date, '%Y%m%d') AS INTEGER) AND COALESCE(CAST(DATE_FORMAT(c.expiration_date, '%Y%m%d') AS INTEGER), 99991231)
        WHERE fs.order_date_key > (SELECT COALESCE(MAX(order_date_key), 0) FROM {{ this }})
        GROUP BY fs.customer_id
    )
    SELECT 
        ROW_NUMBER() OVER (ORDER BY customer_id) + (SELECT COALESCE(MAX(rfm_sk), 0) FROM {{ this }}) AS rfm_sk,
        customer_id, recency, frequency, monetary, sales_per_customer, avg_order_value, effective_date
    FROM rfm_data
{% else %}
    WITH rfm_data AS (
        SELECT 
            fs.customer_id,
            DATEDIFF('day', MAX(CAST(DATE_PARSE(CAST(fs.order_date_key AS VARCHAR), '%Y%m%d') AS DATE)), CURRENT_DATE) AS recency,
            COUNT(DISTINCT fs.order_id) AS frequency,
            SUM(fs.sales) AS monetary,
            MAX(c.sales_per_customer) AS sales_per_customer,
            SUM(fs.sales) / COUNT(DISTINCT fs.order_id) AS avg_order_value,
            CURRENT_TIMESTAMP AS effective_date
        FROM {{ ref('fact_sales') }} fs
        JOIN {{ ref('dim_customer') }} c ON fs.customer_id = c.customer_id
            AND fs.order_date_key BETWEEN CAST(DATE_FORMAT(c.effective_date, '%Y%m%d') AS INTEGER) AND COALESCE(CAST(DATE_FORMAT(c.expiration_date, '%Y%m%d') AS INTEGER), 99991231)
        GROUP BY fs.customer_id
    )
    SELECT 
        ROW_NUMBER() OVER (ORDER BY customer_id) AS rfm_sk,
        customer_id, recency, frequency, monetary, sales_per_customer, avg_order_value, effective_date
    FROM rfm_data
{% endif %}