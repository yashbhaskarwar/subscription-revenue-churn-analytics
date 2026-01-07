-- Staging Layer

DROP TABLE IF EXISTS staging.telco_customer_raw CASCADE;

CREATE TABLE staging.telco_customer_raw (
    customer_id VARCHAR(20) PRIMARY KEY,
    gender VARCHAR(10),
    senior_citizen INTEGER,
    partner VARCHAR(3),
    dependents VARCHAR(3),
    tenure INTEGER,
    phone_service VARCHAR(3),
    multiple_lines VARCHAR(50),
    internet_service VARCHAR(50),
    online_security VARCHAR(50),
    online_backup VARCHAR(50),
    device_protection VARCHAR(50),
    tech_support VARCHAR(50),
    streaming_tv VARCHAR(50),
    streaming_movies VARCHAR(50),
    contract VARCHAR(50),
    paperless_billing VARCHAR(3),
    payment_method VARCHAR(50),
    monthly_charges DECIMAL(10,2),
    total_charges VARCHAR(20), 
    churn VARCHAR(3),
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_staging_customer ON staging.telco_customer_raw(customer_id);