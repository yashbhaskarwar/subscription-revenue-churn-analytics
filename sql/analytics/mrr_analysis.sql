-- Monthly Recurring Revenue (MRR) Analysis

-- MRR Trend with Month-over-Month Growth
WITH monthly_mrr AS (
    SELECT 
        snapshot_date,
        COUNT(DISTINCT customer_id) AS active_customers,
        SUM(monthly_charges) AS total_mrr,
        SUM(CASE WHEN is_new_customer THEN monthly_charges ELSE 0 END) AS new_mrr,
        SUM(CASE WHEN is_churn_month THEN monthly_charges ELSE 0 END) AS churned_mrr
    FROM analytics.fact_subscription_monthly_snapshot
    GROUP BY snapshot_date
),
mrr_with_growth AS (
    SELECT 
        snapshot_date,
        active_customers,
        ROUND(total_mrr, 2) AS total_mrr,
        ROUND(new_mrr, 2) AS new_mrr,
        ROUND(churned_mrr, 2) AS churned_mrr,
        
        -- Month-over-month changes
        ROUND(total_mrr - LAG(total_mrr) OVER (ORDER BY snapshot_date), 2) AS mrr_change,
        ROUND(
            100.0 * (total_mrr - LAG(total_mrr) OVER (ORDER BY snapshot_date)) / 
            NULLIF(LAG(total_mrr) OVER (ORDER BY snapshot_date), 0), 
            2
        ) AS mrr_growth_pct,
        
        -- Customer changes
        active_customers - LAG(active_customers) OVER (ORDER BY snapshot_date) AS net_customer_change
        
    FROM monthly_mrr
)
SELECT 
    TO_CHAR(snapshot_date, 'YYYY-MM') AS month,
    active_customers,
    total_mrr,
    new_mrr,
    churned_mrr,
    mrr_change,
    mrr_growth_pct,
    net_customer_change
FROM mrr_with_growth
ORDER BY snapshot_date;

-- MRR Waterfall: New, Expansion, Contraction, Churn

WITH customer_monthly_mrr AS (
    SELECT 
        customer_id,
        snapshot_date,
        monthly_charges AS current_mrr,
        LAG(monthly_charges) OVER (PARTITION BY customer_id ORDER BY snapshot_date) AS prior_mrr,
        is_new_customer,
        is_churn_month
    FROM analytics.fact_subscription_monthly_snapshot
),
mrr_movements AS (
    SELECT 
        snapshot_date,
        
        -- New MRR
        SUM(CASE WHEN is_new_customer THEN current_mrr ELSE 0 END) AS new_mrr,
        
        -- Expansion MRR 
        SUM(
            CASE 
                WHEN NOT is_new_customer 
                    AND prior_mrr IS NOT NULL 
                    AND current_mrr > prior_mrr 
                THEN current_mrr - prior_mrr 
                ELSE 0 
            END
        ) AS expansion_mrr,
        
        -- Contraction MRR 
        SUM(
            CASE 
                WHEN prior_mrr IS NOT NULL 
                    AND current_mrr < prior_mrr 
                    AND NOT is_churn_month
                THEN prior_mrr - current_mrr 
                ELSE 0 
            END
        ) AS contraction_mrr,
        
        -- Churned MRR
        SUM(CASE WHEN is_churn_month THEN current_mrr ELSE 0 END) AS churned_mrr,
        
        -- Total MRR
        SUM(current_mrr) AS total_mrr
        
    FROM customer_monthly_mrr
    GROUP BY snapshot_date
)
SELECT 
    TO_CHAR(snapshot_date, 'YYYY-MM') AS month,
    ROUND(total_mrr, 2) AS ending_mrr,
    ROUND(new_mrr, 2) AS new_mrr,
    ROUND(expansion_mrr, 2) AS expansion_mrr,
    ROUND(contraction_mrr, 2) AS contraction_mrr,
    ROUND(churned_mrr, 2) AS churned_mrr,
    ROUND(new_mrr - churned_mrr, 2) AS net_new_mrr
FROM mrr_movements
ORDER BY snapshot_date;

-- MRR by Contract Type
SELECT 
    s.snapshot_date,
    TO_CHAR(s.snapshot_date, 'YYYY-MM') AS month,
    c.contract_type,
    COUNT(DISTINCT s.customer_id) AS customers,
    ROUND(SUM(s.monthly_charges), 2) AS total_mrr,
    ROUND(AVG(s.monthly_charges), 2) AS avg_mrr_per_customer
FROM analytics.fact_subscription_monthly_snapshot s
INNER JOIN analytics.dim_contract c ON s.contract_key = c.contract_key
GROUP BY s.snapshot_date, c.contract_type
ORDER BY s.snapshot_date, c.contract_type;

-- MRR by Service Bundle Tier
SELECT 
    s.snapshot_date,
    TO_CHAR(s.snapshot_date, 'YYYY-MM') AS month,
    svc.service_bundle_tier,
    COUNT(DISTINCT s.customer_id) AS customers,
    ROUND(SUM(s.monthly_charges), 2) AS total_mrr,
    ROUND(AVG(s.monthly_charges), 2) AS avg_mrr_per_customer,
    ROUND(100.0 * SUM(s.monthly_charges) / SUM(SUM(s.monthly_charges)) OVER (PARTITION BY s.snapshot_date), 2) AS mrr_mix_pct
FROM analytics.fact_subscription_monthly_snapshot s
INNER JOIN analytics.dim_service svc ON s.service_key = svc.service_key
GROUP BY s.snapshot_date, svc.service_bundle_tier
ORDER BY s.snapshot_date, svc.service_bundle_tier;
