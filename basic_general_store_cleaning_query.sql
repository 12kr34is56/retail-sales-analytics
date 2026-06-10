SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/Users/comme/Desktop/DA/general_store.csv' 
INTO TABLE general_store 
CHARACTER SET latin1 -- <-- This line tells MySQL to accept special text characters
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

SET SQL_SAFE_UPDATES = 0;

-- 1. Parse Order Date (Handles slashes and dashes as Month-First)
UPDATE general_store
SET `Order Date` = CASE 
    WHEN `Order Date` LIKE '%/%' THEN STR_TO_DATE(`Order Date`, '%c/%e/%Y')
    WHEN `Order Date` LIKE '%-%' THEN STR_TO_DATE(`Order Date`, '%c-%e-%Y')
    ELSE `Order Date`
END
WHERE `Order Date` IS NOT NULL;

-- 2. Parse Ship Date (Handles slashes and dashes as Month-First)
UPDATE general_store
SET `Ship Date` = CASE 
    WHEN `Ship Date` LIKE '%/%' THEN STR_TO_DATE(`Ship Date`, '%c/%e/%Y')
    WHEN `Ship Date` LIKE '%-%' THEN STR_TO_DATE(`Ship Date`, '%c-%e-%Y')
    ELSE `Ship Date`
END
WHERE `Ship Date` IS NOT NULL;

-- 3. Secure them into true database DATE columns permanently
ALTER TABLE general_store 
MODIFY `Order Date` DATE,
MODIFY `Ship Date` DATE;




SELECT * FROM genernal_mart.general_store;

ALTER TABLE general_store 
RENAME COLUMN `ï»¿Row ID` TO `Row id`;

desc general_store;



SELECT 
    SUM(CASE WHEN `Order ID` IS NULL OR `Order ID` = '' THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN `order date` IS NULL  THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN `ship date` IS NULL  THEN 1 ELSE 0 END) AS null_ship_date,
    SUM(CASE WHEN `ship mode` IS NULL OR `ship mode` = '' THEN 1 ELSE 0 END) AS null_ship_mode,
    SUM(CASE WHEN `customer id` IS NULL OR `customer id` = '' THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN `customer name` IS NULL OR `customer name` = '' THEN 1 ELSE 0 END) AS null_customer_name,
    SUM(CASE WHEN `segment` IS NULL OR `segment` = '' THEN 1 ELSE 0 END) AS null_segment,
    SUM(CASE WHEN `country` IS NULL OR `country` = '' THEN 1 ELSE 0 END) AS null_country,
    SUM(CASE WHEN `state` IS NULL OR `state` = '' THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN `city` IS NULL OR `city` = '' THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN `postal code` IS NULL OR `postal code` = '' THEN 1 ELSE 0 END) AS null_postal_code,
    SUM(CASE WHEN `region` IS NULL OR `region` = '' THEN 1 ELSE 0 END) AS null_region,
    SUM(CASE WHEN `product id` IS NULL OR `product id` = '' THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN `category` IS NULL OR `category` = '' THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN `sub-category` IS NULL OR `sub-category` = '' THEN 1 ELSE 0 END) AS null_sub_category,
    SUM(CASE WHEN `product name` IS NULL OR `product name` = '' THEN 1 ELSE 0 END) AS null_product_name,
    SUM(CASE WHEN `sales` IS NULL OR `sales` = '' THEN 1 ELSE 0 END) AS null_sales
FROM general_store;


select sales,Round(sales,2) from general_store
where `row id` = 4102;

update general_store
set sales = Round(sales,2)
where sales is not null;

SELECT `row id`,country, state,City,Region, sales, `Postal Code`
FROM general_store 
WHERE `sales` = '' OR `postal code` = 0;

SELECT `Order ID`, COUNT(*) AS total
FROM general_store
GROUP BY `Order ID`
HAVING COUNT(*) > 1;


SELECT *
FROM general_store
WHERE `Order ID` IN (
    SELECT `Order ID`
    FROM general_store
    GROUP BY `Order ID`
    HAVING COUNT(*) > 1
)
ORDER BY `Order ID`;


WITH ranked_orders AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY `Order ID` 
               ORDER BY `Row id`
           ) AS rn
    FROM general_store
)
SELECT 
    `Row id`,
    `Order ID`,
    `Order Date`,
    `Customer Name`,
    `Sales`,
    rn AS duplicate_rank
FROM ranked_orders
WHERE rn > 1;         -- rn = 1 is original, rn > 1 are duplicates



-- Total rows
SELECT COUNT(*) FROM general_store;

-- Unique Order IDs
SELECT COUNT(DISTINCT `Order ID`) FROM general_store;

-- Difference = duplicate rows
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT `Order ID`) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT `Order ID`) AS duplicate_rows
FROM general_store;

SELECT `Order ID`, `Product ID`, `Sales`, `Quantity`, `Discount`, COUNT(*) AS total
FROM general_store
GROUP BY `Order ID`, `Product ID`, `Sales`, `Quantity`, `Discount`
HAVING COUNT(*) > 1;

SELECT *
FROM general_store
WHERE `Order ID` = 'US-2014-150119'
  AND `Product ID` = 'FUR-CH-10002965';
  
  
CREATE TABLE general_store_backup AS 
SELECT * FROM general_store;


WITH ranked AS (
    SELECT `Row id`,
           ROW_NUMBER() OVER (
               PARTITION BY `Order ID`, `Customer ID`, `Product ID`,
                            `Sales`, `Quantity`, `Discount`, `Profit`
               ORDER BY `Row id`
           ) AS rn
    FROM general_store
)
DELETE FROM general_store
WHERE `Row id` IN (
    SELECT `Row id` FROM ranked WHERE rn > 1
);

-- Should return 0 rows now
SELECT `Order ID`, `Customer ID`, `Product ID`, 
       `Sales`, `Quantity`, `Discount`, `Profit`,
       COUNT(*) AS total
FROM general_store
GROUP BY `Order ID`, `Customer ID`, `Product ID`, 
         `Sales`, `Quantity`, `Discount`, `Profit`
HAVING COUNT(*) > 1;













