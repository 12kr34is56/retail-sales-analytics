-- Phase 1 — Understand Your Customer Data First

-- Question 1 — What is your date range?
select `customer name`,
MAX(`order date`) AS last_purchase_date,
DATEDIFF((SELECT MAX(`order date`) FROM general_store), MAX(`order date`)) AS recency_days
from general_store
group by `customer name`
order by recency_days 
;
-- Question 2 — How many unique customers?
select count(distinct `customer name`) 
from general_store;
-- Question 3 — What does one row mean?

with sorted_table as(
select *,
row_number() over(partition by `customer name` order by `order id` desc) as rw_no
from general_store
)
select *
from sorted_table
where rw_no =1
order by `row id`
;

-- Phase 2 — Calculate Raw RFM Values
-- conversion rfm raw -> scores 

WITH raw_rfm AS (
    SELECT 
        `customer name` AS customer_name,
        DATEDIFF((SELECT MAX(`order date`) FROM general_store), MAX(`order date`)) AS recency,
        COUNT(DISTINCT `order id`) AS frequency,
        ROUND(SUM(sales), 2) AS monetary
    FROM general_store
    GROUP BY `customer name`
),
rfm_raw_table as(
SELECT 
    customer_name,
    recency,
    frequency,
    monetary,
    -- 1 = bought long ago, 4 = bought very recently
    NTILE(4) OVER (ORDER BY recency DESC) AS r_score,
    -- 1 = rarely buys, 4 = buys frequently
    NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
    -- 1 = low spender, 4 = high spender
    NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
FROM raw_rfm
),
rfm_final_table as(
select
 customer_name,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    case
        WHEN r_score = 4 AND f_score = 4 AND m_score = 4 THEN 'A_ Champion'
        WHEN r_score = 4 AND f_score >= 3 AND m_score = 4 THEN 'B_ Loyal Customer'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'C_Potential Loyalist'
        WHEN r_score = 4 AND f_score = 1 THEN 'D_New Customer'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'E_At Risk Customer'
        WHEN r_score = 1 AND f_score = 1 THEN 'F_Lost Customer'
        ELSE 'Regular Shopper' 
end as customer_segment
from 
rfm_raw_table
) , 
final_table as(
SELECT 
    customer_segment,
    COUNT(*) AS total_customers,
    round(SUM(monetary), 2) AS total_revenue,
    
    round(AVG(monetary), 2) AS avg_customer_spend
FROM rfm_final_table
GROUP BY customer_segment
)
select customer_segment,
round((total_revenue/ sum(total_revenue)over()*100),2) as per_contribute,
round((total_customers/ sum(total_customers)over()*100),2) as per_engage
from final_table
group by customer_segment
order by customer_segment

;


-- Phase 5 — Business Summary Query

-- What % of total revenue does each segment contribute?




