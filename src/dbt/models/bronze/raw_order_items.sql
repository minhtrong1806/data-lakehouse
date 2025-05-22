with source AS (
      SELECT * FROM {{ source('supply_chain', 'order_items') }}
  ),
renamed AS (
      SELECT
        {{ adapter.quote("order_item_id") }},
        {{ adapter.quote("order_id") }},
        {{ adapter.quote("product_id") }},
        {{ adapter.quote("quantity") }},
        {{ adapter.quote("unit_price") }},
        {{ adapter.quote("discount") }},
        {{ adapter.quote("total_price") }}
      FROM source
  )
SELECT * FROM renamed
    