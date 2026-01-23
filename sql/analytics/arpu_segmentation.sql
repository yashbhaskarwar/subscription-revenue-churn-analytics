-- ARPU and Customer Segmentation Analysis

-- Monthly ARPU Trend
SELECT 
    TO_CHAR(snapshot_date, 'YYYY-MM') AS month,
    COUNT(DISTINCT customer_id) AS active_customers,
    ROUND(SUM(monthly_charges), 2) AS total_mrr,
    ROUND(AVG(monthly_charges), 2) AS arpu,
    
    -- ARPU by new vs existing
    ROUND(AVG(CASE WHEN is_new_customer THEN monthly_charges END), 2) AS arpu_new_customers,
    ROUND(AVG(CASE WHEN NOT is_new_customer THEN monthly_charges END), 2) AS arpu_existing_customers
    
FROM analytics.fact_subscription_monthly_snapshot
GROUP BY snapshot_date
ORDER BY snapshot_date;

-- ARPU by Segment Dimensions
SELECT 
    c.contract_type,
    s.service_bundle_tier,
    COUNT(DISTINCT f.customer_id) AS customers,
    ROUND(AVG(f.monthly_charges), 2) AS arpu,
    ROUND(SUM(f.monthly_charges), 2) AS total_mrr,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customer_base
FROM analytics.fact_subscription f
INNER JOIN analytics.dim_contract c ON f.contract_key = c.contract_key
INNER JOIN analytics.dim_service s ON f.service_key = s.service_key
WHERE f.is_active = TRUE
GROUP BY c.contract_type, s.service_bundle_tier
ORDER BY total_mrr DESC;

-- Customer Segmentation: RFM-Style Analysis
WITH customer_segments AS (
    SELECT 
        customer_id,
        tenure_months,
        monthly_charges,
        is_active,
        
        -- Tenure segment
        CASE 
            WHEN tenure_months <= 6 THEN 'New (0-6mo)'
            WHEN tenure_months <= 24 THEN 'Established (7-24mo)'
            ELSE 'Veteran (24mo+)'
        END AS tenure_segment,
        
        -- Revenue tier
        CASE 
            WHEN monthly_charges < 30 THEN 'Budget (<$30)'
            WHEN monthly_charges < 70 THEN 'Standard ($30-70)'
            ELSE 'Premium ($70+)'
        END AS revenue_tier
        
    FROM analytics.fact_subscription
)
SELECT 
    tenure_segment,
    revenue_tier,
    COUNT(*) AS customers,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_customers,
    ROUND(100.0 * SUM(CASE WHEN is_active THEN 1 ELSE 0 END) / COUNT(*), 2) AS retention_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_arpu,
    ROUND(SUM(monthly_charges), 2) AS total_mrr
FROM customer_segments
GROUP BY tenure_segment, revenue_tier
ORDER BY total_mrr DESC;

-- High-Value Customer Analysis
WITH customer_revenue_rank AS (
    SELECT 
        customer_id,
        monthly_charges,
        is_active,
        churned,
        tenure_months,
        NTILE(5) OVER (ORDER BY monthly_charges DESC) AS revenue_quintile
    FROM analytics.fact_subscription
)
SELECT 
    CASE 
        WHEN revenue_quintile = 1 THEN 'Top 20% (High Value)'
        WHEN revenue_quintile = 2 THEN 'Next 20%'
        WHEN revenue_quintile = 3 THEN 'Middle 20%'
        WHEN revenue_quintile = 4 THEN 'Next 20%'
        ELSE 'Bottom 20%'
    END AS customer_segment,
    
    COUNT(*) AS customers,
    ROUND(SUM(monthly_charges), 2) AS total_mrr,
    ROUND(100.0 * SUM(monthly_charges) / SUM(SUM(monthly_charges)) OVER (), 2) AS pct_of_total_mrr,
    ROUND(AVG(monthly_charges), 2) AS avg_arpu,
    ROUND(100.0 * SUM(CASE WHEN churned THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(tenure_months), 1) AS avg_tenure_months
    
FROM customer_revenue_rank
GROUP BY revenue_quintile
ORDER BY revenue_quintile;