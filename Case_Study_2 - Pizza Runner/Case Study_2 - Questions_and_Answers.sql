-----------------------------------------------------------------------------
-- ## Cleaning and Transform the Data:
--	Based on the first glance at the tables in this challenge,
--	it is obvious that we are going to work together to clear and arrange
--	the values in the tables so that we will not encounter any errors in our calculations or analysis.
-----------------------------------------------------------------------------
-- (A) Clean Null values from customer_orders table
-----------------------------------------------------------------------------

DROP TABLE IF EXISTS #customer_orders;
CREATE TABLE #customer_orders 

 (order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time DATETIME
);

INSERT INTO #customer_orders SELECT order_id,customer_id,pizza_id,exclusions,extras,order_time FROM customer_orders;

-- Cleaning data -- 
UPDATE #customer_orders SET
exclusions = CASE exclusions WHEN 'NULL' THEN NULL ELSE exclusions END,
extras = CASE extras WHEN 'NULL' THEN NULL ELSE extras END;

SELECT * FROM #customer_orders


-----------------------------------------------------------------------------
-- (B) Clean values from runner_orders table: In this table we will handle the values ​​in the columns (pickup_time,distance,duration,cancellation)
--		We can see that their is errors in the ETL proccess and with the null values

-- (C) After cleaning and arranging the table, we will update the different columns according to the correct column type
-----------------------------------------------------------------------------

DROP TABLE IF EXISTS #runner_orders;
CREATE TABLE #runner_orders 

(
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO #runner_orders SELECT order_id,runner_id,pickup_time,distance,duration,cancellation FROM runner_orders;

-- Cleaning data -- 
UPDATE #runner_orders SET
pickup_time = case pickup_time when 'null' then null else pickup_time end,
distance  = case distance when 'null' then null else distance end,
duration  = case duration when 'null' then null else duration end,
cancellation = case cancellation when 'null' then null else cancellation end;

SELECT * FROM #runner_orders

-----------------------------------------------------------------------------
-- (A) Pizza Metrics
--		1. How many pizzas were ordered?
-----------------------------------------------------------------------------

SELECT
		COUNT(*) AMOUNT_OF_PIZZA_ORDERED
		FROM #runner_orders

-----------------------------------------------------------------------------
-- (A) Pizza Metrics
--		2. How many unique customer orders were made?
-----------------------------------------------------------------------------
SELECT * FROM #runner_orders

SELECT 
COUNT(DISTINCT ORDER_ID) UN_ORDER

		FROM [dbo].[customer_orders]

-----------------------------------------------------------------------------
-- (A) Pizza Metrics
--		3. How many successful orders were delivered by each runner?
-----------------------------------------------------------------------------

SELECT 
runner_id,
count(*) as successful_delivered

		FROM #runner_orders
		where duration is not null 
		group by runner_id
		order by 2 desc

-----------------------------------------------------------------------------
-- (A) Pizza Metrics
--		4. How many of each type of pizza was delivered?
-----------------------------------------------------------------------------
select 
p.pizza_name,
count(c.pizza_id) as amount_delivered

	from #runner_orders r 
		join #customer_orders c
		on r.order_id = c.order_id
		join pizza_names p
		on c.pizza_id = p.pizza_id

		where r.duration is not null
		
		group by 
		p.pizza_name

-----------------------------------------------------------------------------
-- (A) Pizza Metrics
--		5. How many Vegetarian and Meatlovers were ordered by each customer?
-----------------------------------------------------------------------------

select 
c.customer_id,
p.pizza_name,
COUNT(p.pizza_name) AS AMOUNT

	from #customer_orders c
		join #runner_orders r 
		on r.order_id = c.order_id
		join pizza_names p
		on c.pizza_id = p.pizza_id

		GROUP BY 
		c.customer_id,
		p.pizza_name

		order by 1 
-----------------------------------------------------------------------------
-- (A) Pizza Metrics
--		6. What was the maximum number of pizzas delivered in a single order?
-----------------------------------------------------------------------------

WITH "MAX_ORDER"
AS
(
SELECT 
ORDER_ID,
COUNT(PIZZA_ID) AS AMOUNT_OF_PIZZA
FROM #customer_orders

GROUP BY 
ORDER_ID
) 

SELECT MAX(AMOUNT_OF_PIZZA) AS MAX_PIZZA_ORDER FROM "MAX_ORDER"

-----------------------------------------------------------------------------
-- (A) Pizza Metrics
--		7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-----------------------------------------------------------------------------
select 
C.customer_id,
SUM(CASE WHEN C.EXCLUSIONS <> '' OR C.EXTRAS <> '' THEN 1 ELSE 0 END ) AS CHANGE_,
SUM (CASE WHEN C.EXCLUSIONS =  '' OR C.EXTRAS   = '' THEN 1 ELSE 0 END ) AS NO_CHANGES

from #customer_orders C 
JOIN #runner_orders R 
on c.order_id = R.order_id
where r.distance is not null 

group by c.customer_id
order by 2 desc

-----------------------------------------------------------------------------
-- (A) Pizza Metrics
--8. How many pizzas were delivered that had both exclusions and extras
-----------------------------------------------------------------------------

SELECT 
		SUM(case when c.exclusions <> '' and c.extras <> '' then 1 else 0 end) as amount_delivered_BOTH

				FROM #customer_orders C 
				JOIN #runner_orders R 
				ON C.order_id = R.order_id

					WHERE duration is not null 

-----------------------------------------------------------------------------
-- (A) Pizza Metrics
--		9. What was the total volume of pizzas ordered for each hour of the day?
-----------------------------------------------------------------------------

SELECT 
DATEPART(hour,order_time) as [hour],
count(order_id) as volume_order

		from #customer_orders

		GROUP BY DATEPART(hour,order_time)

-----------------------------------------------------------------------------
-- (A) Pizza Metrics
--		10. What was the volume of orders for each day of the week?
-----------------------------------------------------------------------------


---------------------------------------------------------
-- (B) (1) How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
---------------------------------------------------------

SELECT

DATEPART(WEEK,registration_date) AS REGIST_WEEK,
COUNT(*) AS RUNNERS
		FROM [dbo].[runners]

		GROUP BY 
		DATEPART(WEEK,registration_date)

---------------------------------------------------------
-- (B) (2) What was the average time in minutes it took for each runner to arrive at the Pizza Runner
--		   HQ to pickup the order?
---------------------------------------------------------
WITH "AVG_TIME"
AS
	(
		SELECT  
		R.runner_id,
		DATEDIFF(MINUTE,C.order_time,R.pickup_time) AS DIFF
				from #customer_orders C
				JOIN #runner_orders R
				ON C.order_id = R.order_iD

				WHERE r.distance IS NOT NULL
	)

	SELECT runner_id,
			AVG(DIFF) AS AVG_TIME_DEL
			FROM AVG_TIME

			GROUP BY 
			runner_id

			ORDER BY  2

---------------------------------------------------------
-- (B) (3) Is there any relationship between the number of pizzas and how long the order takes to prepare?
---------------------------------------------------------
	with relationship
	as 
	(
	SELECT  
			C.order_id,
			COUNT(C.order_id) AS Number_of_Pizza,
			C.order_time,
			R.pickup_time,
			DATEDIFF(MINUTE,C.order_time,R.pickup_time) AS DIFF
		
				from #customer_orders C
				JOIN #runner_orders R
				ON C.order_id = R.order_iD

					WHERE r.distance IS NOT NULL
					GROUP BY C.order_id,C.order_time,R.pickup_time
		)

		SELECT Number_of_Pizza,
				AVG(DIFF) AS AVG_TIME_MAKE_PIZZA
		
		FROM relationship

		GROUP BY Number_of_Pizza


---------------------------------------------------------
-- (B) (4) What was the average distance travelled for each customer?
---------------------------------------------------------
	SELECT  
			C.customer_id,
			AVG(R.distance) AS AVG_DIS

				from #customer_orders C
				JOIN #runner_orders R
				ON C.order_id = R.order_iD

		GROUP BY 
		C.customer_id

		ORDER BY 
		2 DESC

