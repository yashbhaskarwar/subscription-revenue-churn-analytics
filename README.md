# Revenue Retention and Churn Analytics

Subscription business analytics project focused on revenue health, customer retention, churn and cohort analysis using SQL and dimensional modeling.

## Tech Stack
- PostgreSQL
- SQL 
- Power BI
- Star schema data model

## Key Features
- Monthly subscription snapshots enabling point-in-time analysis
- Cohort-based retention tracking
- Multi-dimensional churn analysis
- Predictive LTV modeling
- Executive KPI dashboards

## Data Model
The analytics layer follows a star schema optimized for business intelligence queries and dashboard performance.

### Fact Tables
- `fact_subscription` - Customer subscription lifecycle
- `fact_subscription_monthly_snapshot` - Monthly point-in-time subscriber state

### Dimension Tables
- `dim_customer` - Customer demographics
- `dim_service` - Service configurations and bundle tiers
- `dim_contract` - Contract terms and billing details
- `dim_date` - Time dimension for temporal analysis

## Project Structure
```
subscription-revenue-churn-analytics/
│
├── README.md                          
│
├── sql/
│   ├── schema/                     
│   │   ├── create_staging.sql
│   │   ├── create_dimensions.sql
│   │   └── create_facts.sql
│   │
│   ├── transformations/            
│   │   ├── populate_dim_date.sql
│   │   ├── load_dimensions.sql
│   │   ├── load_fact_subscriptions.sql
│   │   └── build_subscription_snapshots.sql
│   │
│   └── analytics/                 
│       ├── mrr_analysis.sql
│       ├── churn_metrics.sql
│       ├── cohort_analysis.sql
│       ├── customer_ltv.sql
│       ├── net_revenue_retention.sql
│       └── arpu_segmentation.sql
│
└── powerbi/
    ├── DAX measure for Executive Dashbaord.md
    ├── DAX measure for Retention Dashboard.md
    └── DAX measure for Segment dashboard.md      
```

## How to run

### Database Setup

1. Create database and schemas
```sql
CREATE DATABASE subscription_analytics;
\c subscription_analytics;
CREATE SCHEMA staging;
CREATE SCHEMA analytics;
```

2. Run schema creation scripts
```bash
psql -d subscription_analytics -f sql/schema/create_staging.sql
psql -d subscription_analytics -f sql/schema/create_dimensions.sql
psql -d subscription_analytics -f sql/schema/create_facts.sql
```

3. Load source data into staging
```sql
COPY staging.telco_customer_raw 
FROM '/path/to/Telco Customer Churn.csv'    -- Update Datset path
DELIMITER ',' 
CSV HEADER;
```

4. Run transformations
```bash
psql -d subscription_analytics -f sql/transformations/populate_dim_date.sql
psql -d subscription_analytics -f sql/transformations/load_dimensions.sql
psql -d subscription_analytics -f sql/transformations/load_fact_subscriptions.sql
psql -d subscription_analytics -f sql/transformations/build_subscription_snapshots.sql
```

5. Validate data load
```sql
-- Check record counts
SELECT 'fact_subscription' AS table_name, COUNT(*) FROM analytics.fact_subscription
UNION ALL
SELECT 'fact_subscription_monthly_snapshot', COUNT(*) FROM analytics.fact_subscription_monthly_snapshot
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM analytics.dim_customer;
```

### Analytics Queries

1. MRR Analysis
```sql
bashpsql -d subscription_analytics -f sql/analytics/mrr_analysis.sql
```

2. Churn Metrics
```sql
bashpsql -d subscription_analytics -f sql/analytics/churn_metrics.sql
```

3. Cohort Analysis
```sql
bashpsql -d subscription_analytics -f sql/analytics/cohort_analysis.sql
```

4. Customer Lifetime Value
```sql
bashpsql -d subscription_analytics -f sql/analytics/customer_ltv.sql
```

5. Net Revenue Retention
```sql
bashpsql -d subscription_analytics -f sql/analytics/net_revenue_retention.sql
```

6. ARPU & Segmentation
```sql
bashpsql -d subscription_analytics -f sql/analytics/arpu_segmentation.sql
```

## Power BI Dashboards

1. Executive Overview
- MRR trend with month-over-month growth
- Active customer count and net change
- Churn rate trends 
- ARPU evolution
- Key performance indicators with targets

2. Retention & Cohort Analysis
- Cohort retention heatmap
- Revenue retention curves
- Time-to-churn distribution
- Churn rate by segment
- Cohort quality comparison

3. Plan & Segment Performance
- MRR mix by contract type and service tier
- Customer distribution across segments
- Segment-level churn rates
- ARPU by customer segment
- High-value customer analysis
