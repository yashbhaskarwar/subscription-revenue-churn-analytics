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
