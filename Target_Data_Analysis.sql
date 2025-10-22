--CREATE DATABASE TARGET

--USE TARGET

--Press Ctrl + Shift + R to refresh the IntelliSense cache TO AVOID UNNECESSAY RED UNDERLINES.
--CTRL+K -> CTRL +C
--CTRL+K -> CTRL + U

SELECT * FROM CUSTOMERS
SELECT * FROM GEOLOCATION
SELECT * FROM ORDER_ITEMS
SELECT * FROM ORDER_REVIEWS
SELECT * FROM ORDERS
SELECT * FROM PAYMENTS
SELECT * FROM PRODUCTS
SELECT * FROM SELLERS

--2. 
SELECT MIN(ORDER_PURCHASE_TIMESTAMP) AS START_TIME,MAX(ORDER_PURCHASE_TIMESTAMP) AS END_TIME, 
DATEDIFF(MONTH,MIN(ORDER_PURCHASE_TIMESTAMP),MAX(ORDER_PURCHASE_TIMESTAMP)) NUMBER_OF_MONTH
FROM ORDERS;

--3.
SELECT COUNT(DISTINCT(C.CUSTOMER_CITY)) AS TOTAL_CITY_COUNT, COUNT(DISTINCT(C.CUSTOMER_STATE)) AS TOTAL_STATE_COUNT
FROM ORDERS O
JOIN CUSTOMERS C
ON O.customer_id = C.customer_id
WHERE order_purchase_timestamp BETWEEN '2016-09-04 21:15:19' AND '2018-10-17 17:30:18'

---2.1 Is there a growing trend in the no. of orders placed over the past years?

SELECT YEAR(ORDER_PURCHASE_TIMESTAMP) AS YEAR, COUNT(*) AS TOTAL_ORDERS
FROM ORDERS
GROUP BY YEAR(ORDER_PURCHASE_TIMESTAMP)

---2.2 Can we see some kind of monthly seasonality in terms of the no. of orders being placed?

SELECT MONTH(ORDER_PURCHASE_TIMESTAMP) AS MONTH_ORDERS, COUNT(*) AS TOTAL_ORDERS
FROM ORDERS
GROUP BY MONTH(ORDER_PURCHASE_TIMESTAMP)
ORDER BY TOTAL_ORDERS DESC

---2.During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
--0-6 hrs : Dawn
--7-12 hrs : Mornings
--13-18 hrs : Afternoon
--19-23 hrs : Night

WITH CTE AS 
(
	SELECT DATEPART(HOUR,ORDER_PURCHASE_TIMESTAMP) AS TIME_ORDERS, COUNT(*) AS TOTAL_ORDERS
	FROM ORDERS
	GROUP BY DATEPART(HOUR,ORDER_PURCHASE_TIMESTAMP)

),
CTE2 AS
(
SELECT *,
	CASE
		WHEN TIME_ORDERS BETWEEN 0 AND 6 THEN 'DAWN'
		WHEN TIME_ORDERS BETWEEN 7 AND 12 THEN 'MORNINGS'
		WHEN TIME_ORDERS BETWEEN 13 AND 18 THEN 'AFTERNOON'
		WHEN TIME_ORDERS BETWEEN 19 AND 23 THEN 'NIGHT'
		ELSE 'UNKNOWN'
	END AS END_OF_DAY
FROM CTE
)
SELECT END_OF_DAY, SUM(TOTAL_ORDERS) AS TOTAL_ORDERS_CATERGORY
FROM CTE2
GROUP BY END_OF_DAY
ORDER BY TOTAL_ORDERS_CATERGORY DESC

---3.1. Get the month on month no. of orders placed

SELECT CAST(YEAR(ORDER_PURCHASE_TIMESTAMP) AS VARCHAR)+'-'+CAST(MONTH(ORDER_PURCHASE_TIMESTAMP)AS VARCHAR) AS YEARMONTH
,COUNT(*) AS TOTAL_ORDERS
FROM ORDERS
GROUP BY CAST(YEAR(ORDER_PURCHASE_TIMESTAMP) AS VARCHAR)+'-'+CAST(MONTH(ORDER_PURCHASE_TIMESTAMP)AS VARCHAR)
ORDER BY YEARMONTH

---3.2. How are the customers distributed across all the states?

SELECT CUSTOMER_STATE, COUNT(customer_id) AS TOTAL_CUSTOMERS
FROM CUSTOMERS
GROUP BY customer_state
ORDER BY TOTAL_CUSTOMERS DESC

---4.Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.
--4.1.Get the % increase in the cost of orders from year 2017 to 2018 
--(include months between Jan to Aug only). You can use the "payment_value" column in the payments 
--table to get the cost of orders.

WITH CTE AS 
(
	SELECT YEAR(O.ORDER_PURCHASE_TIMESTAMP) AS YEAR,ROUND(SUM(P.PAYMENT_VALUE),2) AS COST_ORDERS
	FROM ORDERS O
	JOIN PAYMENTS P
	ON O.order_id = P.order_id
	WHERE YEAR(O.ORDER_PURCHASE_TIMESTAMP) IN ('2017','2018') AND 
	MONTH(O.ORDER_PURCHASE_TIMESTAMP) >=1 AND MONTH(O.ORDER_PURCHASE_TIMESTAMP)<=8 
	GROUP BY YEAR(O.ORDER_PURCHASE_TIMESTAMP)
)
SELECT YEAR, COST_ORDERS,
COALESCE(ROUND(((LEAD(COST_ORDERS) OVER(ORDER BY YEAR)-COST_ORDERS)*100)/(COST_ORDERS),2),0) AS PERCENTAGE_INCREASE_CTO
FROM CTE

---4.2.Calculate the Total & Average value of order price for each state.
---4.3. Calculate the Total & Average value of order freight for each state.

SELECT C.CUSTOMER_state AS STATES,ROUND(SUM(OI.PRICE),2) AS TOTAL_ORDERPRICE, ROUND(AVG(OI.PRICE),2) AS AVG_ORDERPRICE
,ROUND(SUM(OI.freight_value),2) AS TOTAL_FREIGHT_PRICE, ROUND(AVG(OI.freight_value),2) AS AVG_FREIGHT
FROM orders O
JOIN order_items OI
ON OI.order_id = O.ORDER_id
JOIN customers C
ON O.customer_id = C.customer_id
GROUP BY C.customer_state

--5. Analysis based on sales, freight and delivery time.
--1. Find the no. of days taken to deliver each order from the order’s purchase date as delivery time. Also, 
--calculate the difference (in days) between the estimated & actual delivery date of an order. Do this in a single query. 
--You can calculate the delivery time and the difference between the estimated & actual delivery date using the given formula:
-- time_to_deliver = order_delivered_customer_date - order_purchase_timestamp
-- diff_estimated_delivery = order_delivered_customer_date - order_estimated_delivery_date

SELECT ORDER_ID,
DATEDIFF(DAY,CAST(ORDER_PURCHASE_TIMESTAMP AS DATE),CAST(ORDER_DELIVERED_CUSTOMER_DATE AS DATE)) AS TIME_TO_DELIVER,
DATEDIFF(DAY,CAST(ORDER_ESTIMATED_DELIVERY_DATE AS DATE),CAST(ORDER_DELIVERED_CUSTOMER_DATE AS DATE)) AS DIFF_ESTIMATED_DELIVERY
FROM orders


---5.2.Find out the top 5 states with the highest & lowest average freight value.

--ALTERNATE: 
WITH CTE1 AS 
(	
	SELECT TOP 5 C.customer_state,
	ROUND(AVG(OI.FREIGHT_VALUE),2) AS AVG_FREIGHT,'HIGHEST' AS CATEGORY
	FROM ORDERS O
	JOIN order_items OI
	ON O.order_id = OI.order_id
	JOIN customers C
	ON O.customer_id = C.customer_id
	GROUP BY C.customer_state
	ORDER BY AVG_FREIGHT DESC
),
CTE2 AS
(
	SELECT TOP 5 C.customer_state,
	ROUND(AVG(OI.FREIGHT_VALUE),2) AS AVG_FREIGHT,'LOWEST' AS CATEGORY
	FROM ORDERS O
	JOIN order_items OI
	ON O.order_id = OI.order_id
	JOIN customers C
	ON O.customer_id = C.customer_id
	GROUP BY C.customer_state
	ORDER BY AVG_FREIGHT
)

SELECT * FROM CTE1
UNION ALL
SELECT * FROM CTE2

--ALTERNATE 2: You’re using ORDER BY inside each SELECT with TOP, which SQL Server doesn’t allow
--when combining queries with UNION or UNION ALL.

---5.3.Find out the top 5 states with the highest & lowest average delivery time.

WITH CTE3 AS
(
SELECT TOP 5 C.CUSTOMER_STATE,AVG(DATEDIFF(DAY,CAST(ORDER_PURCHASE_TIMESTAMP AS DATE),
CAST(ORDER_DELIVERED_CUSTOMER_DATE AS DATE))) AS AVG_DELIVERY_TIME,'HIGHEST' AS CATEGORY
FROM orders O
JOIN customers C
ON O.customer_id = C.customer_id
WHERE CAST(ORDER_PURCHASE_TIMESTAMP AS DATE)<CAST(ORDER_DELIVERED_CUSTOMER_DATE AS DATE) AND ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
GROUP BY customer_state
ORDER BY AVG_DELIVERY_TIME DESC
), 

CTE4 AS
(
SELECT TOP 5 C.CUSTOMER_STATE,AVG(DATEDIFF(DAY,CAST(ORDER_PURCHASE_TIMESTAMP AS DATE),
CAST(ORDER_DELIVERED_CUSTOMER_DATE AS DATE))) AS AVG_DELIVERY_TIME,'LOWEST' AS CATEGORY
FROM orders O
JOIN customers C
ON O.customer_id = C.customer_id
WHERE CAST(ORDER_PURCHASE_TIMESTAMP AS DATE)<CAST(ORDER_DELIVERED_CUSTOMER_DATE AS DATE) AND ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
GROUP BY customer_state
ORDER BY AVG_DELIVERY_TIME
)

SELECT * FROM CTE3
UNION ALL
SELECT * FROM CTE4

---5.4.Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery. You can use 
--the difference between the averages of actual & estimated delivery date to fi gure out how fast the delivery was for each state.

SELECT top 5 C.CUSTOMER_STATE,AVG(DATEDIFF(DAY,CAST(order_estimated_delivery_date AS DATE),
CAST(ORDER_DELIVERED_CUSTOMER_DATE AS DATE))) AS AVG_FASTEST_TIME,'NEG IS FASTEST THEN ESTIMATED DAY' AS CATEGORY
FROM orders O
JOIN customers C
ON O.customer_id = C.customer_id
WHERE CAST(ORDER_PURCHASE_TIMESTAMP AS DATE)<CAST(ORDER_DELIVERED_CUSTOMER_DATE AS DATE) AND 
ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL AND order_estimated_delivery_date IS NOT NULL
GROUP BY customer_state
ORDER BY AVG_FASTEST_TIME

--6. Analysis based on the payments:
--1. Find the month on month no. of orders placed using different payment types.

SELECT FORMAT(CAST(O.ORDER_PURCHASE_TIMESTAMP AS DATE),'yyyy-MM') AS YEARMONTH,P.PAYMENT_TYPE,COUNT(O.ORDER_ID) AS TOTAL_ORDERS
FROM ORDERS O
JOIN PAYMENTS P
ON O.order_id = P.order_id
GROUP BY FORMAT(CAST(O.ORDER_PURCHASE_TIMESTAMP AS DATE),'yyyy-MM'),P.PAYMENT_TYPE
ORDER BY YEARMONTH ASC

--2. Find the no. of orders placed on the basis of the payment installments that have been paid.

SELECT payment_installments,COUNT(DISTINCT(ORDER_ID)) AS TOTAL_ORDERS
FROM PAYMENTS 
GROUP BY payment_installments
ORDER BY payment_installments ASC