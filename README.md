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