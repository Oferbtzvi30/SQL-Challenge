----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- () Questions:
----------------------------------------------------------------------------------------------------------------------------------------------------------------

Each of the following case study questions can be answered using a single SQL statement:

What is the total amount each customer spent at the restaurant?
How many days has each customer visited the restaurant?
What was the first item from the menu purchased by each customer?
What is the most purchased item on the menu and how many times was it purchased by all customers?
Which item was the most popular for each customer?
Which item was purchased first by the customer after they became a member?
Which item was purchased just before the customer became a member?
What is the total items and amount spent for each member before they became a member?
If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

----------------------------------------------------------------------------------------------------------------------------------------------------------------
() SQL script for Case study - Week_1
----------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);



----------------------------------------------------------------------------------------------------------------------------------------------------------------
() Answers:
----------------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--(1) What is the total amount each customer spent at the restaurant?
--------------------------------------------------------------------------------
SELECT 
s.customer_id,
SUM(M.PRICE) AS SPEND

		FROM [dbo].[sales] s join [dbo].[menu] m 
		on s.product_id = m.product_id

		GROUP BY s.customer_id

--------------------------------------------------------------------------------
--(2) How many days has each customer visited the restaurant?
--------------------------------------------------------------------------------
SELECT 
customer_id,
COUNT(DISTINCT ORDER_DATE) 
		FROM [dbo].[sales]

		GROUP BY customer_id


--------------------------------------------------------------------------------
--(3) What was the first item from the menu purchased by each customer?
--------------------------------------------------------------------------------

WITH "RANK-TABLE" AS 
(
		SELECT
		S.customer_id,
		S.ORDER_DATE,
		S.PRODUCT_ID,
		M.PRODUCT_NAME,
		DENSE_RANK () OVER (PARTITION BY S.customer_id ORDER BY S.ORDER_DATE) R

		FROM [sales] S LEFT JOIN [menu] M 
		ON S.PRODUCT_ID = M.PRODUCT_ID
) 

SELECT 
customer_id,
ORDER_DATE,
PRODUCT_NAME

FROM "RANK-TABLE"
WHERE R = 1 
	GROUP BY 
		customer_id,
		ORDER_DATE,
		PRODUCT_NAME


--------------------------------------------------------------------------------
--(4) What is the most purchased item on the menu and how many times was it purchased by all customers?
--------------------------------------------------------------------------------

WITH "ITEM" AS
(
SELECT
	M.PRODUCT_NAME,
	COUNT(*) AS AMOUNT
		
		FROM [sales] S LEFT JOIN [menu] M 
		ON S.PRODUCT_ID = M.PRODUCT_ID

		GROUP BY 
		M.PRODUCT_NAME
)
SELECT * FROM "ITEM"
WHERE AMOUNT = (SELECT MAX(AMOUNT) FROM "ITEM") 


--------------------------------------------------------------------------------
--(5) Which item was the most popular for each customer?
--------------------------------------------------------------------------------


WITH "RANK-ORDER" AS 
			(
			SELECT
				S.customer_id,
				M.PRODUCT_NAME,
				COUNT(S.PRODUCT_ID) AS AMOUNT_BY_USER,
				DENSE_RANK () OVER (PARTITION BY customer_id ORDER BY COUNT(S.PRODUCT_ID)DESC) R

					FROM [sales] S LEFT JOIN [menu] M 
					ON S.PRODUCT_ID = M.PRODUCT_ID

				GROUP BY 
				S.customer_id,
				M.PRODUCT_NAME
						)
						SELECT 
							customer_id,
							PRODUCT_NAME,
							AMOUNT_BY_USER
							FROM "RANK-ORDER"
							WHERE R = 1 

--------------------------------------------------------------------------------
--(6) Which item was purchased first by the customer after they became a member?
--------------------------------------------------------------------------------

WITH "FIRST-ORDER" AS 
(
 SELECT 
S.CUSTOMER_ID,
M.JOIN_DATE, 
S.ORDER_DATE,
s.product_id,
DENSE_RANK() OVER (PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE) AS R 

	FROM [dbo].[sales] S	JOIN [dbo].[members] M
			ON S.CUSTOMER_ID = M.CUSTOMER_ID
			WHERE S.ORDER_DATE >= M.JOIN_DATE 
)

SELECT 
A.CUSTOMER_ID,
A.product_id,
B.product_name

FROM "FIRST-ORDER" A 
 JOIN [dbo].[menu] B 
	ON A.product_ID = B.product_ID
WHERE R =1 



--------------------------------------------------------------------------------
--(7) Which item was purchased just before the customer became a member?
--------------------------------------------------------------------------------

WITH "BEFORE-MEMBER" AS 
(
 SELECT 
S.CUSTOMER_ID,
M.JOIN_DATE, 
S.ORDER_DATE,
s.product_id,
DENSE_RANK() OVER (PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE DESC) AS R 

	FROM [dbo].[sales] S	JOIN [dbo].[members] M
			ON S.CUSTOMER_ID = M.CUSTOMER_ID
			WHERE S.ORDER_DATE < M.JOIN_DATE 
)

SELECT 
A.CUSTOMER_ID,
A.product_id,
B.product_name

FROM "BEFORE-MEMBER" A 
 JOIN [dbo].[menu] B 
	ON A.product_ID = B.product_ID
WHERE R =1 

--------------------------------------------------------------------------------
--(8) What is the total items and amount spent for each member before they became a member?
--------------------------------------------------------------------------------

SELECT 
sales.CUSTOMER_ID,
COUNT(DISTINCT sales.product_id) AS UNIQUE_ITEM_AMOUNT,
SUM(menu.PRICE) AS TOTAL_SPENT

	FROM [dbo].[sales] sales	JOIN [dbo].[members] members
			ON sales.CUSTOMER_ID = members.CUSTOMER_ID
			JOIN [dbo].[menu] menu
			ON sales.product_id = menu.product_id

				WHERE sales.ORDER_DATE < members.JOIN_DATE 

				GROUP BY
				sales.CUSTOMER_ID


--------------------------------------------------------------------------------
--(9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
--------------------------------------------------------------------------------

with "points" as 
(
SELECT 
sales.customer_id,
CASE WHEN menu.product_id = 1 THEN menu.price * 20 ELSE menu.price * 10 end as point

	FROM [dbo].[sales] sales	JOIN [dbo].[menu] menu
			ON sales.product_id = menu.product_id 
)
select 
customer_id,
sum(point ) as total_points 
from "points"

group by 
customer_id


--------------------------------------------------------------------------------
--(10) In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--	not just sushi how many points do customer A and B have at the end of January?

--------------------------------------------------------------------------------

	WITH DATES_CTE AS
	(
		SELECT *,
		DATEADD(DAY,6,JOIN_DATE) AS VALID_DATE,
		EOMONTH('2021-01-31') AS last_date
		FROM members AS M
	),

	total_points as 
		(
			SELECT 
			d.customer_id, 
			s.order_date, 
			d.join_date, 
			d.valid_date, 
			d.last_date, 
			m.product_name, 
			m.price,
				 SUM(CASE
				  WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
				  WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
				  ELSE 10 * m.price
				  END) AS points
							FROM dates_cte AS d
							JOIN sales AS s
							 ON d.customer_id = s.customer_id
							JOIN menu AS m
							 ON s.product_id = m.product_id

								WHERE s.order_date < d.last_date
								GROUP BY 
								d.customer_id, 
								s.order_date, 
								d.join_date, 
								d.valid_date, 
								d.last_date, 
								m.product_name, 
								m.price)

				select 
				customer_id,
				sum(points) as total_points

				from total_points
				group by 
				customer_id

--------------------------------------------------------------------------------
--(11) The following questions are related creating basic 
--		data tables that Danny and his team can use to quickly derive insights without needing
--		to join the underlying tables using SQL.
--------------------------------------------------------------------------------

select 
s.customer_id,
s.order_date,
m1.product_name,
m1.price,
case when s.order_date < m2.join_date then 'N' --# when the order made before the membership
	 when s.order_date >= m2.join_date then 'Y'--# when the order made after the membership
	 end as member

	from [dbo].[sales] s join [dbo].[menu] m1
	on s.product_id = m1.product_id
	join [dbo].[members] m2 
	on s.customer_id = m2.customer_id

--------------------------------------------------------------------------------
	-- (12) Danny also requires further information about the ranking of customer products,
	--		but he purposely does not need the ranking for non-member purchases so he expects null ranking values
	--		for the records when customers are not yet part of the loyalty program.
--------------------------------------------------------------------------------
WITH "RANKS-FULL-TALBE"
AS 
(
select 
s.customer_id,
s.order_date,
m1.product_name,
m1.price,
case when s.order_date < m2.join_date then 'N' --# when the order made before the membership
	 when s.order_date >= m2.join_date then 'Y'--# when the order made after the membership
	 end as member

	from [dbo].[sales] s join [dbo].[menu] m1
	on s.product_id = m1.product_id
	join [dbo].[members] m2 
	on s.customer_id = m2.customer_id
)

SELECT *, CASE
 WHEN member = 'N' then NULL
 WHEN member = 'Y' then DENSE_RANK () OVER(PARTITION BY customer_id,member ORDER BY order_date) END AS ranking 
FROM "RANKS-FULL-TALBE"
