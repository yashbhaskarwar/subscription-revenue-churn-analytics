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

## TIME INTELLIGENCE

### MRR Last Month
```
MRR Last Month = 
CALCULATE(
    [Total MRR],
    DATEADD(dim_date[full_date], -1, MONTH)
)
```

### MRR Growth

```
MRR MoM Growth = [Total MRR] - [MRR Last Month]

MRR MoM Growth % = 
DIVIDE(
    [MRR MoM Growth],
    [MRR Last Month],
    0
)
```

### MRR 3M Average
```
MRR 3M Average = 
CALCULATE(
    [Total MRR],
    DATESINPERIOD(dim_date[full_date], LASTDATE(dim_date[full_date]), -3, MONTH)
) / 3
```

### Net Customer Change
```
Customers Last Month = 
CALCULATE(
    [Active Customers],
    DATEADD(dim_date[full_date], -1, MONTH)
)

Net Customer Change = [Active Customers] - [Customers Last Month]
```

## MRR WATERFALL COMPONENTS

### New MRR
```
New MRR = 
CALCULATE(
    SUM(fact_subscription_monthly_snapshot[monthly_charges]),
    fact_subscription_monthly_snapshot[is_new_customer] = TRUE
)
```

### Churned MRR
```
Churned MRR = 
CALCULATE(
    SUM(fact_subscription_monthly_snapshot[monthly_charges]),
    fact_subscription_monthly_snapshot[is_churn_month] = TRUE
)
```

### Expansion MRR
```
Expansion MRR = 
VAR CurrentMonth = MAX(dim_date[full_date])
VAR PriorMonth = EDATE(CurrentMonth, -1)
RETURN
SUMX(
    FILTER(
        fact_subscription_monthly_snapshot,
        fact_subscription_monthly_snapshot[snapshot_date] = CurrentMonth &&
        fact_subscription_monthly_snapshot[is_new_customer] = FALSE
    ),
    VAR CustomerID = fact_subscription_monthly_snapshot[customer_id]
    VAR CurrentMRR = fact_subscription_monthly_snapshot[monthly_charges]
    VAR PriorMRR = 
        CALCULATE(
            SUM(fact_subscription_monthly_snapshot[monthly_charges]),
            fact_subscription_monthly_snapshot[customer_id] = CustomerID,
            fact_subscription_monthly_snapshot[snapshot_date] = PriorMonth
        )
    RETURN
        IF(CurrentMRR > PriorMRR, CurrentMRR - PriorMRR, 0)
)
```

### Contraction MRR
```
Contraction MRR = 
VAR CurrentMonth = MAX(dim_date[full_date])
VAR PriorMonth = EDATE(CurrentMonth, -1)
RETURN
SUMX(
    FILTER(
        fact_subscription_monthly_snapshot,
        fact_subscription_monthly_snapshot[snapshot_date] = CurrentMonth &&
        fact_subscription_monthly_snapshot[is_churn_month] = FALSE
    ),
    VAR CustomerID = fact_subscription_monthly_snapshot[customer_id]
    VAR CurrentMRR = fact_subscription_monthly_snapshot[monthly_charges]
    VAR PriorMRR = 
        CALCULATE(
            SUM(fact_subscription_monthly_snapshot[monthly_charges]),
            fact_subscription_monthly_snapshot[customer_id] = CustomerID,
            fact_subscription_monthly_snapshot[snapshot_date] = PriorMonth
        )
    RETURN
        IF(CurrentMRR < PriorMRR, PriorMRR - CurrentMRR, 0)
)
```

## NRR CALCULATION

### NRR
```
NRR = 
VAR StartingMRR = [MRR Last Month]
VAR EndingMRR = [Total MRR]
VAR ExpansionMRR = [Expansion MRR]
RETURN
    DIVIDE(
        (StartingMRR + ExpansionMRR - [Churned MRR]),
        StartingMRR,
        0
    )
```
