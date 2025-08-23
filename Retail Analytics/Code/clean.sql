
-- Retail Business: Performance & Profitability Analysis

-- Use the Superstore Database
USE superstore;
GO

-- Preview first 10 rows
SELECT TOP 10 *
FROM dbo.store;
GO

-- Count total rows (Before cleaning)
SELECT COUNT(*) AS Total_Rows
FROM dbo.store;
GO 
-- 9994

-- Check for NULL Values in Key Columns
SELECT 
    SUM(CASE WHEN Order_ID IS NULL THEN 1 ELSE 0 END) AS Order_ID_Null,
    SUM(CASE WHEN Ship_Mode IS NULL THEN 1 ELSE 0 END) AS Ship_Mode_Null,
    SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) AS Customer_ID_Null,
    SUM(CASE WHEN Customer_Name IS NULL THEN 1 ELSE 0 END) AS Customer_Name_Null,
    SUM(CASE WHEN Segment IS NULL THEN 1 ELSE 0 END) AS Segment_Null,
    SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS Country_Null,
    SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS City_Null,
    SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS State_Null,
    SUM(CASE WHEN Postal_Code IS NULL THEN 1 ELSE 0 END) AS Postal_Code_Null,
    SUM(CASE WHEN Region IS NULL THEN 1 ELSE 0 END) AS Region_Null,
    SUM(CASE WHEN Product_ID IS NULL THEN 1 ELSE 0 END) AS Product_ID_Null,
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS Category_Null,
    SUM(CASE WHEN Sub_Category IS NULL THEN 1 ELSE 0 END) AS Sub_Category_Null,
    SUM(CASE WHEN Product_Name IS NULL THEN 1 ELSE 0 END) AS Product_Name_Null,
    SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS Sales_Null,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS Quantity_Null,
    SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END) AS Discount_Null,
    SUM(CASE WHEN Profit IS NULL THEN 1 ELSE 0 END) AS Profit_Null
FROM dbo.store;
GO

-- Remove duplicate orders based on Order_ID & Product_ID
;WITH CTE AS (
    SELECT ROW_ID,
           ROW_NUMBER() OVER (PARTITION BY Order_ID, Product_ID ORDER BY ROW_ID) AS rn
    FROM dbo.store
)
DELETE FROM CTE
WHERE rn > 1;
GO

-- Count total rows (After cleaning)
SELECT COUNT(*) AS Total_Rows
FROM dbo.store;
GO 
-- 9986

-- Convert Order_Date and Ship_Date to DATE type
-- Order date
ALTER TABLE dbo.store
ALTER COLUMN Order_Date DATE; 
GO
-- Ship Date
ALTER TABLE dbo.store
ALTER COLUMN Ship_Date DATE;
GO

-- Add Year, Month, Quarter columns for time-series analysis 
ALTER TABLE dbo.store
ADD Order_Year INT,
    Order_Month INT,
    Order_Quarter INT;
GO

-- Populate new time columns
UPDATE dbo.store
SET Order_Year = YEAR(Order_Date),
    Order_Month = MONTH(Order_Date),
    Order_Quarter = DATEPART(QUARTER, Order_Date);
GO

-- Standardize / Trim text columns 
UPDATE dbo.store
SET
    Order_ID = TRIM(Order_ID),
    Product_ID = TRIM(Product_ID),
    Product_Name = TRIM(CAST(Product_Name AS VARCHAR(MAX))),
    Customer_ID = TRIM(Customer_ID),
    Customer_Name = TRIM(Customer_Name),
    Category = TRIM(Category),
    Sub_Category = TRIM(Sub_Category),
    Segment = TRIM(Segment),
    Country = TRIM(Country),
    Region = TRIM(Region),
    City = TRIM(City),
    State = TRIM(State);
GO

-- Overall Summary Sales, Profit & Profit Margin
SELECT 
    ROUND(SUM(Sales),2) AS Total_Sales,
    ROUND(SUM(Profit),2) AS Net_Profit,
    ROUND((SUM(Profit)/NULLIF(SUM(Sales),0)*100),2) AS Profit_Margin_Percent
FROM dbo.store;

-- Category-wise Sales, Profit & Profit Margin
SELECT 
    Category,
    ROUND(SUM(Sales),2) AS Total_Sales,
    ROUND(SUM(Profit),2) AS Net_Profit,
    ROUND((SUM(Profit)/NULLIF(SUM(Sales),0)*100),2) AS Profit_Margin_Percent
FROM dbo.store
GROUP BY Category
ORDER BY Profit_Margin_Percent DESC;
GO

-- Sub_Category-wise Sales, Profit & Profit Margin
SELECT 
    Sub_Category,
    ROUND(SUM(Sales),2) AS Total_Sales,
    ROUND(SUM(Profit),2) AS Net_Profit,
    ROUND((SUM(Profit)/NULLIF(SUM(Sales),0)*100),2) AS Profit_Margin_Percent
FROM dbo.store
GROUP BY Sub_Category
ORDER BY Profit_Margin_Percent DESC;
GO

-- Year-Month Sales, Profit, Discount % and Profit Margin by Category
SELECT 
    Category,
    Order_Year,
    Order_Month,
    ROUND(SUM(Sales),2) AS Total_Sales,
    ROUND(SUM(Profit),2) AS Net_Profit,
	  ROUND(SUM(Sales*Discount)*100/NULLIF(SUM(Sales),0),2) AS Discount_Percentage,
    ROUND(SUM(Profit)*100.0/NULLIF(SUM(Sales),0),2) AS Profit_Margin_Percent
FROM dbo.store
GROUP BY Category, Order_Year, Order_Month
ORDER BY Category, Order_Year, Order_Month;
GO

-- Top 3 Sub-Categories by Profit Margin % within Each Category
;WITH Ranked AS (
    SELECT 
        Category,
        Sub_Category,
        ROUND(SUM(Sales),2) AS Total_Sales,
        ROUND(SUM(Profit),2) AS Net_Profit,
        ROUND(SUM(Profit)*100.0/NULLIF(SUM(Sales),0),2) AS Profit_Margin_Percent,
        ROW_NUMBER() OVER (
            PARTITION BY Category 
            ORDER BY SUM(Profit)*100.0/NULLIF(SUM(Sales),0) DESC
        ) AS rn
    FROM dbo.store
    GROUP BY Category, Sub_Category
    HAVING SUM(Profit) > 0
)
SELECT *
FROM Ranked
WHERE rn <= 3
ORDER BY Category, Profit_Margin_Percent DESC;
GO


-- Top 3 Sub-Categories by Net Profit within Each Category
WITH Ranked AS (
    SELECT 
        Category,
        Sub_Category,
        ROUND(SUM(Sales),2) AS Total_Sales,
        ROUND(SUM(Profit),2) AS Net_Profit,
        ROUND(SUM(Profit)*100.0/NULLIF(SUM(Sales),0),2) AS Profit_Margin_Percent,
        ROW_NUMBER() OVER (
            PARTITION BY Category 
            ORDER BY SUM(Profit) DESC
        ) AS rn
    FROM dbo.store
    GROUP BY Category, Sub_Category
	HAVING SUM(Profit) > 0
)
SELECT *
FROM Ranked
WHERE rn <= 3
ORDER BY Category, Net_Profit DESC;
GO

-- Loss-making Category–Sub-Category combinations (high discount impact)
SELECT 
    Category,
    Sub_Category,
	  ROUND(SUM(Sales),2) AS Total_Sales,
    ROUND(SUM(Sales*Discount)*100/NULLIF(SUM(Sales),0),2) AS Discount_Percentage,
    ROUND(SUM(Profit),2) AS Net_Profit,
	ROUND(SUM(Profit)*100.0/NULLIF(SUM(Sales),0),2) AS Profit_Margin_Percent
FROM dbo.store
GROUP BY Category, Sub_Category
HAVING SUM(Profit) < 0
ORDER BY Net_Profit ASC;


-- Recommendations:
-- 1. Prioritize top profit-making Sub-Categories to boost overall growth.
-- 2. Control discounts in loss-making segments to reduce profit drain.
-- 3. Monitor monthly profit trends to act quickly on downturns.
