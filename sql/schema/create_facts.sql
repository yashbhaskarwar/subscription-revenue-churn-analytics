-- Fact Tables

DROP TABLE IF EXISTS analytics.fact_subscription CASCADE;

CREATE TABLE analytics.fact_subscription (
    subscription_key SERIAL PRIMARY KEY,
    customer_key INTEGER REFERENCES analytics.dim_customer(customer_key),
    service_key INTEGER REFERENCES analytics.dim_service(service_key),
    contract_key INTEGER REFERENCES analytics.dim_contract(contract_key),
    
    -- Business Keys
    customer_id VARCHAR(20) NOT NULL,
    
    -- Subscription Period
    subscription_start_date DATE NOT NULL,
    subscription_end_date DATE, 
    
    -- Tenure Metrics
    tenure_months INTEGER,
    is_active BOOLEAN,
    churned BOOLEAN,
    
    -- Financial Metrics
    monthly_charges DECIMAL(10,2),
    total_charges DECIMAL(10,2),
    
    -- Cohort Assignment
    cohort_month DATE, 
    cohort_year_month VARCHAR(7), 
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fact_sub_customer ON analytics.fact_subscription(customer_key);
CREATE INDEX idx_fact_sub_dates ON analytics.fact_subscription(subscription_start_date, subscription_end_date);
CREATE INDEX idx_fact_sub_cohort ON analytics.fact_subscription(cohort_month);
CREATE INDEX idx_fact_sub_active ON analytics.fact_subscription(is_active) WHERE is_active = TRUE;

-- Fact: Monthly Subscription Snapshot
DROP TABLE IF EXISTS analytics.fact_subscription_monthly_snapshot CASCADE;

CREATE TABLE analytics.fact_subscription_monthly_snapshot (
    snapshot_key SERIAL PRIMARY KEY,
    snapshot_date DATE NOT NULL, 
    snapshot_month_key INTEGER REFERENCES analytics.dim_date(date_key),
    
    customer_key INTEGER REFERENCES analytics.dim_customer(customer_key),
    service_key INTEGER REFERENCES analytics.dim_service(service_key),
    contract_key INTEGER REFERENCES analytics.dim_contract(contract_key),
    
    -- Business Keys
    customer_id VARCHAR(20) NOT NULL,
    
    -- Snapshot Metrics
    is_active BOOLEAN,
    months_since_start INTEGER,
    monthly_charges DECIMAL(10,2),
    
    -- Cohort Context
    cohort_month DATE,
    cohort_age_months INTEGER, 
    
    -- Period Flags
    is_new_customer BOOLEAN, 
    is_churn_month BOOLEAN,  
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(customer_id, snapshot_date)
);

CREATE INDEX idx_snapshot_date ON analytics.fact_subscription_monthly_snapshot(snapshot_date);
CREATE INDEX idx_snapshot_customer ON analytics.fact_subscription_monthly_snapshot(customer_key);
CREATE INDEX idx_snapshot_cohort ON analytics.fact_subscription_monthly_snapshot(cohort_month, cohort_age_months);
CREATE INDEX idx_snapshot_active ON analytics.fact_subscription_monthly_snapshot(is_active, snapshot_date);
CREATE INDEX idx_snapshot_active ON analytics.fact_subscription_monthly_snapshot(is_active, snapshot_date);