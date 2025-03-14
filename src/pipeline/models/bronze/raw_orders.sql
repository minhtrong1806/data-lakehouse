with source as (
        select * from {{ source('supply_chain', 'orders') }}
  ),
  renamed as (
      select
        {{ adapter.quote("order_id") }},
        {{ adapter.quote("order_date") }},
        {{ adapter.quote("order_customer_id") }},
        {{ adapter.quote("store_id") }},
        {{ adapter.quote("order_status") }},
        {{ adapter.quote("order_city") }},
        {{ adapter.quote("order_state") }},
        {{ adapter.quote("order_country") }},
        {{ adapter.quote("order_region") }},
        {{ adapter.quote("order_market") }},
        {{ adapter.quote("sales") }},
        {{ adapter.quote("payment_type") }}

      from source
  )
  select * from renamed
    