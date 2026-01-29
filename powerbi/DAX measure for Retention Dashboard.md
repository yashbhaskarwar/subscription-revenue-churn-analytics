# DAX measures for Retention Dashboard

## COHORT METRICS

### Cohort Size
```
Cohort Size = 
CALCULATE(
    DISTINCTCOUNT(fact_subscription_monthly_snapshot[customer_id]),
    fact_subscription_monthly_snapshot[cohort_age_months] = 0
)
```

### Active in Cohort Month
```
Active in Cohort Month = 
DISTINCTCOUNT(fact_subscription_monthly_snapshot[customer_id])
```

### Cohort Retention Rate
```
Cohort Retention Rate = 
DIVIDE(
    [Active in Cohort Month],
    [Cohort Size],
    0
)
```

### Retention Months
```
Retention Month 0 = 
CALCULATE(
    [Cohort Retention Rate],
    fact_subscription_monthly_snapshot[cohort_age_months] = 0
)

Retention Month 1 = 
CALCULATE(
    [Cohort Retention Rate],
    fact_subscription_monthly_snapshot[cohort_age_months] = 1
)

Retention Month 3 = 
CALCULATE(
    [Cohort Retention Rate],
    fact_subscription_monthly_snapshot[cohort_age_months] = 3
)

Retention Month 6 = 
CALCULATE(
    [Cohort Retention Rate],
    fact_subscription_monthly_snapshot[cohort_age_months] = 6
)

Retention Month 12 = 
CALCULATE(
    [Cohort Retention Rate],
    fact_subscription_monthly_snapshot[cohort_age_months] = 12
)

Retention Month 24 = 
CALCULATE(
    [Cohort Retention Rate],
    fact_subscription_monthly_snapshot[cohort_age_months] = 24
)
```

## REVENUE RETENTION

### Cohort MRR
```
Cohort Starting MRR = 
CALCULATE(
    SUM(fact_subscription_monthly_snapshot[monthly_charges]),
    fact_subscription_monthly_snapshot[cohort_age_months] = 0
)

Cohort Current MRR = 
SUM(fact_subscription_monthly_snapshot[monthly_charges])
```

### Revenue Retention Rate
```
Revenue Retention Rate = 
DIVIDE(
    [Cohort Current MRR],
    [Cohort Starting MRR],
    0
)
```

## TIME TO CHURN

## Churned Customers
```
Churned Customers = 
CALCULATE(
    DISTINCTCOUNT(fact_subscription[customer_id]),
    fact_subscription[churned] = TRUE
)
```

### Churn Months
```
Churn in 0-3 Months = 
CALCULATE(
    [Churned Customers],
    fact_subscription[tenure_months] >= 0,
    fact_subscription[tenure_months] <= 3
)

Churn in 4-6 Months = 
CALCULATE(
    [Churned Customers],
    fact_subscription[tenure_months] >= 4,
    fact_subscription[tenure_months] <= 6
)

Churn in 7-12 Months = 
CALCULATE(
    [Churned Customers],
    fact_subscription[tenure_months] >= 7,
    fact_subscription[tenure_months] <= 12
)

Pct Early Churn (0-6mo) = 
DIVIDE(
    [Churn in 0-3 Months] + [Churn in 4-6 Months],
    [Churned Customers],
    0
)
```

## SEGMENT CHURN

### Segment Churn Rate
```
Segment Churn Rate = 
VAR TotalCustomers = DISTINCTCOUNT(fact_subscription[customer_id])
VAR ChurnedCustomers = 
    CALCULATE(
        DISTINCTCOUNT(fact_subscription[customer_id]),
        fact_subscription[churned] = TRUE
    )
RETURN
    DIVIDE(ChurnedCustomers, TotalCustomers, 0)
```