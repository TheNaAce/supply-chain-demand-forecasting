CREATE DATABASE supply_chain_db;

USE supply_chain_db;
SELECT DATABASE();
USE supply_chain_db;

CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    unit_price DECIMAL(10,2)
);

DESCRIBE products;

USE supply_chain_db;

CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    state VARCHAR(50)
);

CREATE TABLE sales (
    sale_id INT PRIMARY KEY AUTO_INCREMENT,
    sale_date DATE NOT NULL,
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    quantity_sold INT NOT NULL,
    unit_price DECIMAL(10,2),

    FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id)
);

CREATE TABLE inventory (
    inventory_id INT PRIMARY KEY AUTO_INCREMENT,
    inventory_date DATE NOT NULL,
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    stock_quantity INT NOT NULL,

    FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id)
);

CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_name VARCHAR(100) NOT NULL,
    supplier_location VARCHAR(100),
    lead_time_days INT NOT NULL
);

INSERT INTO suppliers
(supplier_name, supplier_location, lead_time_days)
VALUES
('Eastern Beverages Ltd', 'Kolkata', 3),
('National Beverage Supply', 'Bhubaneswar', 5),
('Western Distribution Co', 'Mumbai', 7),
('Northern Beverage Partners', 'Delhi', 6),
('South India Beverages', 'Bangalore', 4);

SELECT * FROM suppliers;

INSERT INTO products
(product_name, category, unit_price)
VALUES
('Lager 500ml', 'Lager', 120.00),
('Lager 650ml', 'Lager', 150.00),
('Premium Lager 500ml', 'Premium', 180.00),
('Strong Beer 500ml', 'Strong', 140.00),
('Strong Beer 650ml', 'Strong', 170.00),
('Wheat Beer 500ml', 'Wheat', 190.00),
('Wheat Beer 650ml', 'Wheat', 220.00),
('Non-Alcoholic Malt 500ml', 'Non-Alcoholic', 110.00);

INSERT INTO warehouses
(warehouse_name, city, state)
VALUES
('East Distribution Center', 'Kolkata', 'West Bengal'),
('Central Distribution Center', 'Bhubaneswar', 'Odisha'),
('West Distribution Center', 'Mumbai', 'Maharashtra'),
('North Distribution Center', 'Delhi', 'Delhi'),
('South Distribution Center', 'Bangalore', 'Karnataka');

SELECT * FROM warehouses;

USE supply_chain_db;

CREATE TABLE raw_sales (
    id INT,
    sale_date DATE,
    item_id VARCHAR(50),
    quantity DECIMAL(12,3),
    price_base DECIMAL(12,2),
    sum_total DECIMAL(14,2),
    store_id INT
);
USE supply_chain_db;
SHOW TABLES;

SELECT COUNT(*) AS total_records
FROM raw_sales;
SELECT *
FROM raw_sales
LIMIT 10;
SELECT
    MIN(sale_date) AS first_date,
    MAX(sale_date) AS last_date
FROM raw_sales;

SELECT
    SUM(sale_date IS NULL) AS missing_dates,
    SUM(item_id IS NULL) AS missing_items,
    SUM(quantity IS NULL) AS missing_quantity,
    SUM(price_base IS NULL) AS missing_prices,
    SUM(store_id IS NULL) AS missing_stores
FROM raw_sales;

SELECT 
    SUM(quantity) AS total_quantity_sold
FROM raw_sales;

SELECT 
    SUM(sum_total) AS total_revenue
FROM raw_sales;

SELECT 
    AVG(quantity) AS average_quantity_per_transaction
FROM raw_sales;

SELECT
    MIN(sale_date) AS first_sale_date,
    MAX(sale_date) AS last_sale_date,
    COUNT(DISTINCT sale_date) AS number_of_days
FROM raw_sales;

SELECT
    sale_date,
    SUM(quantity) AS daily_demand
FROM raw_sales
GROUP BY sale_date
ORDER BY sale_date;

SELECT
    item_id,
    SUM(quantity) AS total_demand
FROM raw_sales
GROUP BY item_id
ORDER BY total_demand DESC;

SELECT
    YEAR(sale_date) AS year,
    MONTH(sale_date) AS month,
    SUM(quantity) AS total_demand,
    SUM(sum_total) AS total_revenue
FROM raw_sales
GROUP BY
    YEAR(sale_date),
    MONTH(sale_date)
ORDER BY
    year,
    month;
    
SELECT
    DAYNAME(sale_date) AS day_of_week,
    SUM(quantity) AS total_demand,
    AVG(quantity) AS average_transaction_quantity
FROM raw_sales
GROUP BY DAYOFWEEK(sale_date), DAYNAME(sale_date)
ORDER BY DAYOFWEEK(sale_date);

SELECT
    item_id,
    SUM(quantity) AS total_demand,
    SUM(sum_total) AS total_revenue
FROM raw_sales
GROUP BY item_id
ORDER BY total_demand DESC
LIMIT 10;

SELECT
    store_id,
    SUM(quantity) AS total_demand,
    SUM(sum_total) AS total_revenue,
    AVG(quantity) AS average_transaction_quantity
FROM raw_sales
GROUP BY store_id
ORDER BY total_demand DESC;

USE supply_chain_db;

WITH daily_demand AS (
    SELECT
        sale_date,
        SUM(quantity) AS total_demand
    FROM raw_sales
    GROUP BY sale_date
)

SELECT
    sale_date,
    total_demand,
    LAG(total_demand) OVER (
        ORDER BY sale_date
    ) AS previous_day_demand
FROM daily_demand
ORDER BY sale_date;

WITH daily_demand AS (
    SELECT
        sale_date,
        SUM(quantity) AS total_demand
    FROM raw_sales
    GROUP BY sale_date
),

demand_comparison AS (
    SELECT
        sale_date,
        total_demand,
        LAG(total_demand) OVER (
            ORDER BY sale_date
        ) AS previous_day_demand
    FROM daily_demand
)

SELECT
    sale_date,
    total_demand,
    previous_day_demand,
    ROUND(
        ((total_demand - previous_day_demand)
        / NULLIF(previous_day_demand, 0)) * 100,
        2
    ) AS demand_growth_pct
FROM demand_comparison
ORDER BY sale_date;

WITH daily_demand AS (
    SELECT
        sale_date,
        SUM(quantity) AS total_demand
    FROM raw_sales
    GROUP BY sale_date
)

SELECT
    sale_date,
    total_demand,
    ROUND(
        AVG(total_demand) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_7_days
FROM daily_demand
ORDER BY sale_date;

CREATE OR REPLACE VIEW daily_demand_analysis AS

WITH daily_demand AS (
    SELECT
        sale_date,
        SUM(quantity) AS total_demand
    FROM raw_sales
    GROUP BY sale_date
),

demand_metrics AS (
    SELECT
        sale_date,
        total_demand,

        LAG(total_demand) OVER (
            ORDER BY sale_date
        ) AS previous_day_demand,

        AVG(total_demand) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS moving_avg_7_days

    FROM daily_demand
)

SELECT
    sale_date,
    ROUND(total_demand, 2) AS total_demand,
    ROUND(previous_day_demand, 2) AS previous_day_demand,
    ROUND(moving_avg_7_days, 2) AS moving_avg_7_days,

    ROUND(
        (
            (total_demand - previous_day_demand)
            / NULLIF(previous_day_demand, 0)
        ) * 100,
        2
    ) AS demand_growth_pct

FROM demand_metrics;

WITH daily_demand AS (
    SELECT
        sale_date,
        SUM(quantity) AS total_demand
    FROM raw_sales
    GROUP BY sale_date
)

SELECT
    ROUND(AVG(total_demand), 2) AS avg_daily_demand,
    ROUND(STDDEV(total_demand), 2) AS demand_stddev
FROM daily_demand;

WITH daily_demand AS (
    SELECT
        sale_date,
        SUM(quantity) AS total_demand
    FROM raw_sales
    GROUP BY sale_date
),

stats AS (
    SELECT
        AVG(total_demand) AS avg_demand,
        STDDEV(total_demand) AS std_demand
    FROM daily_demand
)

SELECT
    d.sale_date,
    ROUND(d.total_demand, 2) AS total_demand,
    ROUND(s.avg_demand, 2) AS avg_demand,
    ROUND(s.std_demand, 2) AS std_demand
FROM daily_demand d
CROSS JOIN stats s
WHERE d.total_demand > s.avg_demand + (2 * s.std_demand)
ORDER BY d.total_demand DESC;

CREATE OR REPLACE VIEW daily_demand_analysis AS

WITH daily_demand AS (
    SELECT
        sale_date,
        SUM(quantity) AS total_demand
    FROM raw_sales
    GROUP BY sale_date
),

stats AS (
    SELECT
        AVG(total_demand) AS avg_demand,
        STDDEV(total_demand) AS std_demand
    FROM daily_demand
),

metrics AS (
    SELECT
        d.sale_date,
        d.total_demand,

        LAG(d.total_demand) OVER (
            ORDER BY d.sale_date
        ) AS previous_day_demand,

        AVG(d.total_demand) OVER (
            ORDER BY d.sale_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS moving_avg_7_days

    FROM daily_demand d
)

SELECT
    m.sale_date,
    ROUND(m.total_demand, 2) AS total_demand,
    ROUND(m.previous_day_demand, 2) AS previous_day_demand,
    ROUND(m.moving_avg_7_days, 2) AS moving_avg_7_days,

    ROUND(
        ((m.total_demand - m.previous_day_demand)
        / NULLIF(m.previous_day_demand, 0)) * 100,
        2
    ) AS demand_growth_pct,

    CASE
        WHEN m.total_demand > s.avg_demand + (2 * s.std_demand)
            THEN 'HIGH_DEMAND_ANOMALY'

        WHEN m.total_demand < s.avg_demand - (2 * s.std_demand)
            THEN 'LOW_DEMAND_ANOMALY'

        ELSE 'NORMAL'
    END AS demand_status

FROM metrics m
CROSS JOIN stats s;

CREATE OR REPLACE VIEW daily_demand_analysis AS

WITH daily_demand AS (
    SELECT
        sale_date,
        SUM(quantity) AS total_demand
    FROM raw_sales
    GROUP BY sale_date
),

stats AS (
    SELECT
        AVG(total_demand) AS avg_demand,
        STDDEV(total_demand) AS std_demand
    FROM daily_demand
),

metrics AS (
    SELECT
        d.sale_date,
        d.total_demand,

        LAG(d.total_demand) OVER (
            ORDER BY d.sale_date
        ) AS previous_day_demand,

        AVG(d.total_demand) OVER (
            ORDER BY d.sale_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS moving_avg_7_days

    FROM daily_demand d
)

SELECT
    m.sale_date,
    ROUND(m.total_demand, 2) AS total_demand,
    ROUND(m.previous_day_demand, 2) AS previous_day_demand,
    ROUND(m.moving_avg_7_days, 2) AS moving_avg_7_days,

    ROUND(
        ((m.total_demand - m.previous_day_demand)
        / NULLIF(m.previous_day_demand, 0)) * 100,
        2
    ) AS demand_growth_pct,

    CASE
        WHEN m.total_demand > s.avg_demand + (2 * s.std_demand)
            THEN 'HIGH_DEMAND_ANOMALY'

        WHEN m.total_demand < s.avg_demand - (2 * s.std_demand)
            THEN 'LOW_DEMAND_ANOMALY'

        ELSE 'NORMAL'
    END AS demand_status


USE supply_chain_db;

CREATE OR REPLACE VIEW forecasting_data AS
SELECT
    sale_date,
    ROUND(SUM(quantity), 2) AS demand
FROM raw_sales
GROUP BY sale_date;

SELECT *
FROM forecasting_data
ORDER BY sale_date
LIMIT 10;

CREATE OR REPLACE VIEW forecast_train AS
SELECT *
FROM forecasting_data
WHERE sale_date < (
    SELECT MAX(sale_date)
    FROM forecasting_data
) - INTERVAL 30 DAY;

CREATE OR REPLACE VIEW forecast_test AS
SELECT *
FROM forecasting_data
WHERE sale_date >= (
    SELECT MAX(sale_date)
    FROM forecasting_data
) - INTERVAL 30 DAY;

SELECT 'TRAIN' AS dataset, COUNT(*) AS row_count
FROM forecast_train
UNION ALL
SELECT 'TEST', COUNT(*)
FROM forecast_test;