

USE master;
GO

IF DB_ID('RetailOrderDB') IS NULL
    CREATE DATABASE RetailOrderDB;
GO

USE RetailOrderDB;
GO

-- 1. CREATE TABLES

CREATE TABLE Products
(
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    CostPrice DECIMAL(10,2),
    SupplierID INT,
    StockQuantity INT NOT NULL,
    ReorderLevel INT NOT NULL,
    SellingPrice DECIMAL(10,2) NOT NULL
);
GO

CREATE TABLE Orders
(
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    Status VARCHAR(30) DEFAULT 'Pending'
);
GO

CREATE TABLE OrderLines
(
    OrderLineID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
GO

CREATE TABLE OrderFollowUps
(
    FollowUpID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT,
    FollowUpDate DATETIME DEFAULT GETDATE(),
    Remarks VARCHAR(200)
);
GO

-- 2. INSERT SAMPLE DATA

INSERT INTO Products
VALUES
(1,'Laptop',35000,101,10,5,45000),
(2,'Mouse',300,102,3,5,500),
(3,'Keyboard',700,103,20,5,1000),
(4,'Monitor',8000,104,2,5,12000);
GO

INSERT INTO Orders(CustomerID,OrderDate,Status)
VALUES
(101,GETDATE(),'Pending'),
(102,DATEADD(DAY,-5,GETDATE()),'Pending'),
(103,GETDATE(),'Completed');
GO

INSERT INTO OrderLines(OrderID,ProductID,Quantity,UnitPrice)
VALUES
(1,1,1,45000),
(2,2,2,500),
(3,3,1,1000);
GO

-- 3. ORDER SUMMARY VIEW

CREATE OR ALTER VIEW vw_order_summary
AS
SELECT
    o.OrderID,
    o.CustomerID,
    o.OrderDate,
    o.Status,
    p.ProductName,
    ol.Quantity,
    ol.UnitPrice,
    ol.Quantity * ol.UnitPrice AS LineTotal
FROM Orders o
JOIN OrderLines ol
    ON o.OrderID = ol.OrderID
JOIN Products p
    ON ol.ProductID = p.ProductID;
GO

-- 4. LOW STOCK VIEW

CREATE OR ALTER VIEW vw_low_stock
AS
SELECT
    ProductID,
    ProductName,
    StockQuantity,
    ReorderLevel,
    SellingPrice
FROM Products
WHERE StockQuantity <= ReorderLevel;
GO

-- 5. UPDATABLE VIEW WITH CHECK OPTION

CREATE OR ALTER VIEW vw_products_low_stock
AS
SELECT
    ProductID,
    ProductName,
    StockQuantity,
    ReorderLevel,
    SellingPrice
FROM Products
WHERE StockQuantity <= ReorderLevel
WITH CHECK OPTION;
GO

-- 6. TEST VIEWS

SELECT * FROM vw_order_summary;
SELECT * FROM vw_low_stock;
SELECT * FROM vw_products_low_stock;
GO

-- 7. TEST UPDATABLE VIEW

UPDATE vw_products_low_stock
SET StockQuantity = 4
WHERE ProductID = 2;
GO

SELECT * FROM vw_products_low_stock;
GO
