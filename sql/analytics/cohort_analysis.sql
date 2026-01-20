-- Cohort Retention Analysis

-- Cohort Retention Table 
WITH cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM analytics.fact_subscription
    GROUP BY cohort_month
),
cohort_retention AS (
    SELECT 
        s.cohort_month,
        s.cohort_age_months,
        COUNT(DISTINCT s.customer_id) AS active_customers
    FROM analytics.fact_subscription_monthly_snapshot s
    GROUP BY s.cohort_month, s.cohort_age_months
)
SELECT 
    TO_CHAR(cr.cohort_month, 'YYYY-MM') AS cohort,
    cs.cohort_size,
    cr.cohort_age_months AS month,
    cr.active_customers,
    ROUND(100.0 * cr.active_customers / cs.cohort_size, 2) AS retention_pct
FROM cohort_retention cr
INNER JOIN cohort_sizes cs ON cr.cohort_month = cs.cohort_month
WHERE cr.cohort_month >= '2021-01-01' 
ORDER BY cr.cohort_month, cr.cohort_age_months;

-- Cohort Retention Pivot 

-- Pivoted view showing Month 0, 1, 3, 6, 12 retention
WITH cohort_retention_wide AS (
    SELECT 
        cohort_month,
        cohort_age_months,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM analytics.fact_subscription_monthly_snapshot
    GROUP BY cohort_month, cohort_age_months
),
cohort_base AS (
    SELECT 
        cohort_month,
        MAX(CASE WHEN cohort_age_months = 0 THEN active_customers END) AS month_0
    FROM cohort_retention_wide
    GROUP BY cohort_month
)
SELECT 
    TO_CHAR(cb.cohort_month, 'YYYY-MM') AS cohort,
    cb.month_0 AS cohort_size,
    
    -- Retention rates at key milestones
    ROUND(100.0 * MAX(CASE WHEN crw.cohort_age_months = 1 THEN crw.active_customers END) / cb.month_0, 1) AS month_1_retention,
    ROUND(100.0 * MAX(CASE WHEN crw.cohort_age_months = 3 THEN crw.active_customers END) / cb.month_0, 1) AS month_3_retention,
    ROUND(100.0 * MAX(CASE WHEN crw.cohort_age_months = 6 THEN crw.active_customers END) / cb.month_0, 1) AS month_6_retention,
    ROUND(100.0 * MAX(CASE WHEN crw.cohort_age_months = 12 THEN crw.active_customers END) / cb.month_0, 1) AS month_12_retention
    
FROM cohort_base cb
LEFT JOIN cohort_retention_wide crw ON cb.cohort_month = crw.cohort_month
WHERE cb.cohort_month >= '2021-01-01'
GROUP BY cb.cohort_month, cb.month_0
ORDER BY cb.cohort_month;

-- Revenue Cohort Analysis

-- Track MRR retention by cohort
WITH cohort_mrr AS (
    SELECT 
        cohort_month,
        cohort_age_months,
        SUM(monthly_charges) AS cohort_mrr
    FROM analytics.fact_subscription_monthly_snapshot
    GROUP BY cohort_month, cohort_age_months
),
starting_mrr AS (
    SELECT 
        cohort_month,
        cohort_mrr AS month_0_mrr
    FROM cohort_mrr
    WHERE cohort_age_months = 0
)
SELECT 
    TO_CHAR(cm.cohort_month, 'YYYY-MM') AS cohort,
    cm.cohort_age_months AS month,
    ROUND(cm.cohort_mrr, 2) AS cohort_mrr,
    ROUND(sm.month_0_mrr, 2) AS starting_mrr,
    ROUND(100.0 * cm.cohort_mrr / sm.month_0_mrr, 2) AS revenue_retention_pct
FROM cohort_mrr cm
INNER JOIN starting_mrr sm ON cm.cohort_month = sm.cohort_month
WHERE cm.cohort_month >= '2021-01-01'
ORDER BY cm.cohort_month, cm.cohort_age_months;

-- Cohort Performance Summary
SELECT 
    TO_CHAR(f.cohort_month, 'YYYY-MM') AS cohort,
    COUNT(*) AS cohort_size,
    
    -- Retention
    ROUND(100.0 * SUM(CASE WHEN f.is_active THEN 1 ELSE 0 END) / COUNT(*), 2) AS current_retention_pct,
    
    -- Revenue metrics
    ROUND(AVG(f.monthly_charges), 2) AS avg_starting_mrr,
    ROUND(AVG(f.total_charges), 2) AS avg_total_revenue,
    ROUND(AVG(f.tenure_months), 1) AS avg_tenure_months,
    
    -- Mix
    ROUND(100.0 * SUM(CASE WHEN c.contract_type != 'Month-to-month' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_annual_contract,
    ROUND(100.0 * SUM(CASE WHEN s.service_bundle_tier = 'Premium' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_premium_tier
    
FROM analytics.fact_subscription f
INNER JOIN analytics.dim_contract c ON f.contract_key = c.contract_key
INNER JOIN analytics.dim_service s ON f.service_key = s.service_key
WHERE f.cohort_month >= '2021-01-01'
GROUP BY f.cohort_month
ORDER BY f.cohort_month;
