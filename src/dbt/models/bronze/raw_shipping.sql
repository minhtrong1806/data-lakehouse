with source AS (
      SELECT * FROM {{ source('supply_chain', 'shipping') }}
  ),
  renamed AS (
      SELECT
        {{ adapter.quote("shipping_id") }},
        {{ adapter.quote("order_id") }},
        {{ adapter.quote("shipping_date") }},
        {{ adapter.quote("shipping_mode") }},
        {{ adapter.quote("days_for_shipping_real") }},
        {{ adapter.quote("days_for_shipment_scheduled") }},
        {{ adapter.quote("delivery_status") }}

      FROM source
  )
SELECT * FROM renamed
    