/* 
================================
Data Cleaning Project Process
================================

Phase 1: Data Backup & Staging
Phase 2: Duplicate Identification & Removal
Phase 3: Data Standardization
Phase 4: Data Type Casting
Phase 5: Missing Value Imputation
Phase 6: Anomaly Detection & Categorization
Phase 7: Final Data Pruning

================================
*/
SELECT * FROM online_retail_data;
-- ============================================================================
-- PHASE 1: DATA BACKUP & STAGING
-- ============================================================================

-- Step 1.1: Making copy of data to have real data safe
CREATE TABLE online_retail_data_raw -- Raw dataset
SELECT * FROM online_retail_data;

-- ============================================================================
-- PHASE 2: DUPLICATE IDENTIFICATION & REMOVAL
-- ============================================================================

-- Step 2.1: Checking and Identifying Duplicate data
SELECT *,
ROW_NUMBER() OVER(PARTITION BY InvoiceNo, StockCode, `Description`, InvoiceDate,CustomerID, Country)
FROM online_retail_data;

WITH Duplicate_CTE AS -- Made CTE For clear Understanding
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY InvoiceNo, StockCode, `Description`,Quantity, InvoiceDate,UnitPrice, CustomerID, Country) AS row_num
FROM online_retail_data
)
SELECT * 
FROM Duplicate_CTE
WHERE row_num > 1
;

-- Found out 1241 Duplicate rows & now Removing it

-- Step 2.2: Creating New Table With row_num column for removing Duplicates
CREATE TABLE `online_retail_data_2` (
  `InvoiceNo` text,
  `StockCode` text,
  `Description` text,
  `Quantity` text,
  `InvoiceDate` text,
  `UnitPrice` text,
  `CustomerID` text,
  `Country` text,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO online_retail_data_2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY InvoiceNo, StockCode, `Description`,Quantity, InvoiceDate,UnitPrice, CustomerID, Country) AS row_num
FROM online_retail_data;	

-- Step 2.3: Executing Duplicate Removal
DELETE
FROM  online_retail_data_2
WHERE row_num > 1;

-- ============================================================================
-- PHASE 3: DATA STANDARDIZATION
-- ============================================================================

-- Step 3.1: Text Standardization (Removing leading & trailing spaces)
SELECT Description, TRIM(description)
FROM online_retail_data_2;

UPDATE online_retail_data_2
SET Description = TRIM(description);

SELECT * FROM online_retail_data_2;

-- Step 3.2: Formatting Text Casing (Fixing inconsistent casing in data)
SELECT DISTINCT Country -- THERE ARE 32 COUNTRIES AND HALF OF THEM HAVE inconsistent casing
FROM online_retail_data_2
ORDER BY Country; 

SELECT DISTINCT Country, 
CONCAT
(UPPER(LEFT(Country,1)),
LOWER(SUBSTRING(Country,2))) 
FROM Online_retail_data_2;

UPDATE online_retail_data_2 -- FIXED inconsistent casing FOR MANY OF THEM
SET Country = CONCAT
(UPPER(LEFT(Country,1)),
LOWER(SUBSTRING(Country,2)));


UPDATE online_retail_data_2 -- COUNTRIES WITH 2 OR MORE WORDS LIKE United Kingdom need's TO DO WITH CASE STATEMENT
SET country = CASE
    WHEN LOWER(TRIM(country)) = 'united kingdom' THEN 'United Kingdom'
    WHEN LOWER(TRIM(country)) = 'channel islands' THEN 'Channel Islands'
    WHEN LOWER(TRIM(country)) = 'united arab emirates' THEN 'United Arab Emirates'
    WHEN LOWER(TRIM(country)) = 'saudi arabia' THEN 'Saudi Arabia'
	WHEN LOWER(TRIM(country)) = 'czech republic' THEN 'Czech Republic'
    WHEN LOWER(TRIM(country)) = 'czech republic' THEN 'Czech Republic'
    ELSE country
END;


-- Step 3.3: Nullifying Empty Strings (Converting Blank Values to NUll to handel it Properly)
UPDATE online_retail_data_2
SET Country = NULL
WHERE Country = '';

UPDATE online_retail_data_2
SET description = NULL
WHERE description = '';


-- ============================================================================
-- PHASE 4: DATA TYPE CASTING
-- ============================================================================

-- Step 4.1: Converting datatypes of columns for accurate analysis
SELECT STR_TO_DATE(InvoiceDate, '%d-%m-%Y %H:%i') AS converted_date
FROM online_retail_data_2;

UPDATE online_retail_data_2
SET InvoiceDate = STR_TO_DATE(InvoiceDate, '%d-%m-%Y %H:%i');

UPDATE online_retail_data_2
SET InvoiceDate = DATE(InvoiceDate);

ALTER TABLE  online_retail_data_2
MODIFY InvoiceDate DATE;

ALTER TABLE  online_retail_data_2
MODIFY Quantity INT;

ALTER TABLE  online_retail_data_2
MODIFY UnitPrice DECIMAL (10,2);

ALTER TABLE  online_retail_data_2
MODIFY CustomerID INT;


-- ============================================================================
-- PHASE 5: MISSING VALUE IMPUTATION
-- ============================================================================

-- Step 5.1: Identifying Null values
SELECT *
FROM online_retail_data_2
WHERE Description IS NULL;

SELECT *
FROM online_retail_data_2
WHERE CustomerID IS NULL;

-- DATA HAVE NULL VALUES IN DESCRIPTION AND CUSTOMER_ID 
-- NOW POPULATING DESCRIPTION WITH THE STOCKCODE 

SELECT DISTINCT StockCode
FROM online_retail_data_2
WHERE Description IS NULL;

-- Step 5.2: Populating Missing Descriptions via Self-Join

SELECT DISTINCT(t1.StockCode),t1.Description,t2.StockCode,t2.Description
FROM online_retail_data_2 t1
JOIN online_retail_data_2 t2 
  ON t1.StockCode = t2.StockCode 
WHERE t1.Description IS NULL
AND t2.Description IS NOT NULL 
;

UPDATE online_retail_data_2 t1  -- SELF JOIN FOR POPULATING DATA 
JOIN online_retail_data_2 t2 
  ON t1.StockCode = t2.StockCode 
SET t1.Description = t2.Description 
WHERE t1.Description IS NULL 
AND t2.Description IS NOT NULL 
;
-- POPULATED 258 DESCRIPTION FROM THIS QUERRY

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- ============================================================================
-- PHASE 6: ANOMALY DETECTION & CATEGORIZATION
-- ============================================================================

-- Step 6.1: Investigating records with negative quantities
SELECT *
FROM online_retail_data_2 -- Cancelled orders
WHERE Quantity < 0
AND InvoiceNo LIKE 'C%' ;

SELECT *
FROM online_retail_data_2 -- Unknown negative
WHERE Quantity < 0
AND InvoiceNo NOT LIKE 'C%' ;

-- WE HAVE 2721 OF NEGATIVE QUANTITY OUT OF THAT 2418 IS cancelled ORDERS 

-- Step 6.2: Segmenting Transactions by Order Type
SELECT *,
CASE 
	WHEN Quantity < 0 AND InvoiceNo LIKE 'C%' THEN 'Cancelled'
    WHEN Quantity < 0 AND InvoiceNo NOT LIKE 'C%' THEN 'Unknown_Negative'
    ELSE 'Normal'
END AS order_type
FROM online_retail_data_2 ;


ALTER TABLE online_retail_data_2
ADD OrderType VARCHAR(20);

UPDATE online_retail_data_2
SET OrderType = CASE 
    WHEN Quantity < 0 AND InvoiceNo LIKE 'C%' THEN 'Cancelled'
    WHEN Quantity < 0 AND InvoiceNo NOT LIKE 'C%' THEN 'Unknown_Negative'
    ELSE 'Normal'
END;

SELECT *
FROM online_retail_data_2
WHERE OrderType = 'Unknown_negative';

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- ============================================================================
-- PHASE 7: FINAL CLEANUP
-- ============================================================================

/*  
 Removing Column or Rows (If Needed)

1) Step 7.1: Removing the row_num column as it was created for intermediate processing and did not contribute to the final analysis.

2) Step 7.2: Identified 303 records under the 'Unknown_Negative' category with 
   negative quantity, zero unit price, and null customer IDs. 
   These are classified as non-transactional/system-generated entries so removing them as they did not contribute to meaningful analysis.
*/

ALTER TABLE online_retail_data_2
DROP COLUMN row_num;


DELETE  
FROM online_retail_data_2
WHERE OrderType = 'Unknown_negative';


/* 
=============================================================================
END OF SCRIPT
=============================================================================
*/