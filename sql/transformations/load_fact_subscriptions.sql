-- Load Fact Subscription with Business Logic

TRUNCATE TABLE analytics.fact_subscription CASCADE;

WITH subscription_base AS (
    SELECT 
        stg.customer_id,
        
        -- Join to dimension keys
        dc.customer_key,
        ds.service_key,
        dct.contract_key,
        
        -- Calculate dates based on tenure
        DATE '2024-01-31' AS snapshot_date,
        (DATE '2024-01-31' - (stg.tenure || ' months')::INTERVAL)::DATE AS subscription_start_date,
        CASE 
            WHEN stg.churn = 'Yes' THEN DATE '2024-01-31'
            ELSE NULL 
        END AS subscription_end_date,
        
        -- Tenure and status
        stg.tenure AS tenure_months,
        CASE WHEN stg.churn = 'No' THEN TRUE ELSE FALSE END AS is_active,
        CASE WHEN stg.churn = 'Yes' THEN TRUE ELSE FALSE END AS churned,
        
        -- Financial metrics
        stg.monthly_charges,
        CASE 
            WHEN stg.total_charges = '' OR stg.total_charges = ' ' THEN 0
            ELSE stg.total_charges::NUMERIC 
        END AS total_charges
        
    FROM staging.telco_customer_raw stg
    INNER JOIN analytics.dim_customer dc ON stg.customer_id = dc.customer_id
    INNER JOIN analytics.dim_service ds ON stg.customer_id = ds.customer_id
    INNER JOIN analytics.dim_contract dct ON stg.customer_id = dct.customer_id
)
INSERT INTO analytics.fact_subscription (
    customer_key,
    service_key,
    contract_key,
    customer_id,
    subscription_start_date,
    subscription_end_date,
    tenure_months,
    is_active,
    churned,
    monthly_charges,
    total_charges,
    cohort_month,
    cohort_year_month
)
SELECT 
    customer_key,
    service_key,
    contract_key,
    customer_id,
    subscription_start_date,
    subscription_end_date,
    tenure_months,
    is_active,
    churned,
    monthly_charges,
    total_charges,
    DATE_TRUNC('month', subscription_start_date)::DATE AS cohort_month,
    TO_CHAR(subscription_start_date, 'YYYY-MM') AS cohort_year_month
FROM subscription_base;

-- Validation Queries
SELECT 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_customers,
    SUM(CASE WHEN churned THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN churned THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(SUM(monthly_charges), 2) AS total_mrr,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charge
FROM analytics.fact_subscription;

-- Cohort distribution
SELECT 
    cohort_year_month,
    COUNT(*) AS cohort_size,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS still_active,
    ROUND(100.0 * SUM(CASE WHEN is_active THEN 1 ELSE 0 END) / COUNT(*), 2) AS retention_rate
FROM analytics.fact_subscription
GROUP BY cohort_year_month
ORDER BY cohort_year_month;

-- Date range check
SELECT 
    MIN(subscription_start_date) AS earliest_start,
    MAX(subscription_start_date) AS latest_start,
    MIN(subscription_end_date) AS earliest_churn,
    MAX(subscription_end_date) AS latest_churn
FROM analytics.fact_subscription;