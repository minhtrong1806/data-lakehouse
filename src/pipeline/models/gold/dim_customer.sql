{{ config(materialized='incremental', unique_key='customer_sk') }}
{% set attributes = ['customer_fname', 'customer_lname', 'customer_email', 'sales_per_customer'] %}
{{ handle_scd_type2(ref('stg_customers'), this, 'customer_id', attributes) }}