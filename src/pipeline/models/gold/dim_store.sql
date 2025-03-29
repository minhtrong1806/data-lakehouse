{{ config(materialized='incremental', unique_key='store_sk', incremental_strategy='delete+insert') }}
{% set attributes = ['store_latitude', 'store_longitude', 'store_street', 'store_city', 'store_state', 'store_zipcode', 'store_country'] %}
{{ handle_scd_type2(ref('stg_stores'), this, 'store_id', attributes, 'store_sk') }}