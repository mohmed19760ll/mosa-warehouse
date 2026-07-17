
--Change over time  analysis
SELECT 
YEAR(order_date) order_year,
MONTH(order_date) order_month,
SUM(sales_amount) total_revenue,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY  YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date)

--Cumulative analysis
--calculate the running total of sales over time

SELECT
order_month,
total_sales,
SUM(total_sales) OVER(PARTITION BY YEAR(order_month) ORDER BY order_month) AS running_total
FROM (
	SELECT 
	DATETRUNC(month,order_date) order_month,
	SUM(sales_amount) total_sales
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(month,order_date)
	)t

--performance analysis
WITH yearly_sales_product AS (
	SELECT 
	YEAR(f.order_date) order_year,
	p.product_name,
	SUM(f.sales_amount) current_total_sales
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
	WHERE f.order_date IS NOT NULL
	GROUP BY YEAR(f.order_date),p.product_name
	)

SELECT 
	order_year,
	product_name,
	current_total_sales,
	AVG(current_total_sales) OVER(PARTITION  BY product_name) avg_sales,
CASE 
	WHEN current_total_sales-AVG(current_total_sales) OVER(PARTITION  BY product_name) > 0 THEN 'Above Avg'
	WHEN current_total_sales-AVG(current_total_sales) OVER(PARTITION  BY product_name) < 0 THEN 'Below Avg'
	ELSE 'Avg'
END avg_conclusion,
	LAG(current_total_sales) OVER(PARTITION BY product_name ORDER BY product_name,order_year) previous_year_sales,
	current_total_sales - LAG(current_total_sales) OVER(PARTITION BY product_name ORDER BY product_name,order_year) py_diff,
CASE 
	WHEN current_total_sales - LAG(current_total_sales) OVER(PARTITION BY product_name ORDER BY product_name,order_year) > 0 THEN 'higher'
	WHEN current_total_sales - LAG(current_total_sales) OVER(PARTITION BY product_name ORDER BY product_name,order_year) < 0 THEN 'lower'
	ELSE 'no diff'
END py_conclusion
FROM yearly_sales_product

--Which category contributes the most to overall sales
SELECT 
category,
total_sales,
SUM(total_sales) OVER () as total_sales_big,
CONCAT(ROUND((CAST(total_sales AS FLOAT)/SUM(total_sales) OVER ())*100,2),'%')  perc_contribution
FROM (
	SELECT 
	p.category,
	SUM(f.sales_amount)  total_sales
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
	GROUP BY p.category
    )t
ORDER BY total_sales DESC

--DATA segmentation
WITH product_segments AS(
	SELECT
		product_key,
		product_name,
		cost,
	CASE
		WHEN cost < 100 THEN 'Below 100'
		WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		ELSE 'Above 1000'
	END cost_range
	FROM gold.dim_products
	)

SELECT
cost_range,
COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC

--customer segmenatation
WITH customer_spending AS(
	SELECT 
	c.customer_key,
	SUM(f.sales_amount)  total_spending,
	MIN(order_date) AS first_order,
	MAX(order_date) AS last_order,
	DATEDIFF(Month,MIN(order_date),MAX(order_date)) lifespan
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
	ON c.customer_key = f.customer_key
	GROUP BY c.customer_key
	)

SELECT 
customer_category,
COUNT(customer_key) total_customers
FROM (
	SELECT 
		customer_key,
	CASE
		WHEN total_spending > 5000 AND lifespan >=12 THEN 'VIP'
		WHEN total_spending <= 5000 AND lifespan >=12 THEN 'Regular'
		ELSE 'New'
	END customer_category
	FROM customer_spending

	)t
GROUP BY customer_category
