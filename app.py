import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt

st.set_page_config(
    page_title="Supply Chain Demand Forecasting",
    layout="wide"
)

st.title("📦 Supply Chain Demand Forecasting Dashboard")
st.write("Demand forecasting and inventory planning using statistical time-series methods.")

# =========================
# LOAD DATA
# =========================

forecast = pd.read_csv("future_30_day_forecast.csv")
results = pd.read_csv("forecast_results.csv")
inventory = pd.read_csv("inventory_analysis.csv")

forecast["date"] = pd.to_datetime(forecast["date"])
results["date"] = pd.to_datetime(results["date"])


# =========================
# KPI SECTION
# =========================

avg_demand = inventory.loc[
    inventory["metric"] == "Average Daily Demand", "value"
].iloc[0]

safety_stock = inventory.loc[
    inventory["metric"] == "Safety Stock", "value"
].iloc[0]

reorder_point = inventory.loc[
    inventory["metric"] == "Reorder Point", "value"
].iloc[0]

mape = (
    (abs(results["actual_demand"] - results["predicted_demand"])
     / results["actual_demand"].replace(0, 1))
    .mean()
    * 100
)

col1, col2, col3, col4 = st.columns(4)

col1.metric("Average Daily Demand", f"{avg_demand:,.0f}")
col2.metric("Safety Stock", f"{safety_stock:,.0f}")
col3.metric("Reorder Point", f"{reorder_point:,.0f}")
col4.metric("Forecast MAPE", f"{mape:.2f}%")


# =========================
# FUTURE FORECAST
# =========================

st.subheader("📈 30-Day Demand Forecast")

fig, ax = plt.subplots(figsize=(12, 5))

ax.plot(
    forecast["date"],
    forecast["forecast_demand"],
    label="Forecast"
)

ax.set_xlabel("Date")
ax.set_ylabel("Demand")
ax.legend()

st.pyplot(fig)


# =========================
# ACTUAL VS PREDICTED
# =========================

st.subheader("🎯 Actual vs Predicted Demand")

fig2, ax2 = plt.subplots(figsize=(12, 5))

ax2.plot(
    results["date"],
    results["actual_demand"],
    label="Actual Demand"
)

ax2.plot(
    results["date"],
    results["predicted_demand"],
    label="Predicted Demand"
)

ax2.set_xlabel("Date")
ax2.set_ylabel("Demand")
ax2.legend()

st.pyplot(fig2)


# =========================
# INVENTORY ANALYSIS
# =========================

st.subheader("📦 Inventory Planning")

st.dataframe(
    inventory,
    use_container_width=True
)


# =========================
# FORECAST TABLE
# =========================

st.subheader("🔮 Future Demand")

st.dataframe(
    forecast,
    use_container_width=True
)