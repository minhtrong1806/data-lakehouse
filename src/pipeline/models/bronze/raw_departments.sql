with source as (
        select * from {{ source('supply_chain', 'departments') }}
  ),
  renamed as (
      select
        {{ adapter.quote("department_id") }},
        {{ adapter.quote("department_name") }}

      from source
  )
  select * from renamed
    