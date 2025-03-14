with source as (
        select * from {{ source('supply_chain', 'stores') }}
  ),
  renamed as (
      select
        {{ adapter.quote("store_id") }},
        {{ adapter.quote("store_name") }},
        {{ adapter.quote("store_latitude") }},
        {{ adapter.quote("store_longitude") }}

      from source
  )
  select * from renamed
    