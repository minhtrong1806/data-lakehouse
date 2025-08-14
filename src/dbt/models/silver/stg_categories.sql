SELECT
    category_id,
    category_name
FROM {{ref('raw_categories')}}
WHERE category_id IS NOT NULL