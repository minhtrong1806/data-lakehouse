with source as (
        select * from {{ source('supply_chain', 'shipping') }}
  ),
  renamed as (
      select
        {{ adapter.quote("shipping_id") }},
        {{ adapter.quote("order_id") }},
        {{ adapter.quote("shipping_date") }},
        {{ adapter.quote("shipping_mode") }},
        {{ adapter.quote("days_for_shipping_real") }},
        {{ adapter.quote("days_for_shipment_scheduled") }},
        {{ adapter.quote("delivery_status") }}

      from source
  )
  select * from renamed
    