# DAX measures for Segment Dashboard

## SEGMENT METRICS

### Customers by Segment
```
Customers by Segment = 
CALCULATE(
    DISTINCTCOUNT(fact_subscription[customer_id]),
    fact_subscription[is_active] = TRUE
)
```

### MRR by Segment
```
MRR by Segment = 
CALCULATE(
    SUM(fact_subscription[monthly_charges]),
    fact_subscription[is_active] = TRUE
)
```

### Pct of Customer Base
```
Pct of Customer Base = 
DIVIDE(
    [Customers by Segment],
    [Active Customers],
    0
)
```

### Pct of MRR
```
Pct of MRR = 
DIVIDE(
    [MRR by Segment],
    [Total MRR],
    0
)
```

### Segment ARPU 
```
Segment ARPU = 
DIVIDE(
    [MRR by Segment],
    [Customers by Segment],
    0
)
```

## LTV CALCULATION

### Avg Tenure (Churned)
```
Avg Tenure (Churned) = 
CALCULATE(
    AVERAGE(fact_subscription[tenure_months]),
    fact_subscription[churned] = TRUE
)
```

### Segment LTV (Predictive)
```
Segment LTV (Predictive) = 
VAR SegmentARPU = [Segment ARPU]
VAR SegmentChurnRate = [Segment Churn Rate]
RETURN
    DIVIDE(
        SegmentARPU,
        SegmentChurnRate,
        0
    )
```

### Segment LTV (Historical)
```
Segment LTV (Historical) = 
CALCULATE(
    AVERAGE(fact_subscription[total_charges]),
    fact_subscription[churned] = TRUE
)
```

## MIX ANALYSIS

### Pct Month-to-Month
```
Pct Month-to-Month = 
CALCULATE(
    [Pct of Customer Base],
    dim_contract[contract_type] = "Month-to-month"
)
```

### Pct Annual+
```
Pct Annual+ = 
CALCULATE(
    [Pct of Customer Base],
    dim_contract[contract_type] IN {"One year", "Two year"}
)
```

### Pct Premium Tier
```
Pct Premium Tier = 
CALCULATE(
    [Pct of Customer Base],
    dim_service[service_bundle_tier] = "Premium"
)
```

### MRR from Premium
```
MRR from Premium = 
CALCULATE(
    [MRR by Segment],
    dim_service[service_bundle_tier] = "Premium"
)
```

## CUSTOMER VALUE TIERS

### High Value Customers
```
High Value Customers = 
CALCULATE(
    DISTINCTCOUNT(fact_subscription[customer_id]),
    fact_subscription[monthly_charges] >= 80,
    fact_subscription[is_active] = TRUE
)
```

### Medium Value Customers
```
Medium Value Customers = 
CALCULATE(
    DISTINCTCOUNT(fact_subscription[customer_id]),
    fact_subscription[monthly_charges] >= 40,
    fact_subscription[monthly_charges] < 80,
    fact_subscription[is_active] = TRUE
)
```

### Low Value Customers
```
Low Value Customers = 
CALCULATE(
    DISTINCTCOUNT(fact_subscription[customer_id]),
    fact_subscription[monthly_charges] < 40,
    fact_subscription[is_active] = TRUE
)
```

### Pct High Value
```
Pct High Value = 
DIVIDE([High Value Customers], [Active Customers], 0)

MRR from High Value = 
CALCULATE(
    SUM(fact_subscription[monthly_charges]),
    fact_subscription[monthly_charges] >= 80,
    fact_subscription[is_active] = TRUE
)
```