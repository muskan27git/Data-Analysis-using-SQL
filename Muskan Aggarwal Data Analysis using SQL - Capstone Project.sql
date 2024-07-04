-- 1 How many sales occurred during this time period? 
USE cryptopunk;
SELECT 
    COUNT(*) AS total_sales
FROM
    pricedata;

-- 2 Return the top 5 most expensive transactions (by USD price) for this data set. Return the name, ETH price, and USD price, as well as the date:
SELECT 
    name, eth_price, usd_price, event_date
FROM
    pricedata
ORDER BY usd_price DESC
LIMIT 5;

-- 3 Return a table with a row for each transaction with an event column, a USD price column, and a moving average of USD price that averages the last 50 transactions.:

SELECT event_date, usd_price, AVG(usd_price)
OVER (ORDER BY event_date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW)
AS moving_average
FROM pricedata;

-- 4 Return all the NFT names and their average sale price in USD. Sort descending. Name the average column as average_price.

SELECT 
    name, AVG(usd_price) AS average_price
FROM
    pricedata
GROUP BY name
ORDER BY average_price DESC;

-- 5 Return each day of the week and the number of sales that occurred on that day of the week, as well as the average price in ETH. Order by the count of transactions in ascending order.

SELECT 
    DAYNAME(event_date) AS day_of_week,
    COUNT(*) AS sales_count,
    AVG(eth_price) AS average_price_in_eth
FROM
    pricedata
GROUP BY day_of_week
ORDER BY sales_count ASC;

-- 6 Construct a column that describes each sale and is called summary. The sentence should include who sold the NFT name, who bought the NFT, who sold the NFT, the date, and what price it was sold for in USD rounded to the nearest thousandth.

SELECT 
    CONCAT(name,
            ' was sold for $',
            ROUND(usd_price, 3),
            ' to ',
            buyer_address,
            ' from ',
            seller_address,
            ' on ',
            event_date)
FROM
    pricedata;
    
-- 7 Create a view called “1919_purchases” and contains any sales where “0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685” was the buyer.

CREATE VIEW 1919_purchases AS
    SELECT 
        *
    FROM
        pricedata
    WHERE
        buyer_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685';

-- 8 Create a histogram of ETH price ranges. Round to the nearest hundred value. 

SELECT 
    ROUND(eth_price, - 2) AS bucket,
    COUNT(*) AS count,
    RPAD(' ', COUNT(*), '-') AS bar
FROM
    pricedata
GROUP BY bucket
ORDER BY bucket;

-- 9 Return a unioned query that contains the highest price each NFT was bought for and a new column called status saying “highest” with a query that has the lowest price each NFT was bought for and the status column saying “lowest”. The table should have a name column, a price column called price, and a status column. Order the result set by the name of the NFT, and the status, in ascending order. :

SELECT 
    name, MAX(usd_price) AS price, 'highest' AS status
FROM
    pricedata
GROUP BY name 
UNION SELECT 
    name, MIN(usd_price) AS price, 'lowest' AS status
FROM
    pricedata
GROUP BY name
ORDER BY name , status;

-- 10 What NFT sold the most each month / year combination? Also, what was the name and the price in USD? Order in chronological format:

SELECT 
    t1.name, 
    t1.usd_price, 
    MONTH(t1.event_date) AS month, 
    YEAR(t1.event_date) AS year
FROM 
    pricedata t1
JOIN (
    SELECT 
        MAX(usd_price) AS max_price, 
        MONTH(event_date) AS max_month, 
        YEAR(event_date) AS max_year
    FROM 
        pricedata
    GROUP BY 
        YEAR(event_date), MONTH(event_date)
) t2 
ON 
    t1.usd_price = t2.max_price 
    AND MONTH(t1.event_date) = t2.max_month 
    AND YEAR(t1.event_date) = t2.max_year
ORDER BY 
    year, month;

	
-- 11 Return the total volume (sum of all sales), round to the nearest hundred on a monthly basis (month/year):

SELECT 
    ROUND(SUM(usd_price), - 2) AS total_volume,
    MONTH(event_date) AS month,
    YEAR(event_date) AS year
FROM
    pricedata
GROUP BY month , year
ORDER BY year , month;
 
 -- 12 Count how many transactions the wallet "0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685"had over this time period:
 
 SELECT 
    COUNT(*) AS transaction_count
FROM
    pricedata
WHERE
    buyer_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685'
        OR seller_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685'
        OR token_id = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685';
 
 
 -- 13 Create an “estimated average value calculator” that has a representative price of the collection every day based off of these criteria:
 #- Exclude all daily outlier sales where the purchase price is below 10% of the daily average price
 #- Take the daily average of remaining transactions
 #a) First create a query that will be used as a subquery. Select the event date, the USD price, and the average USD price for each day using a window function. Save it as a temporary table.
 #b) Use the table you created in Part A to filter out rows where the USD prices is below 10% of the daily average and return a new estimated value which is just the daily average of the filtered data
 
 -- Creating a temporary table with daily event date, USD price, and daily average price

CREATE TEMPORARY TABLE DailyAveragePrices AS (
    SELECT 
        event_date,
        usd_price,
        AVG(usd_price) OVER(PARTITION BY event_date) AS daily_avg_price
    FROM pricedata
);
-- Calculating the estimated average value by filtering outliers and finding the daily average of remaining transactions
SELECT 
    event_date, AVG(usd_price) AS estimated_average_value
FROM
    DailyAveragePrices
WHERE
    usd_price >= 0.1 * daily_avg_price
GROUP BY event_date;

-- 14 Give a complete list ordered by wallet profitability (whether people have made or lost money):

SELECT 
    wallet_address,
    SUM(profit_loss) AS total_profit_loss
FROM (
    SELECT 
        token_id AS wallet_address,
        (usd_price - eth_price) AS profit_loss
    FROM 
        cryptopunkdata
    UNION ALL
    SELECT 
        seller_address AS wallet_address,
        (eth_price - usd_price) AS profit_loss
    FROM 
        cryptopunkdata
) AS profits_losses
GROUP BY 
    wallet_address
ORDER BY 
    total_profit_loss DESC;







