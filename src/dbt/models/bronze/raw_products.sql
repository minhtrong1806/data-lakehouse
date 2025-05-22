with source AS (
    SELECT * FROM {{ source('supply_chain', 'products') }}
  ),
renamed AS (
      SELECT
        {{ adapter.quote("product_id") }},
        {{ adapter.quote("product_name") }},
        {{ adapter.quote("product_description") }},
        {{ adapter.quote("product_price") }},
        {{ adapter.quote("product_status") }},
        {{ adapter.quote("category_id") }},
        {{ adapter.quote("product_image") }}
      FROM source
  )
SELECT * FROM renamed
    