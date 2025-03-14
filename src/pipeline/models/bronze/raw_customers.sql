with source as (
        select * from {{ source('supply_chain', 'customers') }}
  ),
  renamed as (
      select
        {{ adapter.quote("customer_id") }},
        {{ adapter.quote("customer_fname") }},
        {{ adapter.quote("customer_lname") }},
        {{ adapter.quote("customer_email") }},
        {{ adapter.quote("customer_password") }},
        {{ adapter.quote("customer_street") }},
        {{ adapter.quote("customer_city") }},
        {{ adapter.quote("customer_state") }},
        {{ adapter.quote("customer_zipcode") }},
        {{ adapter.quote("customer_country") }}

      from source
  )
  select * from renamed
    