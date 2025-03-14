with source as (
        select * from {{ source('supply_chain', 'order_items') }}
  ),
  renamed as (
      select
        {{ adapter.quote("order_item_id") }},
        {{ adapter.quote("order_id") }},
        {{ adapter.quote("product_id") }},
        {{ adapter.quote("quantity") }},
        {{ adapter.quote("unit_price") }},
        {{ adapter.quote("discount") }},
        {{ adapter.quote("total_price") }}

      from source
  )
  select * from renamed
    