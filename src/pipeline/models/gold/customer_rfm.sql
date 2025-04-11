{{ config(materialized='incremental', unique_key='rfm_sk', incremental_strategy='delete+insert') }}

{% if is_incremental() %}
    WITH rfm_data AS (
        SELECT 
            fs.customer_sk,
            DATE_DIFF('day', MAX(CAST(DATE_PARSE(CAST(fs.order_date_key AS VARCHAR), '%Y%m%d') AS DATE)),DATE '2018-01-31') AS recency,
            COUNT(DISTINCT fs.order_id) AS frequency,
            MAX(c.sales_per_customer) AS monetary,
            MAX(c.sales_per_customer) / NULLIF(COUNT(DISTINCT fs.order_id), 0) AS avg_order_value,
            CAST('2018-01-31 23:38:00.000' AS timestamp(6)) AS effective_date
        FROM {{ ref('fact_sales') }} fs
        JOIN {{ ref('dim_customer') }} c 
            ON fs.customer_sk = c.customer_sk
            AND fs.order_date_key BETWEEN CAST(DATE_FORMAT(c.effective_date, '%Y%m%d') AS INTEGER) 
                                    AND COALESCE(CAST(DATE_FORMAT(c.expiration_date, '%Y%m%d') AS INTEGER), 99991231)
        WHERE fs.order_date_key > (SELECT COALESCE(MAX(order_date_key), 0) FROM {{ this }})
        GROUP BY fs.customer_sk
    )
    SELECT 
        ROW_NUMBER() OVER (ORDER BY customer_sk) + (SELECT COALESCE(MAX(rfm_sk), 0) FROM {{ this }}) AS rfm_sk,
        customer_sk, recency, frequency, monetary, avg_order_value, effective_date
    FROM rfm_data
{% else %}
    WITH rfm_data AS (
        SELECT 
            fs.customer_sk,
            DATE_DIFF('day', MAX(CAST(DATE_PARSE(CAST(fs.order_date_key AS VARCHAR), '%Y%m%d') AS DATE)), DATE '2018-01-31') AS recency,
            COUNT(DISTINCT fs.order_id) AS frequency,
            MAX(c.sales_per_customer) AS monetary,
            MAX(c.sales_per_customer) / NULLIF(COUNT(DISTINCT fs.order_id), 0) AS avg_order_value,
            CAST('2018-01-31 23:38:00.000' AS timestamp(6)) AS effective_date
        FROM {{ ref('fact_sales') }} fs
        JOIN {{ ref('dim_customer') }} c 
            ON fs.customer_sk = c.customer_sk
            AND fs.order_date_key BETWEEN CAST(DATE_FORMAT(c.effective_date, '%Y%m%d') AS INTEGER) 
                                    AND COALESCE(CAST(DATE_FORMAT(c.expiration_date, '%Y%m%d') AS INTEGER), 99991231)
        GROUP BY fs.customer_sk
    )
    SELECT 
        ROW_NUMBER() OVER (ORDER BY customer_sk) AS rfm_sk,
        customer_sk, recency, frequency, monetary, avg_order_value, effective_date
    FROM rfm_data
{% endif %}
