WITH source AS (
    SELECT * FROM {{ source('lakehouse', 'raw_clickstream') }}
),
extracted_data AS (
    SELECT 
        uuid() event_id,  -- Tạo UUID duy nhất cho mỗi sự kiện
        ts,
        ip,
        url,
        regexp_extract(url, '^/department/([^/]+)/category/([^/]+)/product/(.*)', 1) AS department,
        regexp_extract(url, '^/department/([^/]+)/category/([^/]+)/product/(.*)', 2) AS category,
        regexp_extract(url, '^/department/([^/]+)/category/([^/]+)/product/(.*)', 3) AS product
    FROM source
)
SELECT
    event_id, 
    ts,
    ip, 
    regexp_replace(department, '%20', ' ') AS department,
    regexp_replace(category, '%20', ' ') AS category,
    regexp_replace(product, '%20', ' ') AS product
FROM extracted_data
WHERE regexp_replace(product, '%20', ' ') IS NOT NULL
