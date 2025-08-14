with source AS (
      SELECT * FROM {{ source('supply_chain', 'stores') }}
  ),
  renamed AS (
      SELECT
        {{ adapter.quote("store_id") }},
        {{ adapter.quote("store_latitude") }},
        {{ adapter.quote("store_longitude") }},
        {{ adapter.quote("store_street") }},
        {{ adapter.quote("store_city") }},
        {{ adapter.quote("store_state") }},
        {{ adapter.quote("store_zipcode") }},
        {{ adapter.quote("store_country") }}
      FROM source
  )
SELECT * FROM renamed
    