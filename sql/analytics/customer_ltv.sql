-- Customer Lifetime Value (LTV) Analysis

-- Historical LTV 
SELECT 
    'Churned Customers' AS customer_group,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_charges), 2) AS avg_ltv,
    ROUND(AVG(tenure_months), 1) AS avg_lifetime_months,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
    ROUND(MIN(total_charges), 2) AS min_ltv,
    ROUND(MAX(total_charges), 2) AS max_ltv,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_charges)::NUMERIC, 2) AS median_ltv
FROM analytics.fact_subscription
WHERE churned = TRUE;

-- LTV by Cohort (Churned Customers Only)
SELECT 
    TO_CHAR(cohort_month, 'YYYY-MM') AS cohort,
    COUNT(*) AS churned_count,
    ROUND(AVG(total_charges), 2) AS avg_ltv,
    ROUND(AVG(tenure_months), 1) AS avg_lifetime_months,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges
FROM analytics.fact_subscription
WHERE churned = TRUE
GROUP BY cohort_month
ORDER BY cohort_month;

-- Predictive LTV (Simple Model)
WITH latest_metrics AS (
    SELECT 
        snapshot_date,
        COUNT(DISTINCT customer_id) AS active_customers,
        AVG(monthly_charges) AS arpu,
        COUNT(DISTINCT CASE WHEN is_churn_month THEN customer_id END) AS churned_customers
    FROM analytics.fact_subscription_monthly_snapshot
    WHERE snapshot_date = '2024-01-01' 
    GROUP BY snapshot_date
)
SELECT 
    snapshot_date,
    ROUND(arpu::NUMERIC, 2) AS arpu,
    ROUND(100.0 * churned_customers / active_customers, 2) AS monthly_churn_rate_pct,
    ROUND((arpu / NULLIF((churned_customers::NUMERIC / active_customers), 0))::NUMERIC, 2) AS predicted_ltv
FROM latest_metrics;

-- LTV by Contract Type
SELECT 
    c.contract_type,
    COUNT(*) AS customer_count,
    
    -- Churned customers only
    SUM(CASE WHEN f.churned THEN 1 ELSE 0 END) AS churned_count,
    ROUND(AVG(CASE WHEN f.churned THEN f.total_charges END), 2) AS avg_ltv_churned,
    ROUND(AVG(CASE WHEN f.churned THEN f.tenure_months END), 1) AS avg_lifetime_months_churned,
    
    -- All customers (projected)
    ROUND(AVG(f.monthly_charges), 2) AS avg_monthly_charges,
    ROUND(100.0 * SUM(CASE WHEN f.churned THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct,
    
    -- Predictive LTV
    ROUND(
        (AVG(f.monthly_charges) / 
        NULLIF((SUM(CASE WHEN f.churned THEN 1 ELSE 0 END)::NUMERIC / COUNT(*)), 0))::NUMERIC, 
        2
    ) AS predicted_ltv
    
FROM analytics.fact_subscription f
INNER JOIN analytics.dim_contract c ON f.contract_key = c.contract_key
GROUP BY c.contract_type
ORDER BY predicted_ltv DESC NULLS LAST;

-- LTV by Service Bundle Tier
SELECT 
    s.service_bundle_tier,
    COUNT(*) AS customer_count,
    
    -- Historical LTV
    SUM(CASE WHEN f.churned THEN 1 ELSE 0 END) AS churned_count,
    ROUND(AVG(CASE WHEN f.churned THEN f.total_charges END), 2) AS avg_ltv_churned,
    
    -- Predictive LTV
    ROUND(AVG(f.monthly_charges), 2) AS avg_monthly_charges,
    ROUND(100.0 * SUM(CASE WHEN f.churned THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(
        (AVG(f.monthly_charges) / 
        NULLIF((SUM(CASE WHEN f.churned THEN 1 ELSE 0 END)::NUMERIC / COUNT(*)), 0))::NUMERIC, 
        2
    ) AS predicted_ltv
    
FROM analytics.fact_subscription f
INNER JOIN analytics.dim_service s ON f.service_key = s.service_key
GROUP BY s.service_bundle_tier
ORDER BY predicted_ltv DESC NULLS LAST;

-- LTV Distribution by Decile
WITH customer_ltv AS (
    SELECT 
        customer_id,
        total_charges,
        NTILE(10) OVER (ORDER BY total_charges) AS ltv_decile
    FROM analytics.fact_subscription
    WHERE churned = TRUE 
SELECT 
    ltv_decile,
    COUNT(*) AS customer_count,
    ROUND(MIN(total_charges), 2) AS min_ltv,
    ROUND(MAX(total_charges), 2) AS max_ltv,
    ROUND(AVG(total_charges), 2) AS avg_ltv,
    ROUND(SUM(total_charges), 2) AS total_revenue
FROM customer_ltv
GROUP BY ltv_decile
ORDER BY ltv_decile;

-- LTV:CAC Readiness Analysis
SELECT 
    'Overall' AS segment,
    ROUND(AVG(CASE WHEN churned THEN total_charges END), 2) AS avg_ltv,
    ROUND(AVG(monthly_charges), 2) AS avg_arpu,
    ROUND(100.0 * SUM(CASE WHEN churned THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct,
    '[Add CAC here]' AS cac_placeholder,
    '[Calculate LTV:CAC ratio]' AS ltv_cac_ratio_placeholder
FROM analytics.fact_subscription;