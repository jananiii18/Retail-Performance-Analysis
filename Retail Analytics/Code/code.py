# Import required libraries
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Load dataset
df = pd.read_csv("superstore_cleaned_dataset.csv")

# Convert Order_Date column to datetime format
df['Order_Date'] = pd.to_datetime(df['Order_Date'], format="%d-%m-%Y", errors='coerce')

# Reformat date back to string (DD-MM-YYYY)
df['Order_Date'] = df['Order_Date'].dt.strftime("%d-%m-%Y")

# Create new calculated columns
df['Profit_Margin'] = df['Profit'] / df['Sales'] * 100   # Profit margin in percentage
df['Inventory_Days'] = (df['Quantity'] / df['Sales']) * 30  # Approx inventory days


# Correlation Heatmap
corr_matrix = df[['Inventory_Days','Profit','Profit_Margin']].corr()
sns.heatmap(corr_matrix, annot=True, cmap="Reds")
plt.title("Correlation: Inventory Days vs Profitability")
plt.show()

# Quarterly Sales & Profit Trends

# Convert Order_Date again to proper datetime for grouping
df['Order_Date'] = pd.to_datetime(df['Order_Date'], dayfirst=True)
monthly = df.groupby(pd.Grouper(key='Order_Date', freq='QE'))[['Sales','Profit']].sum().reset_index()

# Sales trend over time
plt.figure(figsize=(12,6))
plt.subplot(2,1,1)  
sns.lineplot(data=monthly, x="Order_Date", y="Sales", color="blue")
plt.title("Sales Trend Over Time")
plt.ylabel("Sales")

# Profit trend over time
plt.subplot(2,1,2)   
sns.lineplot(data=monthly, x="Order_Date", y="Profit", color="orange")
plt.title("Profit Trend Over Time")
plt.ylabel("Profit")
plt.tight_layout()
plt.show()

# Discount vs Profit Margin (by Category)
sns.scatterplot(x="Discount", y="Profit_Margin", hue="Category", data=df)
plt.title("Discount vs Profit Margin by Category")
plt.show()

# Profit Heatmap (Category vs Sub-Category)
plt.figure(figsize=(12,6))
pivot = df.pivot_table(values="Profit", index="Category", columns='Sub_Category', aggfunc="sum")
sns.heatmap(pivot, annot=True, fmt=".0f", cmap="RdYlGn")
plt.title("Profit Heatmap by Category & Sub_category")
plt.show()

# Pareto Analysis (80/20 Rule)
df_sorted = df.groupby('Product_Name')['Profit'].sum().sort_values(ascending=False).reset_index()
df_sorted['Cumulative_profit'] = df_sorted['Profit'].cumsum() / df_sorted['Profit'].sum() * 100
sns.lineplot(x=range(len(df_sorted)), y="Cumulative_profit", data=df_sorted)
plt.axhline(80, color='red', linestyle='--')
plt.title("Pareto Analysis (80/20 Rule)")
plt.show()
