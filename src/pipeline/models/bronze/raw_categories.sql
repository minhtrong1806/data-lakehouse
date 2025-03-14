with source as (
        select * from {{ source('supply_chain', 'categories') }}
  ),
  renamed as (
      select
        {{ adapter.quote("category_id") }},
        {{ adapter.quote("category_name") }}

      from source
  )
  select * from renamed
    