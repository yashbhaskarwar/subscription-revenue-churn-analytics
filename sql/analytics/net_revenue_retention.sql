-- Net Revenue Retention (NRR) Analysis

-- Monthly NRR Calculation
WITH monthly_starting_mrr AS (
    SELECT 
        snapshot_date,
        customer_id,
        monthly_charges,
        LAG(snapshot_date) OVER (PARTITION BY customer_id ORDER BY snapshot_date) AS prior_month,
        LAG(monthly_charges) OVER (PARTITION BY customer_id ORDER BY snapshot_date) AS prior_mrr
    FROM analytics.fact_subscription_monthly_snapshot
),
revenue_movements AS (
    SELECT 
        snapshot_date,
        
        -- Starting MRR 
        SUM(CASE WHEN prior_month IS NOT NULL THEN prior_mrr ELSE 0 END) AS starting_mrr,
        
        -- Expansion 
        SUM(
            CASE 
                WHEN prior_month IS NOT NULL 
                    AND monthly_charges > prior_mrr 
                THEN monthly_charges - prior_mrr 
                ELSE 0 
            END
        ) AS expansion_mrr,
        
        -- Contraction 
        SUM(
            CASE 
                WHEN prior_month IS NOT NULL 
                    AND monthly_charges < prior_mrr 
                THEN prior_mrr - monthly_charges 
                ELSE 0 
            END
        ) AS contraction_mrr,
        
        -- Ending MRR from cohort
        SUM(CASE WHEN prior_month IS NOT NULL THEN monthly_charges ELSE 0 END) AS ending_mrr
        
    FROM monthly_starting_mrr
    WHERE prior_month IS NOT NULL 
    GROUP BY snapshot_date
)
SELECT 
    TO_CHAR(snapshot_date, 'YYYY-MM') AS month,
    ROUND(starting_mrr, 2) AS starting_mrr,
    ROUND(expansion_mrr, 2) AS expansion_mrr,
    ROUND(contraction_mrr, 2) AS contraction_mrr,
    ROUND(starting_mrr - ending_mrr, 2) AS churned_mrr,
    ROUND(ending_mrr, 2) AS ending_mrr,
    
    -- Net Revenue Retention %
    ROUND(100.0 * ending_mrr / NULLIF(starting_mrr, 0), 2) AS nrr_pct,
    
    -- Gross Revenue Retention 
    ROUND(100.0 * (ending_mrr - expansion_mrr) / NULLIF(starting_mrr, 0), 2) AS grr_pct
    
FROM revenue_movements
WHERE snapshot_date >= '2021-02-01' 
ORDER BY snapshot_date;

-- Cohort-Based NRR (12-Month View)
WITH cohort_mrr_timeline AS (
    SELECT 
        cohort_month,
        cohort_age_months,
        SUM(monthly_charges) AS cohort_mrr
    FROM analytics.fact_subscription_monthly_snapshot
    WHERE cohort_age_months <= 12
    GROUP BY cohort_month, cohort_age_months
),
cohort_starting_mrr AS (
    SELECT 
        cohort_month,
        cohort_mrr AS starting_mrr
    FROM cohort_mrr_timeline
    WHERE cohort_age_months = 0
)
SELECT 
    TO_CHAR(cmt.cohort_month, 'YYYY-MM') AS cohort,
    cmt.cohort_age_months AS month,
    ROUND(csm.starting_mrr, 2) AS starting_mrr,
    ROUND(cmt.cohort_mrr, 2) AS current_mrr,
    ROUND(100.0 * cmt.cohort_mrr / csm.starting_mrr, 2) AS revenue_retention_pct
FROM cohort_mrr_timeline cmt
INNER JOIN cohort_starting_mrr csm ON cmt.cohort_month = csm.cohort_month
WHERE cmt.cohort_month >= '2021-01-01'
ORDER BY cmt.cohort_month, cmt.cohort_age_months;

-- NRR by Contract Type
WITH contract_revenue_retention AS (
    SELECT 
        c.contract_type,
        f.customer_id,
        MAX(f.monthly_charges) AS starting_mrr,
        MAX(CASE WHEN f.is_active THEN f.monthly_charges ELSE 0 END) AS current_mrr
    FROM analytics.fact_subscription f
    INNER JOIN analytics.dim_contract c ON f.contract_key = c.contract_key
    GROUP BY c.contract_type, f.customer_id
)
SELECT 
    contract_type,
    COUNT(*) AS customers,
    ROUND(SUM(starting_mrr), 2) AS total_starting_mrr,
    ROUND(SUM(current_mrr), 2) AS total_current_mrr,
    ROUND(100.0 * SUM(current_mrr) / NULLIF(SUM(starting_mrr), 0), 2) AS nrr_pct
FROM contract_revenue_retention
GROUP BY contract_type
ORDER BY nrr_pct DESC;