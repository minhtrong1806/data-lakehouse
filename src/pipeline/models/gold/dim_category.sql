SELECT 
    ROW_NUMBER() OVER (ORDER BY category_id) AS category_sk, 
    category_id, 
    category_name
FROM {{ ref('stg_categories') }}