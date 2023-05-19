-- zomato

-- what is the total amount each customer spent on zomato?
USE zomato;
SELECT a.userid, SUM(b.price) total_amount 
FROM sales a INNER JOIN product b 
ON a.product_id=b.product_id 
GROUP BY a.userid;


-- how many days does each customer visited zomato?
SELECT userid,COUNT(DISTINCT created_date) AS number_of_days
FROM sales
GROUP BY userid;


-- What was the first product purchased by each customer?
SELECT * FROM (
	SELECT s.userid , s.created_date, p.product_name, 
	RANK() OVER(PARTITION BY s.userid ORDER BY s.created_date) AS ranking 
	FROM sales s LEFT JOIN product p USING (product_id)) 
AS a WHERE ranking=1;


-- What is the most purchased item on the menu and how many times it was purchased by each customers?
SELECT *, COUNT(userid) FROM sales WHERE product_id =(
SELECT product_id
FROM sales 
GROUP BY product_id 
ORDER BY COUNT(userid) DESC
LIMIT 1)
GROUP BY userid;


-- which item was most popular for each customer

SELECT * FROM(
	SELECT *, RANK() OVER(PARTITION BY userid ORDER BY number_of_item DESC) AS ranking FROM(
		SELECT userid, product_id , COUNT(product_id) AS number_of_item
		FROM sales 
		GROUP BY userid, product_id
		ORDER BY product_id, userid) AS a) AS b
WHERE ranking=1;



-- Which item was purchased first by each customer after they become gold member

SELECT * FROM(
	SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date) AS ranking FROM(
		SELECT s.*, g.gold_signup_date
		FROM sales AS s
		INNER JOIN goldusers_signup AS g
		USING (userid)
		WHERE gold_signup_date<=created_date)AS a)AS b
WHERE ranking=1;


-- Which item was purchased first by each customer just before they become a gold member

SELECT * FROM(
	SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date DESC) AS ranking FROM(
		SELECT s.*, g.gold_signup_date
		FROM sales AS s
		INNER JOIN goldusers_signup AS g
		USING (userid)
		WHERE gold_signup_date>=created_date)AS a)AS b
WHERE ranking=1;


-- What is the total orders and amount spent by each member before they become a gold member

SELECT userid, COUNT(created_date) AS total_orders, SUM(price) AS total_amount FROM
	(SELECT a.*,p.price FROM (
		SELECT s.*, g.gold_signup_date
		FROM sales AS s
		INNER JOIN goldusers_signup AS g
		USING (userid)
		WHERE gold_signup_date>=created_date) AS a
		INNER JOIN product AS p
		USING (product_id)) AS b
	 GROUP BY userid
     ORDER BY userid;
     
     
-- If buying each product generates points for eg 5rs-2 zomato point and 
-- each product has different purchasing points for eg for 
-- p1 5rs=1 zomato point for p2 10rs-5zomato point and p3 5rs=1 zomato point 2rs-1zomato point 
-- calculate points collected by each customers and for which product most points have been given till now.



SELECT userid , (SUM(points)) AS TOTAL_POINTS  FROM(
	SELECT * , (CASE WHEN product_id=1 THEN price/5 WHEN product_id=2 THEN price/2 WHEN product_id=3 THEN price/5 ELSE 0 END)AS POINTS  FROM(
		SELECT userid, product_id, SUM(price) AS price FROM(
			SELECT *
			FROM sales AS s
			INNER JOIN 
			product AS p
			USING(product_id)) AS a
			GROUP BY userid, product_id
			ORDER BY userid, product_id) AS b) AS c
            GROUP BY userid;



SELECT product_id, MAX(total_points) AS maximum_earned_points FROM(
	SELECT product_id, SUM(points) AS total_points FROM(
		SELECT * , (CASE WHEN product_id=1 THEN price/5 WHEN product_id=2 THEN price/2 WHEN product_id=3 THEN price/5 ELSE 0 END)AS POINTS  FROM(
			SELECT userid, product_id, SUM(price) AS price FROM(
				SELECT *
				FROM sales AS s
				INNER JOIN 
				product AS p
				USING(product_id)) AS a
				GROUP BY userid, product_id
				ORDER BY userid, product_id) AS b)AS c
				GROUP BY product_id) AS d;
                
                
			
-- In the first one year after a customer joins the gold program (including their join date) 
-- irrespective of what the customer has purchased 
-- they earn 5 zomato points for every 10 rs spent who earned more 1 or 3 and 
-- what was their points earnings in thier first yr? 
-- 1 zp=2rs 
-- 0.5 zp=1rs

SELECT *, (price/2)AS TOTAL_POINTS FROM(
	SELECT * FROM(
		SELECT s.*, g.gold_signup_date, p.price
		FROM sales AS s
		INNER JOIN goldusers_signup AS g
		USING (userid)
		INNER JOIN product AS p
		USING(product_id)
		WHERE gold_signup_date<=created_date AND created_date<= date_add(gold_signup_date,INTERVAL 1 year)
		) AS a) AS b;




-- RANK all the transactions of the customers

SELECT *,RANK() OVER(PARTITION BY userid ORDER BY created_date) AS ranking 
FROM sales;



-- rank all the transactions for each member whenever they are a zomato gold member for every non gold member transction mark as NA

SELECT * , (CASE WHEN ranking=0 THEN 'NA' ELSE RANKING END ) FROM(
	SELECT a.*, CAST((CASE WHEN gold_signup_date IS NULL THEN 0 ELSE RANK() OVER(PARTITION BY userid ORDER BY created_date DESC) END)AS char)AS ranking FROM(
		SELECT s.userid,s.created_date,s.product_id, g.gold_signup_date 
		FROM sales AS s
		LEFT JOIN
		goldusers_signup AS g
		ON s.userid=g.userid AND created_date>=gold_signup_date)AS a)AS b;
