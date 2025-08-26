# Import required libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Load & clean data
df = pd.read_csv("superstore_cleaned_dataset.csv")

df['Order_Date'] = pd.to_datetime(df['Order_Date'],dayfirst=True, errors='coerce')
df['Profit_Margin'] = df['Profit'] / df['Sales'] * 100
df['Inventory_Days'] = (df['Quantity'] / df['Sales']) * 30 

# Correlation: Inventory vs Profitability
corr_matrix = df[['Inventory_Days','Profit','Profit_Margin']].corr()
sns.heatmap(corr_matrix, annot=True, cmap="Reds")
plt.title("Correlation: Inventory Days vs Profitability")
plt.show()

# Inventory Optimization (Slow-Moving & Overstocked)
df['Slow_Moving'] = df['Inventory_Days'] > df['Inventory_Days'].quantile(0.90)  
df['Overstocked'] = df['Quantity'] > df['Quantity'].quantile(0.75)

df['Action_Recommended'] = np.select(
    [
        (df['Slow_Moving']) & (df['Profit'] < 0),   # Slow-Moving Loss
        (df['Slow_Moving']) & (df['Profit'] >= 0),  # Slow-Moving Profit
        (df['Overstocked']) & (df['Profit'] < 0),   # Overstocked Loss
        (df['Overstocked']) & (df['Profit'] >= 0)   # Overstocked Profit
    ],
    [
        'Phase Out (with Discounting)',  
        'Bundle Promotions',
        'Liquidate Inventory',
        'Run Clearance Promotions'
    ],
    default='No Action Needed'
)

# Export actionable product list
df_actions = df[df['Action_Recommended'] != 'No Action'][
    ['Product_Name','Category','Sub_Category','Inventory_Days','Profit','Action_Recommended']
]
df_actions.to_csv("actionable_products.csv", index=False)

# Top 10 slow-moving products
slow_moving_details = (
    df.groupby(['Category','Sub_Category','Product_Name'])['Inventory_Days']
      .mean()
      .reset_index()
      .sort_values('Inventory_Days', ascending=False)
      .head(10)
)

plt.figure(figsize=(10,6))
sns.barplot(x="Inventory_Days", y="Product_Name", hue="Product_Name",data=slow_moving_details,
            palette="Reds_r", dodge=False, legend=False)
plt.title("Top 10 Slow-Moving Products")
plt.xlabel("Average Inventory Days")
plt.ylabel("Product Name")
plt.show()

# Seasonal Profitability
def get_season(date):
    m = date.month
    if m in [12, 1, 2]:
        return 'Winter'
    elif m in [3, 4, 5]:
        return 'Spring'
    elif m in [6, 7, 8]:
        return 'Summer'
    else:
        return 'Fall'

df['Season'] = df['Order_Date'].apply(get_season)
seasonal = df.groupby(['Season', 'Category'])['Profit'].sum().reset_index()

sns.barplot(data=seasonal, x='Season', y='Profit', hue='Category')
plt.title("Seasonal Profitability by Category")
plt.show()

# Final Export
df.to_csv('retail_analysis_output.csv', index=False)

# Recommendations
# Phase out or discount loss-making slow-moving products; bundle profitable ones to improve turnover.
# Liquidate or clear overstocked items (profitable or not) to free up working capital and reduce storage costs.
# Focus seasonal strategies: boost profitable categories in peak seasons, and control losses in weak seasons.
