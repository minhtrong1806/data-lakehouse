with source as (
        select * from {{ source('supply_chain', 'products') }}
  ),
  renamed as (
      select
        {{ adapter.quote("product_id") }},
        {{ adapter.quote("product_name") }},
        {{ adapter.quote("product_description") }},
        {{ adapter.quote("product_price") }},
        {{ adapter.quote("product_status") }},
        {{ adapter.quote("category_id") }},
        {{ adapter.quote("product_image") }}

      from source
  )
  select * from renamed
    