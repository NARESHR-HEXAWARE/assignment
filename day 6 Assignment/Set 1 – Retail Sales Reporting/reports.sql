IF DB_ID(N'RetailSalesReportingDB') IS NULL
    CREATE DATABASE RetailSalesReportingDB;
GO
USE RetailSalesReportingDB;
GO


IF OBJECT_ID(N'dbo.customers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.customers (
        customer_id INT NOT NULL PRIMARY KEY,
        full_name NVARCHAR(100) NOT NULL,
        city NVARCHAR(60) NOT NULL,
        email NVARCHAR(150) NOT NULL UNIQUE
    );
END;
IF OBJECT_ID(N'dbo.products', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.products (
        product_id INT NOT NULL PRIMARY KEY,
        product_name NVARCHAR(100) NOT NULL,
        category NVARCHAR(60) NOT NULL
    );
END;
IF OBJECT_ID(N'dbo.orders', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.orders (
        order_id INT NOT NULL PRIMARY KEY,
        customer_id INT NOT NULL REFERENCES dbo.customers(customer_id),
        order_date DATE NOT NULL,
        order_status VARCHAR(15) NOT NULL
            CONSTRAINT CK_retail_order_status CHECK (order_status IN ('Completed','Pending','Cancelled')),
        delivery_days INT NULL
    );
END;
IF OBJECT_ID(N'dbo.order_items', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.order_items (
        order_id INT NOT NULL REFERENCES dbo.orders(order_id),
        product_id INT NOT NULL REFERENCES dbo.products(product_id),
        quantity INT NOT NULL CHECK (quantity > 0),
        unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
        CONSTRAINT PK_retail_order_items PRIMARY KEY (order_id, product_id)
    );
END;
IF OBJECT_ID(N'dbo.payments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.payments (
        payment_id INT NOT NULL PRIMARY KEY,
        order_id INT NOT NULL UNIQUE REFERENCES dbo.orders(order_id),
        amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
        paid_on DATE NOT NULL
    );
END;
GO

/* Seed once; all values are illustrative and deterministic. */
IF NOT EXISTS (SELECT 1 FROM dbo.customers WHERE customer_id = 1)
BEGIN
    INSERT INTO dbo.customers (customer_id, full_name, city, email) VALUES
    (1,N'Asha Kumar',N'Chennai',N'asha@example.com'),
    (2,N'Ravi Shah',N'Mumbai',N'ravi@example.com'),
    (3,N'Meena Rao',N'Chennai',N'meena@example.com'),
    (4,N'Arun Das',N'Bengaluru',N'arun@example.com'),
    (5,N'Priya Nair',N'Kochi',N'priya@example.com'),
    (6,N'Kiran Patel',N'Mumbai',N'kiran@example.com'),
    (7,N'Sara Ali',N'Hyderabad',N'sara@example.com'),
    (8,N'Dev Menon',N'Kochi',N'dev@example.com'),
    (9,N'Neha Singh',N'Delhi',N'neha@example.com'),
    (10,N'Vikram Roy',N'Chennai',N'vikram@example.com');
END;
IF NOT EXISTS (SELECT 1 FROM dbo.products WHERE product_id = 1)
BEGIN
    INSERT INTO dbo.products (product_id, product_name, category) VALUES
    (1,N'Laptop',N'Electronics'),(2,N'Headphones',N'Electronics'),
    (3,N'Mouse',N'Electronics'),(4,N'Office Chair',N'Furniture'),
    (5,N'Desk',N'Furniture'),(6,N'Notebook',N'Stationery'),
    (7,N'Pen Pack',N'Stationery'),(8,N'Water Bottle',N'Home');
END;
IF NOT EXISTS (SELECT 1 FROM dbo.orders WHERE order_id = 1001)
BEGIN
    INSERT INTO dbo.orders (order_id,customer_id,order_date,order_status,delivery_days) VALUES
    (1001,1,'2026-01-05','Completed',3),
    (1002,2,'2026-01-05','Completed',5),
    (1003,1,'2026-01-17','Completed',NULL),
    (1004,3,'2026-02-02','Completed',2),
    (1005,1,'2026-02-14','Completed',4),
    (1006,4,'2026-02-14','Completed',NULL),
    (1007,5,'2026-03-01','Completed',6),
    (1008,1,'2026-03-12','Completed',2),
    (1009,6,'2026-03-12','Completed',3),
    (1010,7,'2026-03-19','Completed',NULL),
    (1011,2,'2026-03-20','Pending',NULL),
    (1012,8,'2026-03-21','Cancelled',NULL),
    (1013,3,'2026-03-22','Completed',4),
    (1014,4,'2026-03-25','Completed',5),
    (1015,5,'2026-03-25','Completed',NULL);
END;
IF NOT EXISTS (SELECT 1 FROM dbo.order_items WHERE order_id = 1001)
BEGIN
    INSERT INTO dbo.order_items (order_id,product_id,quantity,unit_price) VALUES
    (1001,1,1,50000),(1001,3,2,500),
    (1002,2,2,2000),(1002,6,5,100),
    (1003,4,1,7000),
    (1004,5,1,9000),(1004,7,2,150),
    (1005,2,1,2000),(1005,8,2,400),
    (1006,1,1,50000),
    (1007,4,2,7000),(1007,6,10,100),
    (1008,3,3,500),(1008,7,4,150),
    (1009,8,3,400),
    (1010,5,1,9000),(1010,6,2,100),
    (1011,1,1,50000),
    (1012,2,1,2000),
    (1013,2,3,2000),(1013,7,2,150),
    (1014,1,1,50000),(1014,8,1,400),
    (1015,6,8,100),(1015,3,1,500);
END;
IF NOT EXISTS (SELECT 1 FROM dbo.payments WHERE payment_id = 1)
BEGIN
    INSERT INTO dbo.payments (payment_id,order_id,amount,paid_on) VALUES
    (1,1001,51000,'2026-01-05'),(2,1002,4500,'2026-01-05'),
    (3,1003,7000,'2026-01-17'),(4,1004,9300,'2026-02-02'),
    (5,1005,2800,'2026-02-14'),(6,1006,50000,'2026-02-14'),
    (7,1007,15000,'2026-03-01'),(8,1008,2100,'2026-03-12'),
    (9,1009,1200,'2026-03-12'),(10,1010,9200,'2026-03-19'),
    (11,1013,6300,'2026-03-22'),(12,1014,50400,'2026-03-25');
END;
GO


SELECT TOP (5) p.product_id, p.product_name,
       SUM(oi.quantity) AS units_sold,
       CAST(SUM(oi.quantity * oi.unit_price) AS DECIMAL(14,2)) AS revenue
FROM dbo.order_items AS oi
JOIN dbo.products AS p ON p.product_id = oi.product_id
JOIN dbo.orders AS o ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_id, p.product_name
ORDER BY revenue DESC, p.product_id;


SELECT FORMAT(o.order_date, 'yyyy-MM') AS sales_month,
       COUNT(DISTINCT o.order_id) AS completed_orders,
       CAST(SUM(oi.quantity * oi.unit_price) AS DECIMAL(14,2)) AS monthly_sales
FROM dbo.orders AS o
JOIN dbo.order_items AS oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY YEAR(o.order_date), MONTH(o.order_date), FORMAT(o.order_date, 'yyyy-MM')
ORDER BY YEAR(o.order_date), MONTH(o.order_date);

SELECT c.customer_id, UPPER(c.full_name) AS customer_name_upper,
       COUNT(o.order_id) AS total_orders
FROM dbo.customers AS c
JOIN dbo.orders AS o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
HAVING COUNT(o.order_id) > 3
ORDER BY total_orders DESC, c.customer_id;

WITH order_totals AS (
    SELECT o.order_id, c.city,
           SUM(oi.quantity * oi.unit_price) AS basket_value
    FROM dbo.orders AS o
    JOIN dbo.customers AS c ON c.customer_id = o.customer_id
    JOIN dbo.order_items AS oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.order_id, c.city
)
SELECT city, COUNT(*) AS completed_orders,
       CAST(ROUND(AVG(CAST(basket_value AS DECIMAL(14,2))), 2) AS DECIMAL(14,2))
           AS average_basket_value
FROM order_totals
GROUP BY city
ORDER BY city;


SELECT o.order_id, c.full_name, o.order_date, o.order_status,
       CONCAT('Order ', o.order_id, ' - payment not found') AS payment_message
FROM dbo.orders AS o
JOIN dbo.customers AS c ON c.customer_id = o.customer_id
LEFT JOIN dbo.payments AS pay ON pay.order_id = o.order_id
WHERE pay.payment_id IS NULL
ORDER BY o.order_id;

SELECT c.customer_id, c.full_name, c.city
FROM dbo.customers AS c
LEFT JOIN dbo.orders AS o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

WITH category_sales AS (
    SELECT p.category,
           SUM(CAST(oi.quantity * oi.unit_price AS DECIMAL(18,2))) AS category_revenue
    FROM dbo.order_items AS oi
    JOIN dbo.products AS p ON p.product_id = oi.product_id
    JOIN dbo.orders AS o ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.category
)
SELECT category,
       CAST(category_revenue AS DECIMAL(14,2)) AS category_revenue,
       CAST(ROUND(100.0 * category_revenue /
            NULLIF(SUM(category_revenue) OVER (), 0), 2) AS DECIMAL(6,2))
            AS revenue_share_pct
FROM category_sales
ORDER BY category_revenue DESC, category;

SELECT TOP (1) o.order_date AS best_sales_day,
       COUNT(DISTINCT o.order_id) AS completed_orders,
       CAST(SUM(oi.quantity * oi.unit_price) AS DECIMAL(14,2)) AS day_sales
FROM dbo.orders AS o
JOIN dbo.order_items AS oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY o.order_date
ORDER BY day_sales DESC, o.order_date ASC;

WITH order_totals AS (
    SELECT o.order_id, o.order_date, c.full_name, c.city,
           SUM(oi.quantity * oi.unit_price) AS basket_value
    FROM dbo.orders o
    JOIN dbo.customers c ON c.customer_id = o.customer_id
    JOIN dbo.order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.order_id, o.order_date, c.full_name, c.city
)
SELECT order_id,
       CONCAT(UPPER(full_name), ' (', city, ')') AS customer_label,
       FORMAT(order_date, 'dd MMM yyyy', 'en-IN') AS formatted_order_date,
       DATEDIFF(DAY, order_date, CONVERT(DATE,'2026-04-01')) AS days_before_report,
       FORMAT(ROUND(basket_value, 2), 'N2', 'en-IN') AS basket_value_inr
FROM order_totals
ORDER BY order_id;


SELECT COUNT(*) AS all_orders_including_nulls,
       COUNT(delivery_days) AS orders_with_delivery_days,
       CAST(AVG(CAST(delivery_days AS DECIMAL(10,4))) AS DECIMAL(10,4))
          AS avg_non_null_delivery_days
FROM dbo.orders;

