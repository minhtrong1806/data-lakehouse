{{ config(materialized='incremental', unique_key='product_sk', incremental_strategy='delete+insert') }}
{% set attributes = ['product_name', 'product_price', 'product_status', 'category_id', 'product_image'] %}
{{ handle_scd_type2(ref('stg_products'), this, 'product_id', attributes, 'product_sk') }}