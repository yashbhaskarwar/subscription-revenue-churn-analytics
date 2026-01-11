-- Load Dimension Tables from Staging

-- dim_customer: Customer Demographics
TRUNCATE TABLE analytics.dim_customer CASCADE;

INSERT INTO analytics.dim_customer (
    customer_id,
    gender,
    is_senior_citizen,
    has_partner,
    has_dependents
)
SELECT DISTINCT
    customer_id,
    gender,
    CASE WHEN senior_citizen = 1 THEN TRUE ELSE FALSE END AS is_senior_citizen,
    CASE WHEN partner = 'Yes' THEN TRUE ELSE FALSE END AS has_partner,
    CASE WHEN dependents = 'Yes' THEN TRUE ELSE FALSE END AS has_dependents
FROM staging.telco_customer_raw;

-- Validate
SELECT COUNT(*) AS customer_count FROM analytics.dim_customer;

-- dim_service: Service Configuration & Bundles
TRUNCATE TABLE analytics.dim_service CASCADE;

INSERT INTO analytics.dim_service (
    customer_id,
    has_phone_service,
    phone_service_type,
    internet_service_type,
    has_online_security,
    has_online_backup,
    has_device_protection,
    has_tech_support,
    has_streaming_tv,
    has_streaming_movies,
    total_addon_services,
    service_bundle_tier
)
SELECT 
    customer_id,
    
    -- Phone Service
    CASE WHEN phone_service = 'Yes' THEN TRUE ELSE FALSE END AS has_phone_service,
    CASE 
        WHEN phone_service = 'No' THEN 'None'
        WHEN multiple_lines = 'Yes' THEN 'Multiple lines'
        WHEN multiple_lines = 'No' THEN 'Single line'
        ELSE 'Single line'
    END AS phone_service_type,
    
    -- Internet Service
    CASE 
        WHEN internet_service IN ('DSL', 'Fiber optic') THEN internet_service
        ELSE 'None'
    END AS internet_service_type,
    
    -- Add-on Services (only available with internet)
    CASE 
        WHEN online_security = 'Yes' THEN TRUE 
        ELSE FALSE 
    END AS has_online_security,
    CASE 
        WHEN online_backup = 'Yes' THEN TRUE 
        ELSE FALSE 
    END AS has_online_backup,
    CASE 
        WHEN device_protection = 'Yes' THEN TRUE 
        ELSE FALSE 
    END AS has_device_protection,
    CASE 
        WHEN tech_support = 'Yes' THEN TRUE 
        ELSE FALSE 
    END AS has_tech_support,
    CASE 
        WHEN streaming_tv = 'Yes' THEN TRUE 
        ELSE FALSE 
    END AS has_streaming_tv,
    CASE 
        WHEN streaming_movies = 'Yes' THEN TRUE 
        ELSE FALSE 
    END AS has_streaming_movies,
    
    -- Calculate total add-ons
    (CASE WHEN online_security = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN online_backup = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN device_protection = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN tech_support = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN streaming_tv = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN streaming_movies = 'Yes' THEN 1 ELSE 0 END
    ) AS total_addon_services,
    
    -- Derive service tier
    CASE 
        WHEN (CASE WHEN online_security = 'Yes' THEN 1 ELSE 0 END +
              CASE WHEN online_backup = 'Yes' THEN 1 ELSE 0 END +
              CASE WHEN device_protection = 'Yes' THEN 1 ELSE 0 END +
              CASE WHEN tech_support = 'Yes' THEN 1 ELSE 0 END +
              CASE WHEN streaming_tv = 'Yes' THEN 1 ELSE 0 END +
              CASE WHEN streaming_movies = 'Yes' THEN 1 ELSE 0 END
             ) >= 5 THEN 'Premium'
        WHEN (CASE WHEN online_security = 'Yes' THEN 1 ELSE 0 END +
              CASE WHEN online_backup = 'Yes' THEN 1 ELSE 0 END +
              CASE WHEN device_protection = 'Yes' THEN 1 ELSE 0 END +
              CASE WHEN tech_support = 'Yes' THEN 1 ELSE 0 END +
              CASE WHEN streaming_tv = 'Yes' THEN 1 ELSE 0 END +
              CASE WHEN streaming_movies = 'Yes' THEN 1 ELSE 0 END
             ) >= 3 THEN 'Standard'
        ELSE 'Basic'
    END AS service_bundle_tier
    
FROM staging.telco_customer_raw;

-- Validate
SELECT 
    service_bundle_tier,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_addon_services), 2) AS avg_addons
FROM analytics.dim_service
GROUP BY service_bundle_tier
ORDER BY service_bundle_tier;

-- dim_contract: Contract Terms & Billing
TRUNCATE TABLE analytics.dim_contract CASCADE;

INSERT INTO analytics.dim_contract (
    customer_id,
    contract_type,
    paperless_billing,
    payment_method
)
SELECT DISTINCT
    customer_id,
    contract AS contract_type,
    CASE WHEN paperless_billing = 'Yes' THEN TRUE ELSE FALSE END AS paperless_billing,
    payment_method
FROM staging.telco_customer_raw;

-- Validate
SELECT 
    contract_type,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM analytics.dim_contract
GROUP BY contract_type
ORDER BY customer_count DESC;
