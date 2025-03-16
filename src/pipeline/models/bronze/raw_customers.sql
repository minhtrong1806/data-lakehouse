with source AS (
      SELECT * FROM {{ source('supply_chain', 'customers') }}
  ),
renamed AS (
      SELECT
        {{ adapter.quote("customer_id") }},
        {{ adapter.quote("customer_fname") }},
        {{ adapter.quote("customer_lname") }},
        {{ adapter.quote("customer_email") }},
        {{ adapter.quote("customer_pASsword") }}
      FROM source
  )
SELECT * FROM renamed
    