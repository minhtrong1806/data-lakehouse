SELECT 
    CAST(DATE_FORMAT(date, '%Y%m%d') AS INTEGER) AS date_key,
    date AS date,
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(QUARTER FROM date) AS quarter,
    CASE 
        WHEN EXTRACT(QUARTER FROM date) = 1 THEN 'Q1'
        WHEN EXTRACT(QUARTER FROM date) = 2 THEN 'Q2'
        WHEN EXTRACT(QUARTER FROM date) = 3 THEN 'Q3'
        WHEN EXTRACT(QUARTER FROM date) = 4 THEN 'Q4'
    END AS quarter_name,
    EXTRACT(MONTH FROM date) AS month,
    CASE 
        WHEN EXTRACT(MONTH FROM date) = 1 THEN 'January'
        WHEN EXTRACT(MONTH FROM date) = 2 THEN 'February'
        WHEN EXTRACT(MONTH FROM date) = 3 THEN 'March'
        WHEN EXTRACT(MONTH FROM date) = 4 THEN 'April'
        WHEN EXTRACT(MONTH FROM date) = 5 THEN 'May'
        WHEN EXTRACT(MONTH FROM date) = 6 THEN 'June'
        WHEN EXTRACT(MONTH FROM date) = 7 THEN 'July'
        WHEN EXTRACT(MONTH FROM date) = 8 THEN 'August'
        WHEN EXTRACT(MONTH FROM date) = 9 THEN 'September'
        WHEN EXTRACT(MONTH FROM date) = 10 THEN 'October'
        WHEN EXTRACT(MONTH FROM date) = 11 THEN 'November'
        WHEN EXTRACT(MONTH FROM date) = 12 THEN 'December'
    END AS month_name,
    EXTRACT(DAY FROM date) AS day,
    EXTRACT(DAY_OF_WEEK FROM date) AS day_of_week_number,
    CASE 
        WHEN EXTRACT(DAY_OF_WEEK FROM date) = 1 THEN 'Monday'
        WHEN EXTRACT(DAY_OF_WEEK FROM date) = 2 THEN 'Tuesday'
        WHEN EXTRACT(DAY_OF_WEEK FROM date) = 3 THEN 'Wednesday'
        WHEN EXTRACT(DAY_OF_WEEK FROM date) = 4 THEN 'Thursday'
        WHEN EXTRACT(DAY_OF_WEEK FROM date) = 5 THEN 'Friday'
        WHEN EXTRACT(DAY_OF_WEEK FROM date) = 6 THEN 'Saturday'
        WHEN EXTRACT(DAY_OF_WEEK FROM date) = 7 THEN 'Sunday'
    END AS day_of_week_name,
    CASE 
        WHEN EXTRACT(DAY_OF_WEEK FROM date) IN (6, 7) THEN 1
        ELSE 0
    END AS is_weekend,
    EXTRACT(WEEK FROM date) AS week_number,
    EXTRACT(DAY_OF_YEAR FROM date) AS day_of_year
FROM UNNEST(SEQUENCE(DATE '2015-01-01', DATE '2017-09-30', INTERVAL '1' DAY)) AS t(date)