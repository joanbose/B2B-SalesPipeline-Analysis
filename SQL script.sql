-- i created a new data base then i called for all my tables
create database capstoneproject
use capstoneproject;

select * from accounts;
select * from sales_pipeline;
select * from sales_teams;
select * from products;

-- created backups for all 4 tables
-- backup for accounts
select * 
into account1
from accounts;

select * 
into sales_pipeline2
from sales_pipeline;

select * 
into sales_teams2
from sales_teams;

select * 
into products2
from products;
-- called for all the tables to be use nothing was missing
select * from accounts1;
select * from sales_pipeline1;
select * from sales_teams1;
select * from products1;

-- checking for duplicates for each table
select *,
row_number() over(partition by opportunity_id,sales_agent, 
product, account,deal_stage order by opportunity_id )
from sales_pipeline1;

select *,
row_number() over(partition by regional_office,sales_agent, 
manager order by sales_agent )
from sales_teams1;

select *,
row_number() over(partition by sector,year_established, 
office_location, account order by account)
from accounts1;
-- next checked for in consistent letters spaces and blanks only the account table had one in the sector
select sector,
trim(upper(left(sector,1))) + lower(substring(sector,2, len(sector)))
from accounts1;
update accounts1
set sector = trim(upper(left(sector,1))) + lower(substring(sector,2, len(sector)));

-- checking for number of nulls in all column

SELECT
    SUM(CASE WHEN opportunity_id IS NULL THEN 1 ELSE 0 END) AS null_opp_id,
    SUM(CASE WHEN sales_agent    IS NULL THEN 1 ELSE 0 END) AS null_agent,
    SUM(CASE WHEN product        IS NULL THEN 1 ELSE 0 END) AS null_product,
    SUM(CASE WHEN account        IS NULL THEN 1 ELSE 0 END) AS null_account,
    SUM(CASE WHEN deal_stage     IS NULL THEN 1 ELSE 0 END) AS null_stage,
    SUM(CASE WHEN engage_date    IS NULL THEN 1 ELSE 0 END) AS null_engage_date,
    SUM(CASE WHEN close_date     IS NULL THEN 1 ELSE 0 END) AS null_close_date,
    SUM(CASE WHEN close_value    IS NULL THEN 1 ELSE 0 END) AS null_close_value
FROM sales_pipeline1;


-- i check for the data types in each table
exec sp_help sales_pipeline1;
exec sp_help accounts1;
exec sp_help sales_teams1;
exec sp_help products1;
-- i noticed that the close value was not in the right data type 
-- checking for distinct close value
SELECT DISTINCT close_value
FROM sales_pipeline1
ORDER BY close_value;

-- checking for null and blank spaces 
  SELECT
    SUM(CASE 
        WHEN close_value IS NULL THEN 1 
        ELSE 0 
    END) AS null_values,

    SUM(CASE 
        WHEN LTRIM(RTRIM(close_value)) = '' THEN 1 
        ELSE 0 
    END) AS blank_values
FROM sales_pipeline1;

-- changing the data type for closeValue because it was the only datatype that was not correct
select close_value, cast(close_value as decimal(18,2)) from sales_pipeline1;

update sales_pipeline1
set close_value = cast(close_value as decimal(18,2)) from sales_pipeline1;

alter table sales_pipeline
alter column close_value decimal(18,2);
-- i alled for it again to  confirm
exec sp_help sales_pipeline1;

-- counting of the different deal stage
select deal_stage, COUNT(deal_stage) from sales_pipeline1
group by deal_stage;


-- checking for number of nulls in all column

SELECT
    SUM(CASE WHEN opportunity_id IS NULL THEN 1 ELSE 0 END) AS null_opp_id,
    SUM(CASE WHEN sales_agent    IS NULL THEN 1 ELSE 0 END) AS null_agent,
    SUM(CASE WHEN product        IS NULL THEN 1 ELSE 0 END) AS null_product,
    SUM(CASE WHEN account        IS NULL THEN 1 ELSE 0 END) AS null_account,
    SUM(CASE WHEN deal_stage     IS NULL THEN 1 ELSE 0 END) AS null_stage,
    SUM(CASE WHEN engage_date    IS NULL THEN 1 ELSE 0 END) AS null_engage_date,
    SUM(CASE WHEN close_date     IS NULL THEN 1 ELSE 0 END) AS null_close_date,
    SUM(CASE WHEN close_value    IS NULL THEN 1 ELSE 0 END) AS null_close_value
FROM sales_pipeline1;

-- checking for won deals without close value
SELECT COUNT(*) AS won_without_value
FROM sales_pipeline1
WHERE deal_stage = 'Won' AND close_value IS NULL;

-- checking for null values using the deal stage as goup by
SELECT deal_stage,
       COUNT(*) AS total,
       SUM(CASE WHEN close_date IS NULL THEN 1 ELSE 0 END) AS null_close_date
FROM sales_pipeline1
GROUP BY deal_stage;

-- checking for nulls in close value using lost deals  as filter
SELECT
    COUNT(*) AS lost_deals,
    SUM(CASE WHEN close_value IS NULL THEN 1 ELSE 0 END) AS lost_null,
    SUM(CASE WHEN close_value = 0 THEN 1 ELSE 0 END) AS lost_zero,
    SUM(CASE WHEN close_value > 0 THEN 1 ELSE 0 END) AS lost_positive
FROM sales_pipeline1
WHERE deal_stage = 'Lost';

-- checking if open deals has value on its close value
SELECT deal_stage, COUNT(*) AS deals_with_value
FROM sales_pipeline1
WHERE deal_stage IN ('Prospecting', 'Engaging')
  AND close_value IS NOT NULL
GROUP BY deal_stage;

-- checking if close value is missing for any won deal
SELECT COUNT(*) AS won_without_value
FROM sales_pipeline1
WHERE deal_stage = 'Won' AND close_value IS NULL;

-- checking to see if all columns and rows in other tables matched the same in the salespipeline
-- Agents with no match in sales_teams
SELECT DISTINCT o.sales_agent
FROM sales_pipeline1 o
LEFT JOIN sales_teams t ON o.sales_agent = t.sales_agent
WHERE t.sales_agent IS NULL;

-- Products with no match in products
SELECT DISTINCT o.product
FROM sales_pipeline1 o
LEFT JOIN products p ON o.product = p.product
WHERE p.product IS NULL;

-- Accounts with no match in accounts
SELECT DISTINCT o.account
FROM sales_pipeline1 o
LEFT JOIN accounts a ON o.account = a.account
WHERE a.account IS NULL;
-- i noticed that a product had a different spelling in both the product table and sales_pipeline
-- Product names as they appear in opportunities (with deal counts)
SELECT product, LEN(product) AS name_length, COUNT(*) AS deals
FROM sales_pipeline1
GROUP BY product
ORDER BY product;

-- Product names in the products table
SELECT product, LEN(product) AS name_length
FROM products
ORDER BY product;

-- Preview: which rows will change?
SELECT opportunity_id, product
FROM sales_pipeline1
WHERE product = 'GTXPro';

update sales_pipeline1
set product = 'GTX Pro'
where product = 'GTXPro';


-- next i joined all tables using the left join
SELECT
    o.opportunity_id,
    o.sales_agent,
    t.manager,
    t.regional_office,
    o.product,
    p.series,
    p.sales_price,
    o.account,
    a.sector,
    a.year_established,
    a.revenue   AS account_revenue,  
    a.employees,
    a.office_location,
    a.subsidiary_of,
    o.deal_stage,
    o.engage_date,
    o.close_date,
    o.close_value 
INTO sales_pipeline_clean
FROM sales_pipeline1 as o
LEFT JOIN sales_teams as t ON o.sales_agent = t.sales_agent
LEFT JOIN products   as  p ON o.product     = p.product
LEFT JOIN accounts   as  a ON o.account     = a.account;
-- calling for joined tables
select 

-- validate joined tables
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT opportunity_id) AS unique_opportunities
FROM sales_pipeline_clean;
-- examine the sales stages
SELECT
    deal_stage,
    COUNT(*) AS total_opportunities,
    SUM(close_value) AS total_close_value
FROM sales_pipeline_clean
GROUP BY deal_stage
ORDER BY total_opportunities DESC;

-- Check the number of won, lost, and open deals
SELECT
    deal_stage,
    COUNT(*) AS total_opportunities
FROM sales_pipeline_clean
GROUP BY deal_stage
ORDER BY total_opportunities DESC;

-- KPIs
SELECT
    COUNT(*)                                                     AS total_deals,
    SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END)          AS deals_won,
    SUM(CASE WHEN deal_stage = 'Lost' THEN 1 ELSE 0 END)         AS deals_lost,
    SUM(CASE WHEN deal_stage IN ('Engaging','Prospecting') THEN 1 ELSE 0 END) AS open_deals,
    SUM(CASE WHEN deal_stage = 'Won' THEN close_value ELSE 0 END) AS total_revenue,
    AVG(CASE WHEN deal_stage = 'Won' THEN close_value END)       AS avg_deal_size,
    CAST(SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS DECIMAL(10,4))
        / NULLIF(SUM(CASE WHEN deal_stage IN ('Won','Lost') THEN 1 ELSE 0 END), 0) AS win_rate
FROM sales_pipeline_clean;

-- sales agents performance from top to bottom
SELECT
    sales_agent,
COUNT(*) AS total_opportunities,
SUM(CASE
        WHEN deal_stage = 'Won' THEN 1
        ELSE 0
    END) AS won_deals,
SUM(CASE
        WHEN deal_stage = 'Lost' THEN 1
        ELSE 0
    END) AS lost_deals,
CAST(
        100.0 * SUM(CASE
            WHEN deal_stage = 'Won' THEN 1
            ELSE 0
        END)
        / NULLIF(
            SUM(CASE
                WHEN deal_stage IN ('Won', 'Lost') THEN 1
                ELSE 0
            END), 0
        )
        AS DECIMAL(5,2)
    ) AS win_rate_percentage,
SUM(CASE
        WHEN deal_stage = 'Won' THEN close_value
        ELSE 0
        END) AS total_won_revenue
FROM sales_pipeline_clean
GROUP BY sales_agent
ORDER BY total_won_revenue DESC;
-- i checked manager with the most won deal, revenue and win rate
SELECT
    manager,
    regional_office,
    SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END)           AS deals_won,
    SUM(CASE WHEN deal_stage = 'Won' THEN close_value ELSE 0 END)  AS revenue,
    AVG(CASE WHEN deal_stage = 'Won' THEN close_value END)         AS avg_deal_size,
    CAST(SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS DECIMAL(10,4))
        / NULLIF(SUM(CASE WHEN deal_stage IN ('Won','Lost') THEN 1 ELSE 0 END), 0) AS win_rate
FROM sales_pipeline_clean
GROUP BY manager, regional_office
ORDER BY revenue DESC;

-- which product generates the most revenue

SELECT
    product,
COUNT(*) AS total_opportunities,
SUM(CASE
        WHEN deal_stage = 'Won' THEN 1
        ELSE 0
    END) AS won_deals,
SUM(CASE
        WHEN deal_stage = 'Lost' THEN 1
        ELSE 0
    END) AS lost_deals,
SUM(CASE
        WHEN deal_stage = 'Won' THEN close_value
        ELSE 0
    END) AS total_won_revenue
FROM sales_pipeline_clean
GROUP BY product
ORDER BY total_won_revenue DESC;

-- which product generates the most revenue

SELECT
    product,
COUNT(*) AS total_opportunities,
SUM(CASE
        WHEN deal_stage = 'Won' THEN 1
        ELSE 0
    END) AS won_deals,
SUM(CASE
        WHEN deal_stage = 'Lost' THEN 1
        ELSE 0
    END) AS lost_deals,
SUM(CASE
        WHEN deal_stage = 'Won' THEN close_value
        ELSE 0
    END) AS total_won_revenue
FROM sales_pipeline_clean
GROUP BY product
ORDER BY total_won_revenue DESC;

-- product win rate

SELECT
    product,

    COUNT(*) AS total_opportunities,

    SUM(CASE
        WHEN deal_stage = 'Won' THEN 1
        ELSE 0
    END) AS won_deals,

    SUM(CASE
        WHEN deal_stage IN ('Won', 'Lost') THEN 1
        ELSE 0
    END) AS closed_deals,

    CAST(
        100.0 * SUM(CASE
            WHEN deal_stage = 'Won' THEN 1
            ELSE 0
        END)
        / NULLIF(
            SUM(CASE
                WHEN deal_stage IN ('Won', 'Lost') THEN 1
                ELSE 0
            END), 0
        )
        AS DECIMAL(5,2)
    ) AS win_rate_percentage,

    SUM(CASE
        WHEN deal_stage = 'Won' THEN close_value
        ELSE 0
    END) AS total_won_revenue,

    CAST(
        AVG(CASE
            WHEN deal_stage = 'Won' THEN close_value
        END) AS DECIMAL(18,2)
    ) AS average_won_deal_value

FROM sales_pipeline_clean
GROUP BY product
ORDER BY total_won_revenue DESC;

-- which customer sector generate the most revenue

SELECT
    sector,COUNT(*) AS total_opportunities,

    SUM(CASE
        WHEN deal_stage = 'Won' THEN 1
        ELSE 0
    END) AS won_deals,

    SUM(CASE
        WHEN deal_stage IN ('Won', 'Lost') THEN 1
        ELSE 0
    END) AS closed_deals,

    CAST(
        100.0 * SUM(CASE
            WHEN deal_stage = 'Won' THEN 1
            ELSE 0
        END)
        / NULLIF(
            SUM(CASE
                WHEN deal_stage IN ('Won', 'Lost') THEN 1
                ELSE 0
            END), 0
        )
        AS DECIMAL(5,2)
    ) AS win_rate_percentage,

    SUM(CASE
        WHEN deal_stage = 'Won' THEN close_value
        ELSE 0
    END) AS total_won_revenue

FROM sales_pipeline_clean
GROUP BY sector
ORDER BY total_won_revenue DESC;

--Which regional office generates the most revenue?
--Which regional office has the highest win rate?


SELECT
    regional_office,
    COUNT(*) AS total_opportunities,

    SUM(CASE
        WHEN deal_stage = 'Won' THEN 1
        ELSE 0
    END) AS won_deals,
SUM(CASE
        WHEN deal_stage IN ('Won', 'Lost') THEN 1
        ELSE 0
    END) AS closed_deals,

    CAST(
        100.0 * SUM(CASE
            WHEN deal_stage = 'Won' THEN 1
            ELSE 0
        END)
        / NULLIF(
            SUM(CASE
                WHEN deal_stage IN ('Won', 'Lost') THEN 1
                ELSE 0
            END), 0
        )
        AS DECIMAL(5,2)
    ) AS win_rate_percentage,
 SUM(CASE
        WHEN deal_stage = 'Won' THEN close_value
        ELSE 0
    END) AS total_won_revenue
FROM sales_pipeline_clean
GROUP BY regional_office
ORDER BY total_won_revenue DESC;

-- Compare average deal value by region


SELECT
    regional_office,
    SUM(CASE
        WHEN deal_stage = 'Won' THEN 1
        ELSE 0
    END) AS won_deals,
    SUM(CASE
        WHEN deal_stage = 'Won' THEN close_value
        ELSE 0
    END) AS total_won_revenue,
    CAST(
        AVG(CASE
            WHEN deal_stage = 'Won' THEN close_value
        END) AS DECIMAL(18,2)
    ) AS average_won_deal_value
FROM sales_pipeline_clean
GROUP BY regional_office
ORDER BY total_won_revenue DESC;

-- sales performance over time

SELECT
    YEAR(close_date) AS sales_year,
    MONTH(close_date) AS sales_month,

    COUNT(CASE
        WHEN deal_stage = 'Won' THEN 1
    END) AS won_deals,

    SUM(CASE
        WHEN deal_stage = 'Won' THEN close_value
        ELSE 0
    END) AS total_won_revenue

FROM sales_pipeline_clean

WHERE close_date IS NOT NULL
  AND deal_stage IN ('Won', 'Lost')

GROUP BY
    YEAR(close_date),
    MONTH(close_date)

ORDER BY
    sales_year,
    sales_month;














