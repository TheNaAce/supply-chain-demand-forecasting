import pandas as pd
import numpy as np
import mysql.connector
from statsmodels.tsa.holtwinters import ExponentialSmoothing
from sklearn.metrics import mean_absolute_error, mean_squared_error

# 1. CONNECT TO MYSQL

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Dinesh123@",
    database="supply_chain_db"
)

print("Connected to MySQL successfully!")

# 2. LOAD DATA

query = """
SELECT sale_date, demand
FROM forecasting_data
ORDER BY sale_date
"""

df = pd.read_sql(query, conn)

conn.close()

df["sale_date"] = pd.to_datetime(df["sale_date"])
df = df.sort_values("sale_date")
df = df.set_index("sale_date")

print("Total days:", len(df))


# 3. TRAIN / TEST SPLIT

train = df.iloc[:-30]
test = df.iloc[-30:]

print("Training days:", len(train))
print("Testing days:", len(test))

# 4. EXPONENTIAL SMOOTHING

model = ExponentialSmoothing(
    train["demand"],
    trend="add",
    seasonal=None
)

fitted_model = model.fit(optimized=True)

predictions = fitted_model.forecast(30)

predictions = np.maximum(predictions, 0)

# 5. MODEL EVALUATION


mae = mean_absolute_error(
    test["demand"],
    predictions
)

rmse = np.sqrt(
    mean_squared_error(
        test["demand"],
        predictions
    )
)

mape = np.mean(
    np.abs(
        (test["demand"] - predictions)
        / np.where(test["demand"] == 0, 1, test["demand"])
    )
) * 100

print("\n MODEL PERFORMANCE 
print(f"MAE  : {mae:.2f}")
print(f"RMSE : {rmse:.2f}")
print(f"MAPE : {mape:.2f}%")



# 6. SAVE TEST FORECAST

test_results = pd.DataFrame({
    "date": test.index,
    "actual_demand": test["demand"].values,
    "predicted_demand": predictions.values
})

test_results.to_csv(
    "forecast_results.csv",
    index=False
)

print("\nTest forecast saved to forecast_results.csv")


# 7. FUTURE 30-DAY FORECAST

final_model = ExponentialSmoothing(
    df["demand"],
    trend="add",
    seasonal=None
).fit(optimized=True)

future_forecast = final_model.forecast(30)

future_forecast = np.maximum(
    future_forecast,
    0
)

future_results = pd.DataFrame({
    "date": future_forecast.index,
    "forecast_demand": future_forecast.values
})

future_results.to_csv(
    "future_30_day_forecast.csv",
    index=False
)

print("\n30-day future forecast saved to future_30_day_forecast.csv")

print("\nNEXT 30 DAYS ")
print(future_results.to_string(index=False))

# =========================
# 8. INVENTORY & REORDER ANALYSIS
# =========================

# Average daily demand
avg_daily_demand = df["demand"].mean()

# Demand standard deviation
demand_std = df["demand"].std()

# Assumed supplier lead time
lead_time_days = 5

# Safety stock
# Using 1.65 service factor (~95% service level)
safety_stock = 1.65 * demand_std * np.sqrt(lead_time_days)

# Reorder point
reorder_point = (
    avg_daily_demand * lead_time_days
    + safety_stock
)

print("\n========== INVENTORY ANALYSIS ==========")
print(f"Average Daily Demand : {avg_daily_demand:.2f}")
print(f"Demand Std Dev       : {demand_std:.2f}")
print(f"Lead Time            : {lead_time_days} days")
print(f"Safety Stock         : {safety_stock:.2f}")
print(f"Reorder Point        : {reorder_point:.2f}")
print("=========================================")


# =========================
# 9. INVENTORY SUMMARY
# =========================

inventory_summary = pd.DataFrame({
    "metric": [
        "Average Daily Demand",
        "Demand Standard Deviation",
        "Lead Time (Days)",
        "Safety Stock",
        "Reorder Point"
    ],
    "value": [
        avg_daily_demand,
        demand_std,
        lead_time_days,
        safety_stock,
        reorder_point
    ]
})

inventory_summary.to_csv(
    "inventory_analysis.csv",
    index=False
)

print("\nInventory analysis saved to inventory_analysis.csv")