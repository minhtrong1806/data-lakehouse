SELECT 
    product_id,
    product_name,
    product_price,
    product_status,
    category_id,
    product_image
FROM {{ ref('raw_products') }}