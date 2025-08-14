WITH source AS (
      SELECT * FROM {{ source('supply_chain', 'categories') }}
  ),
renamed AS (
      SELECT
        {{ adapter.quote("category_id") }},
        {{ adapter.quote("category_name") }}
      FROM source
  )
  SELECT * FROM renamed
    