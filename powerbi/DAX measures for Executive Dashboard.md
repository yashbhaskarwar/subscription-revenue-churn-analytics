# DAX measures fo Executive Dashboard

## CORE METRICS

### MRR
```
Total MRR = 
CALCULATE(
    SUM(fact_subscription_monthly_snapshot[monthly_charges]),
    fact_subscription_monthly_snapshot[is_active] = TRUE
)
```

### Active Customers
```
Active Customers = 
CALCULATE(
    DISTINCTCOUNT(fact_subscription_monthly_snapshot[customer_id]),
    fact_subscription_monthly_snapshot[is_active] = TRUE
)
```

### ARPU
```
ARPU = 
DIVIDE(
    [Total MRR],
    [Active Customers],
    0
)
```

### Logu Churn Rate
```
Logo Churn Rate = 
VAR ChurnedCustomers = 
    CALCULATE(
        DISTINCTCOUNT(fact_subscription_monthly_snapshot[customer_id]),
        fact_subscription_monthly_snapshot[is_churn_month] = TRUE
    )
VAR StartingCustomers = [Active Customers]
RETURN
    DIVIDE(ChurnedCustomers, StartingCustomers, 0)
```

### Revenue Churn Rate
```
Revenue Churn Rate = 
VAR ChurnedMRR = 
    CALCULATE(
        SUM(fact_subscription_monthly_snapshot[monthly_charges]),
        fact_subscription_monthly_snapshot[is_churn_month] = TRUE
    )
VAR StartingMRR = [Total MRR]
RETURN
    DIVIDE(ChurnedMRR, StartingMRR, 0)
```
