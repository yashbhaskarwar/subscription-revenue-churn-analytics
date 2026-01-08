-- Dimension Tables

DROP TABLE IF EXISTS analytics.dim_customer CASCADE;

CREATE TABLE analytics.dim_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) UNIQUE NOT NULL,
    gender VARCHAR(10),
    is_senior_citizen BOOLEAN,
    has_partner BOOLEAN,
    has_dependents BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_customer_id ON analytics.dim_customer(customer_id);

-- Dimension: Service Configuration
DROP TABLE IF EXISTS analytics.dim_service CASCADE;

CREATE TABLE analytics.dim_service (
    service_key SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    
    -- Core Services
    has_phone_service BOOLEAN,
    phone_service_type VARCHAR(20), 
    internet_service_type VARCHAR(20),
    
    -- Add-on Services
    has_online_security BOOLEAN,
    has_online_backup BOOLEAN,
    has_device_protection BOOLEAN,
    has_tech_support BOOLEAN,
    has_streaming_tv BOOLEAN,
    has_streaming_movies BOOLEAN,
    
    -- Derived Metrics
    total_addon_services INTEGER,
    service_bundle_tier VARCHAR(20), 
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_service_customer ON analytics.dim_service(customer_id);

-- Dimension: Contract Details
DROP TABLE IF EXISTS analytics.dim_contract CASCADE;

CREATE TABLE analytics.dim_contract (
    contract_key SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    contract_type VARCHAR(20), 
    paperless_billing BOOLEAN,
    payment_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_contract_customer ON analytics.dim_contract(customer_id);

-- Dimension: Date
DROP TABLE IF EXISTS analytics.dim_date CASCADE;

CREATE TABLE analytics.dim_date (
    date_key INTEGER PRIMARY KEY, 
    full_date DATE NOT NULL UNIQUE,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    month_name VARCHAR(10),
    week_of_year INTEGER,
    day_of_month INTEGER,
    day_of_week INTEGER,
    day_name VARCHAR(10),
    is_weekend BOOLEAN,
    fiscal_year INTEGER,
    fiscal_quarter INTEGER
);

CREATE INDEX idx_dim_date_full ON analytics.dim_date(full_date);
CREATE INDEX idx_dim_date_ym ON analytics.dim_date(year, month);