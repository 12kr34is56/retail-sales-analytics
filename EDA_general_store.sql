SELECT * FROM genernal_mart.general_store;

-- LEVEL 1

-- What is total revenue, total profit and overall profit margin?
SELECT 
    FORMAT(SUM(sales), 2) AS revenue,
    FORMAT(SUM(profit), 2) AS net_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin 
FROM general_store;


-- How many unique customers, orders and products exist?
 select count(distinct `customer id`) as customer_id from general_store;
 select count(distinct `order id`) as order_id from general_store;
 select count(distinct `product id`) as product_id from general_store;
 
 
 -- What is average order value? 
 select format(avg(total_receipt_amt),2) as avg_order_value
 from (
 select `order id`,  sum(sales) as total_receipt_amt, count(*)
 from general_store
 group by `order id`)
 as order_details
 ;
 

-- Calculating the Average Order Value broken down by Customer Segment?
SELECT 
    segment, 
    format(AVG(total_receipt_amt) ,2) as avg_by_segment
FROM (
    SELECT 
        segment,
        `order id`, 
        SUM(sales) AS total_receipt_amt
    FROM general_store 
    GROUP BY segment, `order id`
)  as subquery
GROUP BY segment;




-- What is average shipping time?
SELECT 
    ROUND(AVG((DATEDIFF(`Ship Date`, `Order Date`))),
            2) AS avg_shipping_days
FROM
    general_store;


-- LEVEL 2 Dimension Breakdown Questions

-- By Category
-- Which category generates most revenue?

select distinct category from general_store;

select  category, round(sum(sales),2) as highest_revenue
from general_store
group by Category
order by highest_revenue desc
limit 1
;


-- Which category is most profitable?


select  category, round(sum(profit),2) as highest_profit
from general_store
group by Category
order by highest_profit desc
limit 1
;


-- Which category has worst profit margin despite high sales?

select  category, round( (sum(profit)/sum(sales)) *100,2) as worst_perf_despite_high_sale
from general_store
group by Category
order by worst_perf_despite_high_sale 
limit 1;


-- region
-- Which region leads in revenue?

select region, round(sum(sales),2)  highest_region_revenue
from general_store
group by region
order by highest_region_revenue desc
limit 1
;


-- Which region has best profit margin?
select region, round((sum(profit)/sum(sales)),2)  highest_profit_margin_region
from general_store
group by region
order by highest_profit_margin_region desc
;


select  category, round(sum(sales),2) as highest_revenue
from general_store
where region = "west"
group by Category
order by highest_revenue desc
limit 1
;

-- region wise highest catgory sales

with ranked_sale as(
select region , category , format(sum(sales),2) as highest_revenue,
row_number() over(partition by region order by sum(sales) desc) as ranking
from general_store
group by region , category
order by region desc
) 
select region , category, highest_revenue
from ranked_sale
where ranking =1
;

-- Which region gives most discounts?
select  region, round(sum(discount),2) as highest_discount
from general_store
group by region
order by highest_discount desc
limit 1
;

-- By Segment

-- Consumer vs Corporate vs Home Office — who spends more?


select  segment, round(sum(sales),2) as high_expense
from general_store
group by segment
order by high_expense desc
limit 1
;

-- Which segment is most profitable?
select  
    segment, 
    format(sum(sales), 2) as total_sales,
    format(sum(profit), 2) as total_profit,
    format((sum(profit) / sum(sales)) * 100, 2) as profit_margin_percent -- using the code we can find the highest profitable segment 
from general_store
group by segment
order by profit_margin_percent desc;


SELECT 
    segment,
    ROUND(AVG(discount) * 100, 2) AS avg_discount_percent,
    ROUND(AVG(sales), 2) AS avg_order_value
FROM general_store
GROUP BY segment
ORDER BY avg_discount_percent ASC;

-- By Ship Mode

-- Which shipping mode is used most?
 select `ship mode` , count(*)  as counting
 from general_store
 group by `ship mode`
order by counting desc
;



-- Does faster shipping affect profit?
-- first find the fastest shipping

select `ship mode`, avg(datediff(`ship date`, `order date`)) as avg_time
from general_store
group by `Ship Mode`
;


 SELECT 
    `ship mode`,
    ROUND((SUM(profit) / SUM(sales) * 100), 2) AS profit_margin
FROM
    general_store
GROUP BY `ship mode`
ORDER BY profit_margin DESC
;




-- Level 3 — Time Based Questions

-- Which year had highest growth?

-- fail to get right answer

select distinct(substr(`order date`, 1,4))  as years , format((sum(profit)/sum(sales)*100),2) as profit_margin_per_year
from general_store
group by substr(`order date`, 1,4)
order by profit_margin_per_year desc
;


SELECT 
    substr(`order date`, 1, 4) AS years,
    format(SUM(sales), 2) AS total_sales,
    format(SUM(profit), 2) AS total_profit
FROM general_store
GROUP BY substr(`order date`, 1, 4)
ORDER BY years ASC;


WITH annual_totals AS (
    SELECT 
        SUBSTR(`order date`, 1, 4) AS sales_year,
        ROUND(SUM(sales), 2) AS current_year_sales
    FROM general_store
    GROUP BY SUBSTR(`order date`, 1, 4)
)
SELECT 
    sales_year,
    current_year_sales,
    -- Pulls the previous year's sales figure
    LAG(current_year_sales, 1) OVER (ORDER BY sales_year ASC) AS previous_year_sales,
    -- Calculates the percentage growth jump
    ROUND(
        ((current_year_sales - LAG(current_year_sales, 1) OVER (ORDER BY sales_year ASC)) 
        / LAG(current_year_sales, 1) OVER (ORDER BY sales_year ASC)) * 100, 
        2
    ) AS yoy_sales_growth_percent
FROM annual_totals
ORDER BY sales_year ASC;


-- Which months are consistently best?
-- logic
/*
first we will use the substring to fetch the month
then we use group by to sum sales as per month
then we may use subquery or cte where  when i create
above data fetch me max value from the or
i can simplly use sum sale value in desc and use limit 1
*/


with revenue_table as(

select substring(`order date`,6,2) as Months, round(sum(sales),2) as revenue_by_month
from general_store
group by substring(`order date`,6,2)
order by Months
),
Quartely as (select
case
      WHEN Months IN ('01', '02', '03') THEN 'Q1'
        WHEN Months IN ('04', '05', '06') THEN 'Q2'
        WHEN Months IN ('07', '08', '09') THEN 'Q3'
        WHEN Months IN ('10', '11', '12') THEN 'Q4'
END AS Quarter,
 FORMAT(SUM(revenue_by_month), 2) AS total_quarterly_sales
FROM revenue_table
GROUP BY Quarter
ORDER BY Quarter ASC
)

select Quarter,
format(total_quarterly_sales,2) as current_quarter_sales,
format (lag(total_quarterly_sales,1) over (order by Quarter ASC),2) as prv_quarter_sale,
  ROUND(
        ((total_quarterly_sales - LAG(total_quarterly_sales, 1) OVER (ORDER BY Quarter ASC)) 
        / LAG(total_quarterly_sales, 1) OVER (ORDER BY Quarter ASC)) * 100, 
        2
    ) AS qoq_growth_percent
    
    from Quartely
    order by Quarter asc;
;


-- Level 4 — Problems and Opportunities

-- Which products are selling well but losing money?

/*
fetch distinct value of product -> sum of thier sale using group by of them and i will see profit margin how much money i earing overall 
then i will put highest sale and lowest profit using the order by( can i put two value let's find put 😁😁)

*/
select  `product name`, round (sum(sales),2) as prd_sale, round ((sum(profit)/sum(sales)*100),2) as prd_margin
from general_store
group by `product name`
HAVING SUM(profit) < 0
order by prd_margin asc
limit 50
;


-- At what discount level does profit turn negative?

/*
logic
we can find out cp using the sale and profit value then 
we will find out if actual value of discount of product is more cp of that product then the profit will be negative 

*/
SELECT 
    discount,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales) * 100), 2) AS group_profit_margin
FROM general_store
GROUP BY discount
ORDER BY discount ASC;


-- Which sub-categories are consistently loss making?

select `sub-category` ,  ROUND((SUM(profit) / SUM(sales) * 100), 2) AS sub_category_profit_margin
from general_store
group by `sub-category`
order by sub_category_profit_margin
;

-- Which region + category combination is most problematic?

select region , category ,ROUND((SUM(profit) / SUM(sales) * 100), 2) AS profit_margin
from general_store
group by region, category
having ROUND((SUM(profit) / SUM(sales) * 100), 2) < 5
order by region
;
 
-- Are there customers who only buy on heavy discounts?
/*
i can create two list or temp table where in one have customer name of discount from 0 <=50 
and other table cusotomer name dicount 50<= discount and fill find out 
if thier is an dupluicate in  t2  then will remove when showing the result
*/


SELECT 
    `customer name`,
    COUNT(`order id`) AS total_orders_placed,
    ROUND(AVG(discount) * 100, 2) AS avg_discount_received,
    MIN(discount) AS lowest_discount_they_ever_accepted
FROM general_store
GROUP BY `customer name`
HAVING MIN(discount) >= 0.3
ORDER BY total_orders_placed DESC;






