-- Find Losing Transactions First

SELECT 
    COUNT(*) AS total_losing_rows,
    COUNT(DISTINCT `order id`) AS total_losing_orders,
    ROUND(SUM(profit), 2) AS total_money_lost,
    ROUND(AVG(discount) * 100, 1) AS avg_discount_on_losses
FROM general_store
WHERE profit < 0;

-- Cause 1 → Too high discount selling below cost to acquire customer ✔
select 
case
	when discount =0 then '0% (No Discount)'
    when discount <=0.2 then "1-20% (Low discount)"    
    when discount <=0.4 then "21-40% (Medium discount)"  
    else '41% (Heavy discount)'
end as discount_tier,
count(*),
format(sum(profit),2) as total_profit
from general_store
group by discount_tier
order by discount_tier ;


SELECT 
    category,
    `sub-category` AS sub_cat,
    COUNT(*) AS heavy_discount_orders,
    FORMAT(SUM(profit), 2) AS total_loss
FROM general_store
WHERE discount > 0.40 -- Focuses exactly on your worst tier
GROUP BY category, sub_cat
ORDER BY SUM(profit) ASC; -- Shows worst losses first

SELECT 
    region,
    COUNT(*) AS heavy_discount_orders,
    FORMAT(SUM(profit), 2) AS total_loss,
    ROUND(AVG(discount) * 100, 1) AS avg_discount_pct
FROM general_store
WHERE discount > 0.40
GROUP BY region
ORDER BY SUM(profit) ASC;


/*
Cause 2 → Wrong product mix
          Some products have negative margin
          regardless of discount ❌
*/

select category, 
		`sub-category` as sub_cat,
         COUNT(*) AS regular_orders_losing_money,
        round(sum(profit),2) as profit_leak
from general_store
where profit <0  and Discount = 0
group by category, sub_cat
order by Category;
;


/*
Cause 3 → Wrong region + product combination
          Shipping costs eating into margin
          in specific geographies
*/

SELECT 
    region,
    `product name` AS p_name,
    `sub-category` AS sub_cat,
    COUNT(*) AS total_orders_placed,
    ROUND(AVG(discount) * 100, 1) AS avg_regional_discount_pct,
    FORMAT(SUM(profit), 2) AS net_total_profit
from general_store
group by region,p_name,sub_cat
HAVING SUM(profit) < 0 -- Filters for combinations that lose money as a whole group
ORDER BY SUM(profit) ASC;



-- Which individual rows have negative profit?
WITH unique_orders AS (
    SELECT 
        *,
        ROW_NUMBER() OVER(PARTITION BY `order id` ORDER BY profit ASC) AS row_num
    FROM general_store
    WHERE profit < 0 AND discount > 0 -- Focuses purely on discount leaks
)
SELECT * 
FROM unique_orders
WHERE row_num = 1
ORDER BY profit ASC;

-- How many transactions are losing money?
SELECT 
    (SELECT COUNT(*) FROM general_store WHERE profit < 0) * 100.0 / COUNT(*) AS per_of_loss
FROM 
    general_store;
    
-- What is total loss amount?

select round(sum(profit),2) as total_loss
from general_store
where profit<0;

-- Phase 3 — Drill Down by Each Dimension
-- Question → Which category loses most money?

-- By Category
select category , round(sum(profit),2) as cat_loss
from general_store
where profit <0
group by category
;
-- answer Furniture with value of -60,924

-- By Sub Category
select `sub-category` as sub_cat , round(sum(profit),2) as sub_cat_loss
from general_store
where profit <0
group by sub_cat
order by sub_cat_loss 
;
-- answer binder

-- both category and sub category
with ranked_category as (
SELECT 
    category,
    `sub-category` AS sub_cat,
    ROUND(SUM(profit), 2) AS both_cat_loss,
    row_number () over(partition by `category` order by (SUM(profit)) ) as ranked_row
FROM
    general_store
WHERE
    profit < 0
GROUP BY category , sub_cat
)
select category, sub_cat, both_cat_loss
from ranked_category
where ranked_row = 1
ORDER BY both_cat_loss
;

-- answer 
/*
Office Supplies ->	Binders	-38510.5
Furniture ->	Tables	-32412.15
Technology ->	Machines	-30118.67
*/

-- by region
select `region` as region , round(sum(profit),2) as region_loss
from general_store
where profit <0
group by region
order by region_loss 
;

-- all combo of region, cate , sub-cate

with ranked_category as (
SELECT 
 region,
    category,
    `sub-category` AS sub_cat,
    (SUM(profit)) AS total_loss,
    row_number () over(partition by region order by (SUM(profit)) ) as ranked_row
FROM
    general_store
WHERE
    profit < 0
GROUP BY region,category , sub_cat
)
select region,category, sub_cat, total_loss
from ranked_category
where ranked_row = 1
ORDER BY total_loss
;

-- answer 
/*
Central	Office Supplies	Binders	-21909.398
East	Technology	Machines	-13990.1903
South	Furniture	Tables	-8840.7788
West	Furniture	Tables	-5956.667100000002
*/


-- by segment

select segment , round(sum(profit),2) as segment_loss
from general_store
where profit <0
group by segment
order by segment_loss 
;

-- answer 
/*
Consumer	-84945.71
Corporate	-44787.21
Home Office	-26386.31
*/


SELECT 
    CASE
        WHEN discount = 0 THEN '0% discount'
        WHEN discount > 0 AND discount <= 0.1 THEN '1 to 10% discount'
        WHEN discount > 0.1 AND discount <= 0.2 THEN '10 to 20% discount'
        WHEN discount > 0.2 AND discount <= 0.3 THEN '20 to 30% discount'
        WHEN discount > 0.3 AND discount <= 0.4 THEN '30 to 40% discount'
        ELSE '40%+ discount'
    END discount_bucket,
    ROUND(AVG(profit), 2) AS average_profit,
    COUNT(*) AS total_transactions
    from general_store
    group by discount_bucket
    order by discount_bucket;
    
    
    
-- total combo

WITH global_losses AS (
    SELECT 
        region,
        category,
        `sub-category` AS sub_cat,
        SUM(profit) AS raw_loss,
        CASE
            WHEN discount = 0 THEN '0% discount'
            WHEN discount > 0 AND discount <= 0.1 THEN '1 to 10% discount'
            WHEN discount > 0.1 AND discount <= 0.2 THEN '10 to 20% discount'
            WHEN discount > 0.2 AND discount <= 0.3 THEN '20 to 30% discount'
            WHEN discount > 0.3 AND discount <= 0.4 THEN '30 to 40% discount'
            ELSE '40%+ discount'
        END AS discount_bucket
    FROM
        general_store
    GROUP BY region, category, `sub-category`, discount_bucket
    HAVING SUM(profit) < 0 -- Accurately grabs net-negative groups
)
SELECT 
    ROW_NUMBER() OVER(ORDER BY raw_loss ASC) AS `Rank`, -- Generates clean 1 to 10 numbering
    region AS `Region`,
    category AS `Category`,
    sub_cat AS `Sub-Cat`,
    CASE 
        WHEN discount_bucket IN ('30 to 40% discount', '40%+ discount') THEN 'High'
        WHEN discount_bucket IN ('10 to 20% discount', '20 to 30% discount') THEN 'Medium'
        ELSE 'Low'
    END AS `Disc Bucket`,
    CONCAT('-$', FORMAT(ABS(raw_loss), 2)) AS `Total Loss` 
FROM global_losses
ORDER BY raw_loss ASC
LIMIT 10; -- Keeps exactly the 10 worst entries globally


-- answer 

/*
1	Central	Office Supplies	Binders	High	-$21,909.40
2	East	Technology	Machines	High	-$13,990.19
3	East	Furniture	Tables	High	-$9,839.73
4	Central	Office Supplies	Appliances	High	-$8,629.64
5	South	Office Supplies	Binders	High	-$8,404.47
6	South	Technology	Machines	High	-$7,635.23
7	East	Technology	Phones	High	-$6,385.79
8	South	Furniture	Tables	High	-$6,347.67
9	East	Office Supplies	Binders	High	-$5,971.64
10	Central	Furniture	Furnishings	High	-$5,944.66
*/

-- -- Phase 5 — Quantify the Damage (The Queries)Query 1: Overall Scale (Total Loss, % of Revenue Lost, Affected Customers)


SELECT 
    CONCAT('-$', FORMAT(ABS(SUM(profit)), 2)) AS total_profit_loss,
    ROUND((ABS(SUM(profit)) / (SELECT SUM(sales) FROM general_store)) * 100, 2) AS percent_of_total_revenue_lost,
    COUNT(DISTINCT `customer id`) AS customers_affected -- Swap with your actual customer ID column name
FROM 
    general_store
WHERE 
    profit < 0;
 -- answer -$156,119.23	, 6.8	 ,638

-- Query 2: Policy Simulation 1 (Stopping discounts > 30%)This query simulates how much bleeding is stopped if management bans high discounts.

SELECT 
    CONCAT('$', FORMAT(ABS(SUM(profit)), 2)) AS loss_recovered_if_discount_capped_at_30
FROM 
    general_store
WHERE 
    profit < 0 
    AND discount > 0.30;
-- answer $127,737.56



-- Query 3: Policy Simulation 2 (Stopping Tables in Central)This isolates the exact amount of money you would claw back by removing Tables from the Central region's catalog.

SELECT 
    CONCAT('$', FORMAT(ABS(SUM(profit)), 2)) AS loss_recovered_from_central_tables,
    COUNT(*) AS orders_affected
FROM 
    general_store
WHERE 
    region = 'Central'
    AND `sub-category` = 'Tables'
    AND profit < 0;
    
    
    
-- answer $6,568.36	,49


-- The Discount Tipping Point
SELECT 
    discount, ROUND(AVG(profit), 2) AS average_profit
FROM
    general_store
GROUP BY discount
ORDER BY discount ASC;

-- answer 
/*
0	66.9
0.1	96.06
0.15	27.29
0.2	24.7
0.3	-45.83
0.32	-88.56
0.4	-111.93
0.45	-226.65
0.5	-310.7
0.6	-43.08
0.7	-95.87
0.8	-101.8
*/


/*
Phase 6 — Business Recommendations (Executive Brief)
Recommendation 1 → Eradicate Deep Promotional DiscountingProblem 
→ Aggressive discounting is entirely wiping out store profitability and creating a hidden deficit.Evidence 
→ The business is losing a massive $156,119.23 on negative transactions, which represents a leakage of 6.8% 
of total store revenue across 638 affected customers. Crucially, 81.8% of this entire loss ($127,737.56) occurs 
strictly on transactions with discounts exceeding 30%.Action → Implement an immediate automated system hard-cap 
in the checkout POS architecture to block any manual or promotional discounts above 30% across all product lines.
Impact → Instant recovery of up to $127,737.56 in profit, instantly stabilizing the company's gross margins without 
altering base product pricing.

Recommendation 2 → Restructure or Suspend Central Region Table SalesProblem 
→ The "Tables" sub-category within the Central territory operates at a structurally unviable loss, acting as a direct 
drain on local operational capital.Evidence → Sub-category tracking isolated a net loss of $6,568.36 spread across 49 
fully bleeding orders inside the Central region alone.Action → Cease selling the Tables product line in the Central 
region entirely, or enforce a mandatory order rule requiring a minimum purchase volume combined with zero promotional 
discount options to offset freight-shipping overhead.Impact → Recovers $6,568.36 in localized bottom-line cash while 
saving operations from fulfilling 49 highly inefficient, margin-negative supply chain shipments.

Recommendation 3 → Re-Anchor the Corporate Discounting Policy LineProblem 
→ The current sales discounting framework lacks a clear safeguard boundary, allowing sales teams to push promotions past 
the commercial breaking point.Evidence → Transactional averages pinpoint the exact discount tipping point between 20% and 30%. 
At a 20% discount, the store safely maintains a healthy positive average profit of $24.70 per sale. However, crossing into a 
30% discount causes average profit to collapse into a net loss of -$45.83, accelerating downwards to -$310.70 at a 50% discount.
Action → Formally update corporate sales policy to mandate a strict maximum discount limit of 20% for all everyday sales negotiations. 
Require regional VP approval for any exception exceeding this threshold.Impact → Hard-stops systemic margin erosion at the source, 
ensuring every standard transaction closed by the sales floor remains structurally profitable

*/
