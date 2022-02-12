CREATE DATABASE cs3; -- cs2 stands for case study 3
USE cs3;
CREATE TABLE info (
							clientnum VARCHAR(10),
							attrition_flag VARCHAR(30),
                            customer_age INTEGER,
							gender VARCHAR(10),
                            dependent_count DOUBLE,
                            education_level VARCHAR(30),
                            marital_status VARCHAR(30),
                            income_category VARCHAR(30),
                            card_category VARCHAR(30),
                            months_on_book INTEGER,
                            total_relationship_count INTEGER,
                            months_inactive_12_mon DOUBLE,
                            contacts_count_12_mon DOUBLE,
                            credit_limit DOUBLE,
                            total_revolving_bal DOUBLE,
                            avg_open_to_buy DOUBLE,
                            total_amt_chng_q4_q1 DOUBLE,
							total_trans_amt DOUBLE,
                            total_trans_ct DOUBLE,
                            total_ct_chng_q4_q1 DOUBLE,
                            avg_utilization_ratio DOUBLE);

-- changing clientnum to cient_num to be consisitent with naming                             
ALTER TABLE cs3.info
RENAME COLUMN clientnum TO client_num;

SELECT * FROM cs3.info;
SELECT COUNT(*) FROM cs3.info;
SELECT COUNT(DISTINCT clientnum) FROM cs3.info;

SELECT DISTINCT card_category FROM cs3.info;

/* Note
We will use the 1627 Attrited customers' characteristic as a sample size, which would sufficiently represent the population, with:
	-- 95% confidence level
    -- +/- 5 margin of error
    -- population size 10127
The sample size needed is only 370, which we are way beyond */

/* Part 1 - Relationship with clients */ 
-- Let us take a look at what duration is the most frequent for a client to leave
-- At the same time, let's see how many existing cliens are in that popular time period 

SELECT attrition_flag, COUNT(*) FROM cs3.info GROUP BY attrition_flag;
-- Current attrition ratio is 19.14%

SELECT 
	MAX(months_on_book),
    MIN(months_on_book)
FROM cs3.info;

SELECT 
	attrition_flag,
	COUNT(attrition_flag) As num_of_clients,
	CASE WHEN months_on_book = 12 THEN 'One year'
		 WHEN months_on_book BETWEEN 13 AND 24 THEN 'Two years'
         WHEN months_on_book BETWEEN 25 AND 36 THEN 'Three years'
         WHEN months_on_book BETWEEN 37 AND 48 THEN 'Four years'
         WHEN months_on_book BETWEEN 49 AND 60 THEN 'Five years' 
         END AS years
FROM cs3.info
GROUP BY attrition_flag, years
ORDER BY num_of_clients DESC;
-- We can see that: 1) most attrited customers leave during their third year. 
-- 					2) Majority of the existing clients are within that third year time frame. We can create a list of leads to contact in order to increase retention rate 

-- Let's learn more about the characteristic of attrited customers. More specifically, in these areas:
-- Relationship count and Contacting effort 
SELECT 
	COUNT(client_num) AS num_clients,
    attrition_flag,
    total_relationship_count
FROM cs3.info
GROUP BY  total_relationship_count, attrition_flag
ORDER BY total_relationship_count;
-- We can see that Clients with two or three relationships has the highest attrition count. However, let's look at the churn ratio within each group 

WITH 
	a AS (SELECT 
			COUNT(client_num) AS num_a_clients,
			attrition_flag,
			total_relationship_count
			FROM cs3.info
            WHERE attrition_flag = 'Attrited Customer'
			GROUP BY  total_relationship_count
			ORDER BY total_relationship_count
		 ),
	b AS (SELECT 
			COUNT(client_num) AS num_e_clients,
			attrition_flag,
			total_relationship_count
			FROM cs3.info
            WHERE attrition_flag = 'Existing Customer'
			GROUP BY  total_relationship_count
			ORDER BY total_relationship_count
		 )
SELECT 
	a.total_relationship_count,
    ROUND((num_a_clients/num_e_clients)*100, 2) AS percentage_attrited
FROM a JOIN b
ON a.total_relationship_count = b. total_relationship_count
GROUP BY a.total_relationship_count;
-- From this query, we can see that the attrition rate decreases as the number of relationship increases. The most dramatic drop is from the two to three relationships mark
-- This allows us to narrow our contact list, and target our effort towards the existing clients with two or less relaitonships. 

-- So far, we have narrowed our contact list to clients that:
-- 1) Has been with us three years or less, 2) Has two relationships or less 
SELECT 
	COUNT(client_num) AS num_clients,
	total_relationship_count
FROM cs3.info
WHERE total_relationship_count <= 3 
AND months_on_book BETWEEN 25 AND 36
AND attrition_flag = 'Existing Customer'
GROUP BY total_relationship_count
ORDER BY total_relationship_count;
-- The results from this query allow us to set a pirority list. Clients with just less relationships should be reached out to first (with promotions or perks) 

-- We can further refine this list by including how many times the client has been contacted in the past 12 months
SELECT 
	COUNT(client_num),
    COUNT(client_num)/SUM(COUNT(client_num)) OVER() AS percentage_of_total,
    contacts_count_12_mon
FROM cs3.info
WHERE attrition_flag = 'Attrited Customer'
GROUP BY contacts_count_12_mon
ORDER BY contacts_count_12_mon;

SELECT 
	COUNT(client_num),
    COUNT(client_num)/SUM(COUNT(client_num)) OVER() AS percentage_of_total,
    contacts_count_12_mon
FROM cs3.info
WHERE attrition_flag = 'Existing Customer'
GROUP BY contacts_count_12_mon
ORDER BY contacts_count_12_mon;
-- Surprisingly, there are not much difference between the exisitng and attrited client's contact effort. Much of the clients are contacted between 2 to 3 times.
-- We could do a further analysis if we know what the contact was about. Perhaps the contact lead to negative impression of the bank, or treated as spam calls/sell products declined before

-- Therefore, our final list would also includes clients that was contacted three times or less
SELECT 
	client_num,
    months_on_book,
	total_relationship_count
FROM cs3.info
WHERE total_relationship_count <= 3 
AND months_on_book BETWEEN 25 AND 36
AND attrition_flag = 'Existing Customer'
AND contacts_count_12_mon <= 3
ORDER BY total_relationship_count, months_on_book DESC;
-- Clients will be listed by their time on the book, and then relationship counts. Clients within the 3 years range take piority, then those with less relationship 


/* Part 2 - Income level vs Attrition 
We will take a look at different card group's client and their attrition rate. The hypothesis here is that our higher tier cards is attractive to higher income clients 
and people with higher tier cards churn less. Consequentially, upgrading the card could mean keeping the customer from leaving.*/ 

SELECT DISTINCT income_category FROM cs3.info;

SELECT DISTINCT card_category FROM cs3.info;
    
-- Let's see the attrition rate for each card tier 
SELECT 
	COUNT(*) AS num_clients,
    card_category
FROM cs3.info
WHERE attrition_flag = 'Attrited Customer'
GROUP BY card_category;
-- There is a dramatic decreases in attrition rate as the card tier increases 

-- We will assume 60K+ income is consider high (as shown by the top 6 FI in Canada for visa income requirement), let's see how many high income clients attrited and their card tier at the time
SELECT 
	card_category,
	COUNT(client_num) AS ex_clients 
FROM cs3.info
WHERE (income_category = '40K to 60K' OR 'Less than 40K') AND attrition_flag = 'Attrited Customer'
GROUP BY card_category
ORDER BY ex_clients DESC;
-- We can see that 257 clients with lower income churn when they hold the lowest tier card 

SELECT 
	card_category,
	COUNT(client_num) AS ex_clients 
FROM cs3.info
WHERE (income_category = '60K to 80K' OR income_category ='80K to 120K' OR income_category = '120K +')
	  AND attrition_flag = 'Attrited Customer'
GROUP BY card_category
ORDER BY ex_clients DESC;
-- In comparison, 500 clients with higher income churn with the lowest tier card. And higher income clients bring more potential to the bank 
-- Perhaps it is beacuse other banks offer premier cards that matches their spending habits. Which is what we need to start doing to increase retention

-- So, let's come up with a list of clients to contact with high income but equip with two lower tier cards
-- First, a few assumptions: 
	-- 1) Income levels are matched with the card tiers 
    -- 2) Income level from lowest to highest: Less than 40K, 40K to 80K, 80K to 120K, 120K + 
    -- 3) Card tier from lowest to highest: Blue, Silver, Gold, Platium
	-- 4) 60K+ income is consider high
SELECT 
	client_num
FROM cs3.info
WHERE income_category = '60K to 80K' OR income_category ='80K to 120K' OR income_category = '120K +'
AND card_category = 'Blue' OR card_category = 'Silver'
AND attrition_flag = 'Existing Customer';

SELECT MAX(avg_utilization_ratio), MIN(avg_utilization_ratio) FROM cs3.info;

-- We can also see if there are specific characteristic about attrited clients and their utilization rate
SELECT 
    ROUND(COUNT(IF(avg_utilization_ratio = 0, 1, NULL))/COUNT(avg_utilization_ratio),2) AS no_use,
    ROUND(COUNT(IF(avg_utilization_ratio <= 0.25, 1, NULL))/COUNT(avg_utilization_ratio),2) AS first_quartile,
    ROUND(COUNT(IF(avg_utilization_ratio BETWEEN 0.25 AND 0.50, 1, NULL))/COUNT(avg_utilization_ratio),2) AS second_quartile,
    ROUND(COUNT(IF(avg_utilization_ratio BETWEEN 0.50 AND 0.75, 1, NULL))/COUNT(avg_utilization_ratio),2) AS third_quartile,
	ROUND(COUNT(IF(avg_utilization_ratio > 0.75, 1, NULL))/COUNT(avg_utilization_ratio), 2) AS forth_quartile
FROM cs3.info
WHERE attrition_flag = 'Attrited Customer';
-- As shown by the data, 55% of the attrited clients did not use their card in the past 12 months, and 75.23% of the clients use the card less than 25% of their limit
-- This suggest that the credit card could be used a spare card and there is another bank's card as main 

SELECT 
    ROUND(COUNT(IF(avg_utilization_ratio = 0, 1, NULL))/COUNT(avg_utilization_ratio),2) AS no_use,
    ROUND(COUNT(IF(avg_utilization_ratio <= 0.25, 1, NULL))/COUNT(avg_utilization_ratio),2) AS first_quartile,
    ROUND(COUNT(IF(avg_utilization_ratio BETWEEN 0.25 AND 0.50, 1, NULL))/COUNT(avg_utilization_ratio),2) AS second_quartile,
    ROUND(COUNT(IF(avg_utilization_ratio BETWEEN 0.50 AND 0.75, 1, NULL))/COUNT(avg_utilization_ratio),2) AS third_quartile,
	ROUND(COUNT(IF(avg_utilization_ratio > 0.75, 1, NULL))/COUNT(avg_utilization_ratio), 2) AS forth_quartile
FROM cs3.info
WHERE attrition_flag = 'Existing Customer';

-- Another factor we can capture is the spending habit. Maybe the income info is outdate, but the spending habit of high income clients could be higher 
-- By comparing the reported income level, merged with the transaction amount, we can identify clients to upgrade their card 
SELECT 
	ROUND(AVG(total_trans_amt)) AS avg_amount,
    card_category
FROM cs3.info
GROUP BY card_category
ORDER BY avg_amount;
-- This will establish our spending tier per card

SELECT 
	total_trans_amt,
    income_category,
    card_category
FROM cs3.info
WHERE card_category = 'Blue' OR 'Silver'
AND attrition_flag IN('ex')
ORDER BY total_trans_amt DESC;
-- We can now re-assign clients to different card tiers depending on their spending habits and income 
-- The assumption is that some income data could be outdated, because people with total transaction of 15k is not likely to have an annual income below 40k 


SELECT DISTINCT income_category FROM cs3.info; 

SELECT 
	a.client_num,
    a.recommended_card_tier
FROM		
		(SELECT 
			client_num,
			income_category,
			card_category,
			CASE 
				WHEN income_category = 'Less than 40K' AND total_trans_amt <= 4225 THEN 'Blue'
				WHEN income_category = 'Less than 40K' AND total_trans_amt BETWEEN 4225 AND 7700 THEN 'Silver'
				WHEN income_category = 'Less than 40K' AND total_trans_amt BETWEEN 7700 AND 9000 THEN 'Gold'
				WHEN income_category = 'Less than 40K' AND total_trans_amt > 9000 THEN 'Platnium' 
				WHEN income_category = ('40K to 60K' OR '60K to 80K') AND total_trans_amt <= 4225 THEN 'Blue'
				WHEN income_category = ('40K to 60K' OR '60K to 80K') AND total_trans_amt BETWEEN 4225 AND 7700 THEN 'Silver'
				WHEN income_category = ('40K to 60K' OR '60K to 80K') AND total_trans_amt BETWEEN 7700 AND 9000 THEN 'Gold'
				WHEN income_category = ('40K to 60K' OR '60K to 80K') AND total_trans_amt > 9000 THEN 'Platnium'
				WHEN income_category = '80K to 120K' AND total_trans_amt <= 4225 THEN 'Gold'
				WHEN income_category = '80K to 120K' AND total_trans_amt BETWEEN 4225 AND 7700 THEN 'Gold'
				WHEN income_category = '80K to 120K' AND total_trans_amt BETWEEN 7700 AND 9000 THEN 'Gold'
				WHEN income_category = '80K to 120K' AND total_trans_amt > 9000 THEN 'Gold'
				WHEN income_category = '120K +' AND total_trans_amt <= 4225 THEN 'Platnium'
				WHEN income_category = '120K +' AND total_trans_amt BETWEEN 4225 AND 7700 THEN 'Platnium'
				WHEN income_category = '120K +' AND total_trans_amt BETWEEN 7700 AND 9000 THEN 'Platnium'
				WHEN income_category = '120K +' AND total_trans_amt > 9000 THEN 'Platnium'
				ELSE card_category END AS recommended_card_tier
		FROM cs3.info
		WHERE attrition_flag = 'Existing Customer') AS a
WHERE a.card_category != a.recommended_card_tier;
-- This way, we have generated a list of clients that needs a card upgrade based on their income level and spending habits. 

-- Now we just need to join our finding in utilization rate and spending together 
WITH
a AS (SELECT 
	client_num,
	income_category,
	card_category,
	CASE 
		WHEN income_category = 'Less than 40K' AND total_trans_amt <= 4225 THEN 'Blue'
		WHEN income_category = 'Less than 40K' AND total_trans_amt BETWEEN 4226 AND 7700 THEN 'Silver'
		WHEN income_category = 'Less than 40K' AND total_trans_amt BETWEEN 7701 AND 9000 THEN 'Gold'
		WHEN income_category = 'Less than 40K' AND total_trans_amt > 9001 THEN 'Platnium' 
		WHEN income_category = ('40K to 60K' OR '60K to 80K') AND total_trans_amt <= 4225 THEN 'Blue'
		WHEN income_category = ('40K to 60K' OR '60K to 80K') AND total_trans_amt BETWEEN 4226 AND 7700 THEN 'Silver'
		WHEN income_category = ('40K to 60K' OR '60K to 80K') AND total_trans_amt BETWEEN 7701 AND 9000 THEN 'Gold'
		WHEN income_category = ('40K to 60K' OR '60K to 80K') AND total_trans_amt > 9001 THEN 'Platnium'
		WHEN income_category = '80K to 120K' AND total_trans_amt <= 4225 THEN 'Gold'
		WHEN income_category = '80K to 120K' AND total_trans_amt BETWEEN 4226 AND 7700 THEN 'Gold'
		WHEN income_category = '80K to 120K' AND total_trans_amt BETWEEN 7701 AND 9000 THEN 'Gold'
		WHEN income_category = '80K to 120K' AND total_trans_amt > 9001 THEN 'Gold'
		WHEN income_category = '120K +' AND total_trans_amt <= 4225 THEN 'Platnium'
		WHEN income_category = '120K +' AND total_trans_amt BETWEEN 4226 AND 7700 THEN 'Platnium'
		WHEN income_category = '120K +' AND total_trans_amt BETWEEN 7701 AND 9000 THEN 'Platnium'
		WHEN income_category = '120K +' AND total_trans_amt > 9001 THEN 'Platnium'
		ELSE card_category END AS recommended_card_tier
	FROM cs3.info
	WHERE attrition_flag = 'Existing Customer'),
b AS (SELECT 
		client_num,
		CASE 
			WHEN avg_utilization_ratio = 0 THEN 'no use'
			WHEN avg_utilization_ratio BETWEEN 0 AND 0.25 THEN 'first quartile'
			WHEN avg_utilization_ratio BETWEEN 0.25 AND 0.50 THEN 'second quartile'
			WHEN avg_utilization_ratio BETWEEN 0.50 AND 0.75 THEN 'third quartile'
			ELSE 'forth quartile' END AS quartile
FROM cs3.info
WHERE attrition_flag = 'Existing Customer')

SELECT 
	a.client_num,
    card_category,
    a.recommended_card_tier,
    b.quartile
FROM a JOIN b
	ON a.client_num = b.client_num
	AND a.card_category != a.recommended_card_tier;
-- This query will bring us the list of people that deserves to be in a higher tier card. As we can observe, 3465 clients are needed to be contacted regarding a card upgrade
-- These are clients who spends a lot, and could benefits more on higher tier cards, and
-- These are clients who treats our card as a spare card while they have a higher tier primary card 

/* part 3 - Other Demographic information 
We will look at clients with different social status, such as age, martial status and number of dependents. 
This will allow us to further breakdown characteristics we can identify for attrition. The hypothesis is that people with family expenses will move to whatever better card they find*/
SELECT * FROM cs3.info;
SELECT DISTINCT marital_status FROM cs3.info;

-- Let us see how the proportion of churn rate in differnet marrital status groups for both Attrited and Existing clients 
SELECT 
	COUNT(IF(marital_status = 'Married' AND attrition_flag = 'Attrited Customer', 1, NULL)) / COUNT(IF(attrition_flag = 'Attrited Customer', 1, NULL)) AS married_attrited,
    COUNT(IF(marital_status = 'Single' AND attrition_flag = 'Attrited Customer', 1, NULL)) / COUNT(IF(attrition_flag = 'Attrited Customer', 1, NULL)) AS single_attrited,
    COUNT(IF(marital_status = 'Divorced'AND attrition_flag = 'Attrited Customer', 1, NULL)) / COUNT(IF(attrition_flag = 'Attrited Customer', 1, NULL)) AS divorced_attrited,
    COUNT(IF(marital_status = 'Unknown'AND attrition_flag = 'Attrited Customer', 1, NULL)) / COUNT(IF(attrition_flag = 'Attrited Customer', 1, NULL)) AS unknown_attrited,
	COUNT(IF(marital_status = 'Married' AND attrition_flag = 'Existing customer', 1, NULL)) / COUNT(IF(attrition_flag = 'Existing customer', 1, NULL)) AS married_Existing,
    COUNT(IF(marital_status = 'Single' AND attrition_flag = 'Existing customer', 1, NULL)) / COUNT(IF(attrition_flag = 'Existing customer', 1, NULL)) AS single_Existing,
    COUNT(IF(marital_status = 'Divorced' AND attrition_flag = 'Existing customer', 1, NULL)) / COUNT(IF(attrition_flag = 'Existing customer', 1, NULL)) AS divorced_Existing,
    COUNT(IF(marital_status = 'UNknown' AND attrition_flag = 'Existing customer', 1, NULL)) / COUNT(IF(attrition_flag = 'Existing customer', 1, NULL)) AS unknown_Existing
FROM CS3.info;
-- There seems to be no sigificant differneces in churn rate whether you are married or single. However, given that 43.58% of attirted customers are married, perhaps we can promotes plans for family cards 
-- such as adding your 19 years old + offsprings as an authorized user would waive your annual fees 

-- A quick check to see the age range of our customers shows min 26, max 73
SELECT MIN(customer_age), MAX(customer_age) FROM cs3.info ORDER BY customer_age;

SELECT 
    customer_age,
    COUNT(customer_age) AS num_of_cus
FROM cs3.info
WHERE attrition_flag = 'Attrited customer' AND marital_status = 'Married' 
GROUP BY customer_age
ORDER BY num_of_cus DESC; 
-- Here we noticed that there is a dramatic increase of attrition rate for customers between the age of 40 to 55. 

-- A quick check to see the number of dependent range of our customers shows min 0, max 5
SELECT MIN(dependent_count), MAX(dependent_count) FROM cs3.info; 

SELECT 
	a.dependent_count,
    num_of_dependent/ SUM(num_of_dependent) OVER() AS percentage_of_attrited
FROM (SELECT 
		customer_age,
		dependent_count,
		COUNT(dependent_count) AS num_of_dependent
	FROM cs3.info
	WHERE attrition_flag = 'Attrited customer' AND customer_age >= 40 AND customer_age <= 55 AND marital_status = 'Married'
    GROUP BY dependent_count
	ORDER BY dependent_count) AS a
GROUP BY a.dependent_count;
-- We can see that the most churn rate occurs with customers with 3 offsprings. This could be because of the increasing housing expense lead to customer looking for a card that has more benefits 
-- Therefore, we can use the social status as a supplement in identifying promotion opportunities, but these status should not be used as the main criteria. 

-- Here is the list of married clients that are age 40 to 55, and has 3 offsprings 
SELECT 
	client_num,
    customer_age,
    dependent_count
FROM cs3.info
WHERE customer_age >= 40 AND customer_age <= 55 
AND dependent_count = 3
AND marital_status = 'Married'
AND attrition_flag = 'Existing Customer';

/* Part 4 - Recommendations */

/*
Part 1
With the generated list of leads, we need to investigate into why most clients leaves during the third year with our FI. During our contact call, we can
see what the client's current goals are and offer a card that might best meet their needs. If their card is currently the best match to their needs,
then we can offer annual fees waiver or other incentive that best suits the customer's situation. 
One of the incentive could attract new clients by offering those who successfully introduced a new relationship, identified by opening a new card, a dicsount to their card, such as annual fee waiver, or promotion reward rate.

Part 2
Contact the 3465 potential clients for upgrading their card that matches their income, spending habit, and respective rewards 
-- These are clients who spends a lot, and could benefits more on higher tier cards, and
-- These are clients who treats our card as a spare card while they have a higher tier primary card 

Part 3
Customer who are married and has dependents of age of majority could be targeted with another plan. Our data shows that 
35% of the married and attrted clients has 3 dependents. This could be because our card's reward programs are not compensating for the high family expenses for the family. 
We could offer card fees discount to the famils that has dependents 19 or above. For every dependent of the family that apply for a credit card, we can discount 25% of the annual fee, or increase 0.5% cash back or points multipliers.
The goal is to promote the family to build a full banking relation with our FI.
*/
  











