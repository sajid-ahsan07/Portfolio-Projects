
-- 1. Checking for missing and inconsistent data
-- Records without customer name are useless for reporting/analysis
SELECT 
	customerNumber
	,contactLastName
    ,contactFirstName
FROM customers
WHERE contactLastName IS NULL OR contactFirstName IS NULL;

-- 2. Standardizing customer country names

UPDATE
	customers
SET
	country = UPPER(country)
WHERE 
	customerNumber >0; # To circumvent Safe Update error, WHERE clause with a KEY column is required
    
-- 3. Identifying duplicate orders

SELECT 
	orderNumber
    ,COUNT(*) AS dup_count
FROM
	orders
GROUP BY
	orderNumber
Having COUNT(*) > 1;

-- 4. Calculating total order amount per line item
SELECT
	orderNumber
    ,productCode
    ,quantityOrdered
    priceEach,
    (quantityOrdered * priceEach) AS total_Amount
FROM
	orderdetails;
    
-- 5. Total sales per customer
SELECT
	c.customerNumber
    ,c.customerName
    ,SUM(od.quantityOrdered * od.priceEach) AS total_sales
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY c.customerNumber, c.customerName
ORDER BY total_sales DESC;

-- 6. Top 5 products by revenue
SELECT
	p.productCode
    ,p.productName
    ,SUM(od.quantityOrdered * od.priceEach) as revenue
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY 
	p.productCode
    ,p.productName
ORDER BY revenue DESC
LIMIT 5;

-- 7. Sales Trend by Month
SELECT
	DATE_FORMAT(orderDate, '%Y-%m') AS month
    ,SUM(od.quantityOrdered * od.priceEach) AS monthly_Sales
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY month
ORDER BY month ASC;

-- 8. Total Sales per Sales Representative
SELECT
	e.employeeNumber
    ,CONCAT(e.firstName, ' ', e.lastName) AS sales_Rep
    ,SUM(od.quantityOrdered * od.priceEach) AS total_sales
FROM employees e
JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY e.employeeNumber, sales_Rep
ORDER BY total_Sales DESC;

-- 9. Top customer by sales in each city using window function
SELECT 
	customerNumber
    ,customerName
    ,city
    ,total_Sales
FROM (
SELECT
	c.customerNumber
    ,c.customerName
    ,c.city
    ,SUM(od.quantityOrdered * od.priceEach) AS total_Sales
    ,ROW_NUMBER() OVER
		(PARTITION BY c.city ORDER BY SUM(od.quantityOrdered * od.priceEach) DESC)
        AS rnk
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY
	c.customerNumber
    ,c.customerName
    ,c.city
) as ranked
WHERE rnk = 1;

-- 10. Aggregate Sales Table using CTE

WITH Sales AS (
SELECT
	o.orderNumber
    ,c.customerNumber
    ,c.customerName
    ,SUM(od.quantityOrdered * od.priceEach) AS total_Order_Amount
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN customers c ON o.customerNumber = c.customerNumber
GROUP BY o.orderNumber, c.customerNumber, c.customerName
)
SELECT * FROM Sales;

-- 11. List of Products that were not sold

SELECT
	productCode
    ,productName
FROM
	products
WHERE
	productCode
NOT IN (
		SELECT
			DISTINCT productCode
		FROM
			orderdetails
);

-- 12. Average order value per customer
SELECT
	c.customerNumber
    ,c.customerName
    ,AVG(od.quantityOrdered * od.priceEach) AS average_Order_Value
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY c.customerNumber, c.customerName
ORDER BY average_Order_Value DESC;


-- 13. Customer count per country
SELECT
	TRIM(country) AS country
    ,COUNT(*) AS customer_Count
FROM
	customers
GROUP BY
	TRIM(country)
ORDER BY
	customer_Count DESC;
    
-- 14. Sales per product line
SELECT
	p.productLine
    ,COUNT(*) AS product_Count
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
WHERE
	o.status = 'Shipped'
GROUP BY
	p.productLine
ORDER BY
	product_Count DESC;
    
-- 15. Total Revenue

SELECT sum(total_sales)
FROM
(
SELECT
	c.customerName
    ,sum(od.quantityOrdered * od.priceEach) as total_sales
FROM orderdetails od
JOIN orders o ON od.orderNumber = o.orderNumber
JOIN customers c ON o.customerNumber = c.customerNumber
GROUP BY c.customerName
ORDER BY total_sales DESC
) as ts
