# 🛒 Online Retail Data Cleaning & Analysis

## 📌 Project Overview
This project focuses on the most critical step of data analytics: data integrity. I took a raw, messy online retail dataset and used **MySQL** to clean, standardize, and prepare the data for accurate business analysis. The goal was to eliminate anomalies so that revenue and customer behavior insights are based on reliable data.

## Dataset Used 
- <a herf="https://github.com/kedarjadhav365-cell/DataCleaning-And-EDA/blob/main/Online%20Retail.xlsx">Dataset</a>

## 🛠️ Tech Stack
* **Database:** MySQL
* **Presentation:** Microsoft PowerPoint (Business Insights Deck)
* **Core Concepts:** Data Cleaning, Common Table Expressions (CTEs), Window Functions, Data Type Standardization.

## 🧹 The Data Cleaning Process
Real-world retail data is rarely ready for analysis out of the box. To ensure accuracy, I executed the following data cleaning steps in MySQL:
1. **Removed Duplicates:** Used `ROW_NUMBER()` over partition windows to identify and remove duplicate transaction lines.
2. **Handled Missing Data:** Filtered out records with missing `CustomerID`s using `IS NOT NULL` to ensure customer-level metrics were accurate.
3. **Filtered Anomalies:** Isolated and removed canceled orders (showing as negative `Quantity` values) so they would not artificially inflate or deflate total revenue calculations.
4. **Standardized Formatting:** Casted string date columns into proper `DATETIME` formats to allow for precise time-series and monthly trend analysis.

## 💻 Code Snippet: Identifying Duplicates
Here is a sample of the SQL logic used to identify duplicate transactions before removing them from the main dataset:

```sql
WITH DuplicateCheck AS (
    SELECT 
        InvoiceNo, 
        StockCode, 
        CustomerID,
        Quantity,
        InvoiceDate,
        ROW_NUMBER() OVER(PARTITION BY InvoiceNo, StockCode, Quantity ORDER BY InvoiceDate) as row_num
    FROM 
        online_retail_data
)
SELECT * 
FROM DuplicateCheck 
WHERE row_num > 1;
