-- Churn Metrics Analysis

-- Monthly Logo and Revenue Churn Rates
WITH monthly_cohorts AS (
    SELECT 
        snapshot_date,
        COUNT(DISTINCT CASE WHEN is_active THEN customer_id END) AS active_customers_start,
        SUM(CASE WHEN is_active THEN monthly_charges ELSE 0 END) AS mrr_start,
        COUNT(DISTINCT CASE WHEN is_churn_month THEN customer_id END) AS churned_customers,
        SUM(CASE WHEN is_churn_month THEN monthly_charges ELSE 0 END) AS churned_mrr
    FROM analytics.fact_subscription_monthly_snapshot
    GROUP BY snapshot_date
)
SELECT 
    TO_CHAR(snapshot_date, 'YYYY-MM') AS month,
    active_customers_start,
    ROUND(mrr_start, 2) AS starting_mrr,
    churned_customers,
    ROUND(churned_mrr, 2) AS churned_mrr,
    
    -- Logo churn rate 
    ROUND(100.0 * churned_customers / NULLIF(active_customers_start, 0), 2) AS logo_churn_rate_pct,
    
    -- Revenue churn rate 
    ROUND(100.0 * churned_mrr / NULLIF(mrr_start, 0), 2) AS revenue_churn_rate_pct,
    
    -- Average MRR of churned customers
    ROUND(churned_mrr / NULLIF(churned_customers, 0), 2) AS avg_churned_customer_mrr
    
FROM monthly_cohorts
WHERE snapshot_date >= '2021-02-01' 
ORDER BY snapshot_date;

-- Gross Churn Rate 
SELECT 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churned THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN churned THEN 1 ELSE 0 END) / COUNT(*), 2) AS gross_churn_rate_pct,
    
    SUM(monthly_charges) AS total_mrr,
    SUM(CASE WHEN churned THEN monthly_charges ELSE 0 END) AS churned_mrr,
    ROUND(100.0 * SUM(CASE WHEN churned THEN monthly_charges ELSE 0 END) / SUM(monthly_charges), 2) AS revenue_churn_rate_pct
FROM analytics.fact_subscription;

-- Churn Rate by Contract Type
SELECT 
    c.contract_type,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN f.churned THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN f.churned THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(f.tenure_months), 1) AS avg_tenure_months,
    ROUND(AVG(f.monthly_charges), 2) AS avg_monthly_charges
FROM analytics.fact_subscription f
INNER JOIN analytics.dim_contract c ON f.contract_key = c.contract_key
GROUP BY c.contract_type
ORDER BY churn_rate_pct DESC;

-- Churn Rate by Service Bundle Tier
SELECT 
    s.service_bundle_tier,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN f.churned THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN f.churned THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(s.total_addon_services), 1) AS avg_addons,
    ROUND(AVG(f.monthly_charges), 2) AS avg_monthly_charges
FROM analytics.fact_subscription f
INNER JOIN analytics.dim_service s ON f.service_key = s.service_key
GROUP BY s.service_bundle_tier
ORDER BY churn_rate_pct DESC;

-- Churn Rate by Demographics
SELECT 
    d.is_senior_citizen,
    d.has_partner,
    d.has_dependents,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN f.churned THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN f.churned THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct
FROM analytics.fact_subscription f
INNER JOIN analytics.dim_customer d ON f.customer_key = d.customer_key
GROUP BY d.is_senior_citizen, d.has_partner, d.has_dependents
ORDER BY churn_rate_pct DESC;

-- Time-to-Churn Distribution
SELECT 
    tenure_bracket,
    COUNT(*) AS churned_customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_churned,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
    ROUND(AVG(total_charges), 2) AS avg_total_charges
FROM (
    SELECT 
        CASE 
            WHEN tenure_months <= 3 THEN '0-3 months'
            WHEN tenure_months <= 6 THEN '4-6 months'
            WHEN tenure_months <= 12 THEN '7-12 months'
            WHEN tenure_months <= 24 THEN '13-24 months'
            ELSE '24+ months'
        END AS tenure_bracket,
        CASE 
            WHEN tenure_months <= 3 THEN 1
            WHEN tenure_months <= 6 THEN 2
            WHEN tenure_months <= 12 THEN 3
            WHEN tenure_months <= 24 THEN 4
            ELSE 5
        END AS sort_order,
        monthly_charges,
        total_charges
    FROM analytics.fact_subscription
    WHERE churned = TRUE
) churned_with_brackets
GROUP BY tenure_bracket, sort_order
ORDER BY sort_order;

-- Churn Risk Segmentation
SELECT 
    CASE 
        WHEN con.contract_type = 'Month-to-month' 
            AND f.tenure_months <= 6 
            AND svc.service_bundle_tier = 'Basic' 
        THEN 'High Risk'
        
        WHEN con.contract_type = 'Month-to-month' 
            OR f.tenure_months <= 6 
            OR svc.service_bundle_tier = 'Basic'
        THEN 'Medium Risk'
        
        ELSE 'Low Risk'
    END AS risk_segment,
    
    COUNT(*) AS total_customers,
    SUM(CASE WHEN f.churned THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN f.churned THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(SUM(f.monthly_charges), 2) AS total_mrr,
    ROUND(AVG(f.tenure_months), 1) AS avg_tenure
    
FROM analytics.fact_subscription f
INNER JOIN analytics.dim_contract con ON f.contract_key = con.contract_key
INNER JOIN analytics.dim_service svc ON f.service_key = svc.service_key
GROUP BY risk_segment
ORDER BY churn_rate_pct DESC;
