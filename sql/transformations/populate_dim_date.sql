-- Populate Date Dimension

TRUNCATE TABLE analytics.dim_date;

INSERT INTO analytics.dim_date (
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    week_of_year,
    day_of_month,
    day_of_week,
    day_name,
    is_weekend,
    fiscal_year,
    fiscal_quarter
)
SELECT 
    TO_CHAR(date_series, 'YYYYMMDD')::INTEGER AS date_key,
    date_series AS full_date,
    EXTRACT(YEAR FROM date_series)::INTEGER AS year,
    EXTRACT(QUARTER FROM date_series)::INTEGER AS quarter,
    EXTRACT(MONTH FROM date_series)::INTEGER AS month,
    TO_CHAR(date_series, 'Month') AS month_name,
    EXTRACT(WEEK FROM date_series)::INTEGER AS week_of_year,
    EXTRACT(DAY FROM date_series)::INTEGER AS day_of_month,
    EXTRACT(ISODOW FROM date_series)::INTEGER AS day_of_week,
    TO_CHAR(date_series, 'Day') AS day_name,
    CASE 
        WHEN EXTRACT(ISODOW FROM date_series) IN (6, 7) THEN TRUE 
        ELSE FALSE 
    END AS is_weekend,

    CASE 
        WHEN EXTRACT(MONTH FROM date_series) >= 2 
        THEN EXTRACT(YEAR FROM date_series)::INTEGER
        ELSE EXTRACT(YEAR FROM date_series)::INTEGER - 1
    END AS fiscal_year,
    CASE 
        WHEN EXTRACT(MONTH FROM date_series) IN (2, 3, 4) THEN 1
        WHEN EXTRACT(MONTH FROM date_series) IN (5, 6, 7) THEN 2
        WHEN EXTRACT(MONTH FROM date_series) IN (8, 9, 10) THEN 3
        ELSE 4
    END AS fiscal_quarter
FROM GENERATE_SERIES(
    '2021-01-01'::DATE,
    '2024-12-31'::DATE,
    '1 day'::INTERVAL
) AS date_series;

-- Validate
SELECT 
    MIN(full_date) AS min_date,
    MAX(full_date) AS max_date,
    COUNT(*) AS total_days
FROM analytics.dim_date;