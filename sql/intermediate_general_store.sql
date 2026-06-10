SELECT * FROM general_store;
/*
Intermediate Analysis — 4 Key Areas
Area 1 → Customer Analysis
Area 2 → Product Analysis
Area 3 → Discount & Profitability Analysis
Area 4 → Shipping & Operations Analysis

*/

-- customer analyze

-- Who are your top 10 most valuable customers? 
/*
i want highest sale, low discount, high profit
*/
select`customer name` , round(sum(sales),2) as s, round(sum(profit),2)  as p
from general_store
group by  `customer name`
having p > 0
order by s desc , p desc;

-- How many customers ordered more than once vs only once?

WITH customer_order_counts AS (
    SELECT 
        `customer name`, 
        COUNT(DISTINCT `order id`) AS total_orders -- Use DISTINCT so multiple items in 1 order don't inflate the count
    FROM general_store
    GROUP BY `customer name`
)
SELECT 
    SUM(CASE WHEN total_orders = 1 THEN 1 ELSE 0 END) AS ordered_only_once,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS ordered_more_than_once
FROM customer_order_counts;



-- Which customers generate high revenue but low profit? (risky customers)

SELECT 
    `customer name`,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales) * 100), 2) AS margin
FROM general_store
GROUP BY `customer name`
HAVING total_profit < 0 AND total_sales > 1000 -- Only look at high-spending accounts
ORDER BY total_profit ASC
LIMIT 10;

-- Which segment has highest average order value?

SELECT 
    segment, 
    ROUND(AVG(sales), 2) AS highest_avg_order_value
FROM general_store
GROUP BY segment
ORDER BY highest_avg_order_value DESC
;

-- Which segment and which category has highest average order value?

SELECT 
    segment,
    `Category`, 
    ROUND(AVG(sales), 2) AS highest_avg_order_value
FROM general_store
GROUP BY segment, `Category`
ORDER BY highest_avg_order_value DESC
LIMIT 1;

-- Which customers are buying on heavy discounts every time?

SELECT 
    `customer name`,
    COUNT(`order id`) AS total_orders_placed,
    ROUND(AVG(discount) * 100, 2) AS lifetime_avg_discount,
    MIN(discount) AS lowest_discount_ever_accepted
FROM general_store
GROUP BY `customer name`
HAVING MIN(discount) >= 0.3
ORDER BY total_orders_placed DESC;

-- Area 2 — Product Analysis

-- Which products are stars? (high sales + high profit) or more than avg

WITH product_totals AS (
    SELECT 
        `product name`, 
        SUM(sales) AS total_sales, 
        SUM(profit) AS total_profit
    FROM general_store
    GROUP BY `product name`
)
SELECT 
    `product name`, 
    ROUND(total_sales, 2) AS s, 
    ROUND(total_profit, 2) AS p
FROM product_totals
WHERE total_sales > (SELECT AVG(total_sales) FROM product_totals)
  AND total_profit > (SELECT AVG(total_profit) FROM product_totals)
ORDER BY s DESC;

-- Which products are dead weight? (high sales + negative profit)

SELECT `product name`, ROUND(SUM(sales), 2) AS s, ROUND(SUM(profit), 2) AS p
FROM general_store
GROUP BY `product name`
HAVING s > (
    SELECT AVG(total_sales) 
    FROM (
        SELECT SUM(sales) AS total_sales 
        FROM general_store 
        GROUP BY `product name`
    ) AS product_sums
)
AND p < 0
ORDER BY s DESC;


-- Which sub-category has best profit margin percentage?

select `sub-category` , round((sum(profit)/sum(sales)*100),2) as margin
from general_store
group by `Sub-Category`
order by margin desc;

-- Which products are bought most frequently?

with ranked_table as(
select `product name` as p_name, count(*) as product_counting
from general_store
group by `product name`
)
select p_name, product_counting,
dense_rank() over(order by product_counting desc) as popular_rank
from ranked_table
order by popular_rank;

-- Which products are only sold at heavy discount — never at full price?

/*
in this first would be 
create me temp list or table which all products whose discount value is 0
then i will compare that list  with another list whose discount is more than 0
then i will use NOT IN function t1 which is not present in t2 list give that list
 again this logic is very rudementary
*/

SELECT `product name`, MIN(discount) AS lowest_discount_given
FROM general_store
GROUP BY `product name`
HAVING MIN(discount) > 0;

-- Area 3 — Discount and Profitability Analysis

-- At what exact discount % does profit turn negative on average?

/*

*/

SELECT 
    discount, ROUND(AVG(profit), 2) AS avg_p
FROM
    general_store
GROUP BY discount
HAVING avg_p < 0
ORDER BY discount
;

-- Which region gives highest average discount?

select region, round(avg(discount),2) as avg_d
from general_store
group by region
ORDER BY avg_d DESC
; 

-- Which category suffers most from discounting?

WITH aggregated_margins AS (
    SELECT 
        category,
        -- Calculate total sales and profits for both conditions
        SUM(CASE WHEN discount = 0 THEN profit ELSE 0 END) AS full_profit,
        SUM(CASE WHEN discount = 0 THEN sales ELSE 0 END) AS full_sales,
        SUM(CASE WHEN discount > 0 THEN profit ELSE 0 END) AS disc_profit,
        SUM(CASE WHEN discount > 0 THEN sales ELSE 0 END) AS disc_sales
    FROM general_store
    GROUP BY category
),
calculated_percentages AS (
    SELECT
        category,
        -- Convert totals into percentages
        ROUND((full_profit / full_sales) * 100, 2) AS full_price_margin_pct,
        ROUND((disc_profit / disc_sales) * 100, 2) AS discounted_margin_pct
    FROM aggregated_margins
)
SELECT 
    category,
    full_price_margin_pct,
    discounted_margin_pct,
    -- Simple subtraction without repeating code
    ROUND(full_price_margin_pct - discounted_margin_pct, 2) AS margin_drop_pct
FROM calculated_percentages
ORDER BY margin_drop_pct DESC;


-- Is there a pattern — specific sub-categories always discounted heavily?

select  `sub-category` as s_cate, round(avg(discount),2) avg_d
from general_store
group by s_cate
having avg_d > 0.3
;

-- Compare: orders with zero discount vs orders with discount — profit difference?

WITH aggregated_margins AS (
    SELECT 
        category,
        -- Calculate total sales and profits for both conditions
        SUM(CASE WHEN discount = 0 THEN profit ELSE 0 END) AS full_profit,
        SUM(CASE WHEN discount = 0 THEN sales ELSE 0 END) AS full_sales,
        SUM(CASE WHEN discount > 0 THEN profit ELSE 0 END) AS disc_profit,
        SUM(CASE WHEN discount > 0 THEN sales ELSE 0 END) AS disc_sales
    FROM general_store
    GROUP BY category
)
SELECT 
    category,
    full_profit,
    disc_profit,
    -- Simple subtraction without repeating code
    ROUND(full_profit - disc_profit, 2) AS difference_profit
FROM aggregated_margins
ORDER BY margin_drop_pct DESC;


-- Area 4 — Shipping and Operations

-- Average shipping days by ship mode — is express actually faster?

select `ship mode` as s_mode , avg(datediff(`ship date`, `order date`)) as avg_ship_time
from general_store
group by s_mode
order by avg_ship_time 
;

-- Which region has slowest shipping?

select `region`  , round(avg(datediff(`ship date`, `order date`)),2) as avg_ship_time
from general_store
group by region
order by avg_ship_time desc
;


-- Do delayed shipments correlate with lower repeat purchases?


WITH customer_metrics AS (
    SELECT 
        `customer id` AS c_id,
        -- Count unique shopping trips per customer
        COUNT(DISTINCT `order id`) AS total_orders,
        AVG(DATEDIFF(`ship date`, `order date`)) AS customer_avg_ship
    FROM general_store
    GROUP BY `customer id`
)
SELECT 
    CASE 
        WHEN customer_avg_ship >= 5 THEN 'Delayed Shipping (5+ Days)'
        WHEN customer_avg_ship >= 3 THEN 'Average Shipping (3-5 Days)'
        ELSE 'Fast Shipping (Under 3 Days)'
    END AS shipping_experience,
    -- Find the average number of lifetime repeat purchases for each group
    ROUND(AVG(total_orders), 2) AS avg_lifetime_orders,
    COUNT(*) AS total_customers_in_group
FROM customer_metrics
GROUP BY 1
ORDER BY avg_lifetime_orders DESC;

-- Which segment uses which shipping mode most?


with rankedd as (
select `segment` as seg , `Ship Mode`   as s_mode , count(*),
dense_rank() over(partition by Segment order by count(*) desc) as par
from general_store
group by seg, s_mode
)
select seg, s_mode, par
from rankedd
where par = 1

group by seg, s_mode
;





















