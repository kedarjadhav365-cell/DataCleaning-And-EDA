/* 
===============================================================================
Exploratory Data Analysis (EDA) - Online Retail Data
===============================================================================
Author: Kedar Jadhav
Purpose: To extract business insights regarding sales trends, product 
         performance, and customer segmentation using SQL.

Phases:
Phase 1: EDA Environment Setup
Phase 2: Product Integrity Checks
Phase 3: Temporal Analysis (Sales Trends)
Phase 4: Product Performance & Supply Chain Metrics
Phase 5: Customer Value Metrics (AOV & The "Whales")
Phase 6: RFM Analysis (Recency, Frequency, Monetary)
===============================================================================
*/
SELECT * FROM eda_online_retail_data;
-- ============================================================================
-- PHASE 1: EDA ENVIRONMENT SETUP
-- ============================================================================

-- Step 1.1: Create a dedicated table for EDA to preserve the cleaned dataset
CREATE TABLE EDA_online_retail_data
SELECT * FROM online_retail_data_2;

-- Step 1.2: General data preview
SELECT * FROM EDA_online_retail_data;


-- ============================================================================
-- PHASE 2: PRODUCT INTEGRITY CHECKS
-- ============================================================================

-- Step 2.1: Identify products with a net-zero total quantity (cancelled = ordered)
SELECT Description, SUM(Quantity)
FROM EDA_online_retail_data
GROUP BY Description 
HAVING SUM(Quantity) = 0 
;
-- ============================================================================
-- PHASE 3: TEMPORAL ANALYSIS (SALES TRENDS)
-- ============================================================================

-- Step 3.1: Calculate total monthly revenue and order volume (excluding cancellations)
SELECT 
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS Sales_Month,
    SUM(Quantity * UnitPrice) AS Total_Revenue,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders
FROM EDA_online_retail_data
WHERE OrderType = 'Normal'
GROUP BY Sales_Month
ORDER BY Sales_Month;


-- ============================================================================
-- PHASE 4: PRODUCT PERFORMANCE & SUPPLY CHAIN METRICS
-- ============================================================================

-- Step 4.1: Identify the Top 10 revenue-generating products
SELECT StockCode,Description,
        SUM(Quantity*UnitPrice) AS Total_revenue,
        SUM(Quantity) AS Total_units_sold,
        COUNT(InvoiceNo) AS Total_orders
FROM EDA_online_retail_data
WHERE OrderType = 'Normal'
GROUP BY StockCode,Description
ORDER BY Total_revenue DESC 
LIMIT 10;




-- ============================================================================
-- PHASE 5: CUSTOMER VALUE METRICS
-- ============================================================================

-- Step 5.1: Calculate the Global Average Order Value (AOV)
SELECT ROUND(SUM(Quantity * UnitPrice)/ COUNT(DISTINCT InvoiceNo),2)
FROM eda_online_retail_data
WHERE OrderType = 'Normal';


-- Step 5.2: Identify "Whale" Customers (Top 5% generating 80% of total revenue)
WITH Customer_Totals AS (
    -- Get the total revenue for every single customer
    SELECT 
        CustomerID, 
        SUM(Quantity * UnitPrice) AS Individual_Revenue
    FROM eda_online_retail_data
    WHERE OrderType = 'Normal' AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
Running_Totals AS (
    -- Calculate the running total and the grand total
    SELECT 
        CustomerID,
        Individual_Revenue,
        -- This creates a running tally, adding each customer's revenue to the previous ones
        SUM(Individual_Revenue) OVER(ORDER BY Individual_Revenue DESC) AS Running_Total,
        -- This calculates the grand total revenue for the whole company
        SUM(Individual_Revenue) OVER() AS Grand_Total
    FROM Customer_Totals
)
-- Filter for the customers who make up the top 80% of revenue
SELECT 
    CustomerID,
    Individual_Revenue,
    ROUND((Running_Total / Grand_Total) * 100, 2) AS Cumulative_Revenue_Pct
FROM Running_Totals
WHERE (Running_Total / Grand_Total) <= 0.80
ORDER BY Individual_Revenue DESC;


-- ============================================================================
-- PHASE 6: RFM ANALYSIS (RECENCY, FREQUENCY, MONETARY)
-- ============================================================================

-- Step 6.1: (Draft) Recency - Calculate days since first and last purchase
SELECT CustomerID,MAX(InvoiceDate) AS last_purchace,
DATEDIFF( (SELECT MAX(InvoiceDate) FROM eda_online_retail_data),   MAX(InvoiceDate))AS since_last_purchace
FROM eda_online_retail_data
GROUP BY CustomerID;

-- Step 6.2: (Draft) Frequency - Count total distinct invoices per customer
SELECT CustomerID, COUNT(DISTINCT InvoiceNo)
FROM eda_online_retail_data
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID;

-- Step 6.3: (Draft) Monetary - Calculate net lifetime spend per customer
SELECT CustomerID, SUM(Quantity * UnitPrice)
FROM eda_online_retail_data
WHERE OrderType = 'Normal'
GROUP BY CustomerID;


-- Step 6.4: FINAL RFM MASTER QUERY - Combined dynamic Recency, Frequency, and Monetary scores
SELECT CustomerID,
DATEDIFF( (SELECT MAX(InvoiceDate) FROM eda_online_retail_data) ,MAX(InvoiceDate))AS Recency_Days,
COUNT(DISTINCT InvoiceNo) AS Frequency_Orders,
SUM(Quantity * UnitPrice) AS Monetary_Spend
FROM eda_online_retail_data
WHERE OrderType = 'Normal'
AND CustomerID IS NOT NULL
GROUP BY CustomerID;

/* 
===============================================================================
END OF SCRIPT
===============================================================================
*/

WITH Customer_Totals AS (
    -- Total revenue per customer
    -- Total revenue per customer
    SELECT 
        CustomerID,
        SUM(Quantity * UnitPrice) AS Individual_Revenue
    FROM eda_online_retail_data
    WHERE OrderType = 'Normal'
          AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),

Running_Totals AS (
    -- Running revenue and grand total
    SELECT
        CustomerID,
        Individual_Revenue,

        SUM(Individual_Revenue) OVER(
            ORDER BY Individual_Revenue DESC
        ) AS Running_Total,

        SUM(Individual_Revenue) OVER() AS Grand_Total

    FROM Customer_Totals
),

Top_80_Customers AS (
    -- Customers contributing to first 80% revenue
    SELECT *
    FROM Running_Totals
    WHERE (Running_Total / Grand_Total) <= 0.80
)

-- Final Percentage Calculation
SELECT 
    COUNT(*) AS Customers_In_80_Percent_Revenue,

    (SELECT COUNT(*) FROM Customer_Totals) 
    AS Total_Customers,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM Customer_Totals),
        2
    ) AS Percentage_Of_Customers

FROM Top_80_Customers;

