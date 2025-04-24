{{ config(
    materialized='incremental', 
    unique_key='customer_sk', 
    incremental_strategy='delete+insert') }}

{% set attributes = ['customer_fname', 'customer_lname', 'customer_email', 'sales_per_customer', 'customer_segment'] %}

{{ handle_scd_type2(
    ref('stg_customers'), 
    this, 
    'customer_id', 
    attributes, 
    'customer_sk') }}