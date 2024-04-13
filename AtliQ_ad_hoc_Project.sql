use gdb023;

-- 1) Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

Select DISTINCT market 
FROM dim_customer
WHERE customer = "Atliq Exclusive" and region = "APAC";

-- 2) What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

WITH CTE1 AS(
	SELECT COUNT(DISTINCT product_code) unique_product_2020
	FROM fact_sales_monthly
	WHERE fiscal_year = 2020),

CTE2 AS(
	SELECT COUNT(DISTINCT product_code) unique_product_2021
	FROM fact_sales_monthly
	WHERE fiscal_year = 2021)

SELECT
	unique_product_2020,
    unique_product_2021,
    ROUND((unique_product_2021 - unique_product_2020) * 100 / unique_product_2020, 2) as percentage_chg
FROM CTE1
JOIN CTE2;

-- 3) Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.The final output contains 2 fields,
-- segment
-- product_count

SELECT
	segment,
	COUNT(DISTINCT product_code) as product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- 4) Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

WITH CTE1 AS (
	SELECT
		p.segment,
		COUNT(DISTINCT p.product_code) as product_count_2020
	FROM dim_product p
	JOIN fact_sales_monthly s
		ON p.product_code = s.product_code
	WHERE fiscal_year = 2020
	GROUP BY p.segment),

CTE2 AS (
	SELECT
		p.segment,
		COUNT(DISTINCT p.product_code) as product_count_2021
	FROM dim_product p
	JOIN fact_sales_monthly s
		ON p.product_code = s.product_code
	WHERE fiscal_year = 2021
	GROUP BY p.segment)

SELECT
	CTE1.segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) as Difference
FROM CTE1
JOIN CTE2
	on CTE1.segment = CTE2.segment
ORDER BY Difference DESC;

-- 5) Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

SELECT
	p.product_code,
    p.product,
    c.manufacturing_cost
FROM
	dim_product p
JOIN
	fact_manufacturing_cost c
	on p.product_code = c.product_code
WHERE
	c.manufacturing_cost = ( 
    SELECT max(manufacturing_cost)
		FROM fact_manufacturing_cost)
	OR
		c.manufacturing_cost = (
    SELECT min(manufacturing_cost)
		FROM fact_manufacturing_cost);

-- 6) Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

SELECT	
	c.customer_code,
    c.customer,
    d.pre_invoice_discount_pct AS average_discount_percentage
FROM 
	dim_customer c
JOIN
	fact_pre_invoice_deductions d
	ON c.customer_code = d.customer_code
WHERE
	pre_invoice_discount_pct > (
		SELECT avg(pre_invoice_discount_pct)
			FROM fact_pre_invoice_deductions
            )
	AND
	c.market = "india" AND d.fiscal_year = 2021
ORDER BY average_discount_percentage DESC
LIMIT 5;

-- 7) Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions. The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

SELECT
	monthname(s.date) as Month,
    year(s.date) as Year,
    round(sum(gross_price * sold_quantity),2) as Gross_sales_Amount
FROM
	dim_customer c
JOIN 
	fact_sales_monthly s
    ON c.customer_code = s.customer_code
JOIN
	fact_gross_price g
    ON g.product_code = s.product_code
WHERE customer = "Atliq Exclusive"
GROUP BY s.date;
    
-- 8) In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity

SELECT 
	CASE 
		WHEN month(s.date) IN (9,10,11) THEN "Q1"
        WHEN month(s.date) IN (12,1,2) THEN "Q2"
        WHEN month(s.date) IN (3,4,5) THEN "Q3"
        WHEN month(s.date) IN (6,7,8) THEN "Q4"
        END AS Quarter,
        concat(FORMAT(SUM(s.sold_quantity) / 1000000 , 2) , " M") AS Total_sold_quantity
from fact_sales_monthly s
where s.fiscal_year = '2020'
GROUP BY Quarter
ORDER BY Total_sold_quantity DESC;


-- 9) Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

with CTE AS (
	SELECT
		c.channel,
		concat(round(sum(gross_price * sold_quantity) / 1000000 ,2), " M") as Gross_sales_mil
	FROM 
		dim_customer c
		JOIN fact_sales_monthly s ON c.customer_code = s.customer_code
		JOIN fact_gross_price g ON s.product_code = g.product_code
	WHERE
		s.fiscal_year = 2021
	GROUP BY
		c.channel
	ORDER BY Gross_sales_mil DESC)
    
SELECT 
	channel,
    Gross_sales_mil,
    CONCAT(ROUND((Gross_sales_mil * 100) / SUM(Gross_sales_mil) OVER() , 2), " %") AS Percentage
FROM CTE;

-- 10) Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
-- division
-- product_code

WITH CTE AS (
SELECT
	p.division,
    p.product_code,
    p.product,
    SUM(s.sold_quantity) AS Total_sold_quantity,
    RANK() OVER(PARTITION BY division ORDER BY SUM(s.sold_quantity) DESC) AS Rank_order
FROM
	dim_product p
JOIN
	fact_sales_monthly s
	ON p.product_code = s.product_code
WHERE
	s.fiscal_year = '2021'
GROUP BY
	p.division,
    p.product_code,
    p.product
)
SELECT *
FROM CTE
WHERE 
	Rank_order <= 3;
























































