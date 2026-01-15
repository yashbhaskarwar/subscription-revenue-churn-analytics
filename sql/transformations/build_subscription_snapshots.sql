-- Build Monthly Subscription Snapshots

TRUNCATE TABLE analytics.fact_subscription_monthly_snapshot CASCADE;

WITH monthly_spine AS (
    SELECT DISTINCT
        DATE_TRUNC('month', full_date)::DATE AS snapshot_date
    FROM analytics.dim_date
    WHERE full_date BETWEEN '2021-01-01' AND '2024-01-31'
),
subscription_months AS (
    SELECT 
        ms.snapshot_date,
        fs.customer_key,
        fs.service_key,
        fs.contract_key,
        fs.customer_id,
        fs.subscription_start_date,
        fs.subscription_end_date,
        fs.cohort_month,
        fs.monthly_charges,
        fs.churned
    FROM analytics.fact_subscription fs
    CROSS JOIN monthly_spine ms
    WHERE 
        ms.snapshot_date >= DATE_TRUNC('month', fs.subscription_start_date)::DATE
        AND (
            fs.subscription_end_date IS NULL 
            OR ms.snapshot_date <= DATE_TRUNC('month', fs.subscription_end_date)::DATE
        )
),
snapshot_metrics AS (
    SELECT 
        sm.snapshot_date,
        sm.customer_key,
        sm.service_key,
        sm.contract_key,
        sm.customer_id,
        sm.cohort_month,
        sm.monthly_charges,
        
        -- Calculate months since start
        EXTRACT(YEAR FROM AGE(sm.snapshot_date, sm.subscription_start_date))::INTEGER * 12 +
        EXTRACT(MONTH FROM AGE(sm.snapshot_date, sm.subscription_start_date))::INTEGER AS months_since_start,
        
        -- Cohort age
        EXTRACT(YEAR FROM AGE(sm.snapshot_date, sm.cohort_month))::INTEGER * 12 +
        EXTRACT(MONTH FROM AGE(sm.snapshot_date, sm.cohort_month))::INTEGER AS cohort_age_months,
        
        -- Period flags
        CASE 
            WHEN sm.snapshot_date = DATE_TRUNC('month', sm.subscription_start_date)::DATE 
            THEN TRUE 
            ELSE FALSE 
        END AS is_new_customer,
        
        CASE 
            WHEN sm.churned 
                AND sm.snapshot_date = DATE_TRUNC('month', sm.subscription_end_date)::DATE 
            THEN TRUE 
            ELSE FALSE 
        END AS is_churn_month,
        
        TRUE AS is_active 
        
    FROM subscription_months sm
)
INSERT INTO analytics.fact_subscription_monthly_snapshot (
    snapshot_date,
    snapshot_month_key,
    customer_key,
    service_key,
    contract_key,
    customer_id,
    is_active,
    months_since_start,
    monthly_charges,
    cohort_month,
    cohort_age_months,
    is_new_customer,
    is_churn_month
)
SELECT 
    sm.snapshot_date,
    TO_CHAR(sm.snapshot_date, 'YYYYMMDD')::INTEGER AS snapshot_month_key,
    sm.customer_key,
    sm.service_key,
    sm.contract_key,
    sm.customer_id,
    sm.is_active,
    sm.months_since_start,
    sm.monthly_charges,
    sm.cohort_month,
    sm.cohort_age_months,
    sm.is_new_customer,
    sm.is_churn_month
FROM snapshot_metrics sm;

-- Validation Queries

-- Total snapshot records
SELECT 
    COUNT(*) AS total_snapshot_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT snapshot_date) AS months_covered
FROM analytics.fact_subscription_monthly_snapshot;

-- Monthly MRR trend
SELECT 
    snapshot_date,
    COUNT(DISTINCT customer_id) AS active_customers,
    ROUND(SUM(monthly_charges), 2) AS total_mrr,
    ROUND(AVG(monthly_charges), 2) AS arpu,
    SUM(CASE WHEN is_new_customer THEN 1 ELSE 0 END) AS new_customers,
    SUM(CASE WHEN is_churn_month THEN 1 ELSE 0 END) AS churned_customers
FROM analytics.fact_subscription_monthly_snapshot
GROUP BY snapshot_date
ORDER BY snapshot_date;

-- Cohort retention snapshot 
SELECT 
    cohort_month,
    cohort_age_months,
    COUNT(DISTINCT customer_id) AS active_customers
FROM analytics.fact_subscription_monthly_snapshot
WHERE cohort_month >= '2022-01-01'
GROUP BY cohort_month, cohort_age_months
HAVING cohort_age_months <= 12
ORDER BY cohort_month, cohort_age_months
LIMIT 50;

-- Sanity check
SELECT 
    snapshot_date,
    customer_id,
    COUNT(*) AS duplicate_count
FROM analytics.fact_subscription_monthly_snapshot
GROUP BY snapshot_date, customer_id
HAVING COUNT(*) > 1;
