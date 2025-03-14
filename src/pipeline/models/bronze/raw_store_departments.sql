with source as (
        select * from {{ source('supply_chain', 'store_departments') }}
  ),
  renamed as (
      select
        {{ adapter.quote("store_id") }},
        {{ adapter.quote("department_id") }}

      from source
  )
  select * from renamed
    