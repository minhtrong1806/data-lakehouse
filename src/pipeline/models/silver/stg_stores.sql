SELECT 
    store_id,
    store_latitude,
    store_longitude,
    store_street,
    store_city,
    store_state,
    store_zipcode,
    store_country
FROM {{ ref('raw_stores') }}