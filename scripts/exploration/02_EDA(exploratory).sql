--DATABASE EXPLORATION

--CHECK DISTINCT DIMENSIONS
SELECT DISTINCT 
country
FROM gold.dim_customers

SELECT DISTINCT 
category,
subcategory,
product_name
FROM gold.dim_products
ORDER BY 1,2,3

--EXPLORE DATES
SELECT 
MIN(order_date) first_order,
MAX(order_date) last_order,
DATEDIFF(YEAR,MIN(order_date),MAX(order_date)) order_years
FROM gold.fact_sales

SELECT
MIN(birthdate) oldest,
DATEDIFF(year,MIN(birthdate),GETDATE()) AS oldest_age,
MAX(birthdate) youngest,
DATEDIFF(year,MAX(birthdate),GETDATE()) AS youngest_age
FROM gold.dim_customers

--CHECK MEASURE AGGREGATES

SELECT
SUM(sales_amount) as total_sales,
SUM(quantity) as total_quantity,
COUNT(DISTINCT order_number) as total_unique_orders,
AVG(price) as avg_price
FROM gold.fact_sales

SELECT 
COUNT(customer_key)  total_cust
FROM gold.dim_customers

SELECT
COUNT(DISTINCT customer_key) customers_with_orders
FROM gold.fact_sales

--BUSINESS REPORT

SELECT 'Total sales' as measure_name, SUM(sales_amount) as measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity' as measure_name, SUM(quantity) as measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Average Price' as measure_name, AVG(price) as measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Orders' as measure_name, COUNT(DISTINCT order_number) as measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Products' as measure_name, COUNT(product_key) as measure_value FROM gold.dim_products
UNION ALL
SELECT 'Total Nr. Customers' as measure_name, COUNT(customer_key) as measure_value FROM gold.dim_customers
UNION ALL
SELECT 'Total Nr. Customers With Orders' as measure_name, COUNT(DISTINCT customer_key) as measure_value FROM gold.fact_sales


--Magnitude analysis

--total customers by country
SELECT 
country,
COUNT(customer_key) AS total_customers_by_country
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers_by_country DESC

--total customers by gender
SELECT 
gender,
COUNT(customer_key) AS total_customers_by_gender
FROM gold.dim_customers
GROUP BY gender

--total products by category
SELECT
category,
COUNT(product_key) AS total_product_by_category
FROM gold.dim_products
GROUP BY category
ORDER BY total_product_by_category DESC

--average cost in each category
SELECT
category,
AVG(cost) AS average_cost_per_category
FROM gold.dim_products
GROUP BY category
ORDER BY average_cost_per_category DESC

--TOTAL revenue from each category
SELECT 
p.category,
SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC

--Total revenue by each customer
SELECT
f.customer_key,
c.first_name,
c.last_name,
SUM(f.sales_amount) customer_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY f.customer_key,c.first_name,c.last_name
ORDER BY customer_revenue DESC

--Distribution of items sold per country
SELECT
c.country,
SUM(f.quantity) total_quantity
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_quantity DESC

--RANKING ANALYSIS
-- 5 products generating the highest revenue
SELECT TOP 5
p.product_name,
SUM(f.sales_amount) revenue_per_product
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p             --GROUP BY variant
ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY revenue_per_product DESC

SELECT *
FROM (
	SELECT 
	p.product_name,
	SUM(f.sales_amount) revenue_per_product,
	ROW_NUMBER() OVER( ORDER BY SUM(f.sales_amount) DESC) rank_   --WINDOW FUNCTION variant
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
	GROUP BY p.product_name) t
WHERE rank_ <= 5

-- 5 products generating the lowest revenue
SELECT TOP 5
p.product_name,
SUM(f.sales_amount) revenue_per_product
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY revenue_per_product ASC

--3 customers with the lowest nr of orders placed
SELECT TOP 3
f.customer_key,
c.first_name,
c.last_name,
COUNT(DISTINCT order_number) customer_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY f.customer_key,c.first_name,c.last_name
ORDER BY customer_orders 