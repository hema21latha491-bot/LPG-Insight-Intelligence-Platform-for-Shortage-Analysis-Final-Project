create database lpg_shortage_analysis;
USE lpg_shortage_analysis;


CREATE TABLE dim_location (
    location_id INT PRIMARY KEY,
    city VARCHAR(50),
    state VARCHAR(50),
    region VARCHAR(50)
);

select *  from fact_lpg_shortage;

CREATE TABLE dim_time (
    time_id INT PRIMARY KEY,
    date DATE,
    day INT,
    month INT,
    quarter INT,
    year INT
);

CREATE TABLE dim_supplier (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(50),
    supplier_type VARCHAR(20),
    rating DECIMAL(3,2)
);


CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    customer_type VARCHAR(20),
    income_group VARCHAR(20),
    connection_type VARCHAR(30)
);

USE lpg_shortage_analysis;
CREATE TABLE fact_lpg_shortage (
    transaction_id INT PRIMARY KEY,
    location_id INT,
    supplier_id INT,
    time_id INT,
    customer_id INT,
    demand_cylinders INT,
    supply_cylinders INT,
    shortage_cylinders INT,
    price_per_cylinder DECIMAL(10,2),
    subsidy_amount DECIMAL(10,2),
    delivery_delay_days INT,
    stock_available INT,
    transport_cost DECIMAL(10,2),
    weather_impact_score DECIMAL(3,2),
    strike_impact_flag TINYINT,
    festival_demand_flag TINYINT,
    emergency_supply_flag TINYINT,
    warehouse_capacity INT,
    fulfilled_orders INT,
    unfulfilled_orders INT
    );
 
  
  ##### Remove duplicates 

SELECT DISTINCT *
FROM fact_lpg_shortage;
    
 
 
 ##  Find duplicate records
 
 SELECT transaction_id, COUNT(*)
FROM fact_lpg_shortage
GROUP BY transaction_id
HAVING COUNT(*) > 1;


##  Filter high shortage records

SELECT *
FROM fact_lpg_shortage
WHERE shortage_cylinders > 10;

##   Replace NULL values (if any)
 
 
 SELECT 
COALESCE(subsidy_amount, 0) AS subsidy_amount
FROM fact_lpg_shortage;



###  AGGREGATION

##   Total shortage by location

SELECT l.state, SUM(f.shortage_cylinders) AS total_shortage
FROM fact_lpg_shortage f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.state
ORDER BY total_shortage DESC;
 
 
##  Monthly shortage trend

SELECT t.month, SUM(f.shortage_cylinders) AS total_shortage
FROM fact_lpg_shortage f
JOIN dim_time t ON f.time_id = t.time_id
GROUP BY t.month
ORDER BY t.month;
 
## Supplier performance

SELECT s.supplier_name,
       AVG(f.delivery_delay_days) AS avg_delay,
       SUM(f.shortage_cylinders) AS shortage
FROM fact_lpg_shortage f
JOIN dim_supplier s ON f.supplier_id = s.supplier_id
GROUP BY s.supplier_name
ORDER BY avg_delay DESC;


##  Impact of strikes

SELECT strike_impact_flag,
       AVG(shortage_cylinders) AS avg_shortage
FROM fact_lpg_shortage
GROUP BY strike_impact_flag;


##  Festival demand impact

SELECT festival_demand_flag,
       SUM(demand_cylinders) AS total_demand
FROM fact_lpg_shortage
GROUP BY festival_demand_flag;


##  Weather impact on shortage
 
 SELECT 
CASE 
    WHEN weather_impact_score > 0.7 THEN 'High Impact'
    WHEN weather_impact_score > 0.4 THEN 'Medium Impact'
    ELSE 'Low Impact'
END AS weather_category,
AVG(shortage_cylinders) AS avg_shortage
FROM fact_lpg_shortage
GROUP BY weather_category;
 
##  Running total shortage
 
 SELECT t.date,
       SUM(f.shortage_cylinders) OVER (ORDER BY t.date) AS running_total
FROM fact_lpg_shortage f
JOIN dim_time t ON f.time_id = t.time_id;


##  Top 5 worst cities

SELECT l.city,
       SUM(f.shortage_cylinders) AS total_shortage
FROM fact_lpg_shortage f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.city
ORDER BY total_shortage DESC
LIMIT 5;
 
 
 ##  Customer type impact
 
 
 SELECT c.customer_type,
       SUM(f.shortage_cylinders) AS shortage
FROM fact_lpg_shortage f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.customer_type;




CREATE TABLE fact_final AS
SELECT 
    f.transaction_id,
    t.time_id,
    s.supplier_id,
    l.location_id,
    c.customer_id,
    f.shortage_cylinders,
    f.demand_cylinders
FROM fact_lpg_shortage f
JOIN dim_time t ON f.date = t.date
JOIN dim_supplier s ON f.supplier_name = s.supplier_name
JOIN dim_location l ON f.city = l.city
JOIN dim_customer c ON f.customer_type = c.customer_type;

    
    


