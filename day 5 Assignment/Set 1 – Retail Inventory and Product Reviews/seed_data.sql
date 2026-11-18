
USE RetailInventoryDB;
GO
SET NOCOUNT ON;

INSERT INTO dbo.Categories (CategoryName) VALUES
(N'Electronics'),(N'Home Appliances'),(N'Clothing'),(N'Footwear'),(N'Groceries'),
(N'Furniture'),(N'Stationery'),(N'Beauty'),(N'Sports'),(N'Toys');

INSERT INTO dbo.Suppliers (SupplierName, SupplierPhone) VALUES
(N'Alpha Distributors','9000000001'),(N'Bright Supplies','9000000002'),
(N'City Wholesale','9000000003'),(N'Delta Traders','9000000004'),
(N'Evergreen Goods','9000000005'),(N'FreshMart Supply','9000000006'),
(N'Global Office','9000000007'),(N'Horizon Care','9000000008'),
(N'Infinity Sports','9000000009'),(N'Joy Toys','9000000010');

INSERT INTO dbo.Warehouses (WarehouseName, City) VALUES
(N'Central Depot',N'Chennai'),(N'North Depot',N'Delhi'),
(N'West Depot',N'Mumbai'),(N'South Depot',N'Bengaluru'),
(N'East Depot',N'Kolkata'),(N'Port Depot',N'Kochi'),
(N'Airport Depot',N'Hyderabad'),(N'Hill Depot',N'Coimbatore'),
(N'City Depot',N'Pune'),(N'Express Depot',N'Jaipur');

INSERT INTO dbo.Products (SKU, ProductName, CategoryID, SupplierID, ReorderLevel, ProductStatus) VALUES
('SKU1001',N'Wireless Mouse',1,1,10,'ACTIVE'),
('SKU1002',N'Electric Kettle',2,2,7,'ACTIVE'),
('SKU1003',N'Cotton T-Shirt',3,3,20,'ACTIVE'),
('SKU1004',N'Running Shoes',4,4,12,'ACTIVE'),
('SKU1005',N'Rice Pack 5kg',5,5,25,'ACTIVE'),
('SKU1006',N'Office Chair',6,6,5,'ACTIVE'),
('SKU1007',N'Notebook A5',7,7,30,'ACTIVE'),
('SKU1008',N'Shampoo 250ml',8,8,15,'ACTIVE'),
('SKU1009',N'Football',9,9,8,'ACTIVE'),
('SKU1010',N'Puzzle Set',10,10,6,'ACTIVE'),
('SKU1011',N'Old USB Cable',1,1,5,'DISCONTINUED'),
('SKU1012',N'Legacy Toy Car',10,10,5,'DISCONTINUED');

INSERT INTO dbo.Inventory (ProductID, WarehouseID, Quantity) VALUES
(1,1,45),(2,2,30),(3,3,120),(4,4,35),(5,5,80),
(6,6,10),(7,7,200),(8,8,55),(9,9,24),(10,10,40),
(1,2,18),(5,1,50),(11,1,3),(12,10,2);

PRINT 'Initial sample row counts (all five tables have at least 10 rows):';
SELECT 'Categories' AS TableName, COUNT(*) AS RowCount FROM dbo.Categories
UNION ALL SELECT 'Suppliers', COUNT(*) FROM dbo.Suppliers
UNION ALL SELECT 'Warehouses', COUNT(*) FROM dbo.Warehouses
UNION ALL SELECT 'Products', COUNT(*) FROM dbo.Products
UNION ALL SELECT 'Inventory', COUNT(*) FROM dbo.Inventory;

/* Four INTENTIONAL failures; TRY/CATCH keeps the rest of the demonstration running. */
PRINT 'EXPECTED FAILURE 1 - duplicate SKU (UNIQUE constraint)';
BEGIN TRY
    INSERT INTO dbo.Products (SKU, ProductName, CategoryID, SupplierID)
    VALUES ('SKU1001',N'Duplicate Mouse',1,1);
END TRY
BEGIN CATCH
    SELECT 'Duplicate SKU' AS FailureTest, ERROR_MESSAGE() AS ExpectedError;
END CATCH;

PRINT 'EXPECTED FAILURE 2 - missing parent category (FOREIGN KEY)';
BEGIN TRY
    INSERT INTO dbo.Products (SKU, ProductName, CategoryID, SupplierID)
    VALUES ('SKU9998',N'Orphan Product',9999,1);
END TRY
BEGIN CATCH
    SELECT 'Missing parent' AS FailureTest, ERROR_MESSAGE() AS ExpectedError;
END CATCH;

PRINT 'EXPECTED FAILURE 3 - negative stock (CHECK constraint)';
BEGIN TRY
    INSERT INTO dbo.Inventory (ProductID, WarehouseID, Quantity)
    VALUES (2,1,-9);
END TRY
BEGIN CATCH
    SELECT 'Negative quantity' AS FailureTest, ERROR_MESSAGE() AS ExpectedError;
END CATCH;

PRINT 'EXPECTED FAILURE 4 - NULL product name (NOT NULL constraint)';
BEGIN TRY
    INSERT INTO dbo.Products (SKU, ProductName, CategoryID, SupplierID)
    VALUES ('SKU9999',NULL,1,1);
END TRY
BEGIN CATCH
    SELECT 'Mandatory column NULL' AS FailureTest, ERROR_MESSAGE() AS ExpectedError;
END CATCH;

/* Before / after: supplier phone correction. */
PRINT 'BEFORE supplier phone correction';
SELECT SupplierID, SupplierName, SupplierPhone
FROM dbo.Suppliers WHERE SupplierName = N'Alpha Distributors';

UPDATE dbo.Suppliers
SET SupplierPhone = '9888877766'
WHERE SupplierName = N'Alpha Distributors';

PRINT 'AFTER supplier phone correction';
SELECT SupplierID, SupplierName, SupplierPhone
FROM dbo.Suppliers WHERE SupplierName = N'Alpha Distributors';

/* Before / after: delete discontinued SKUs; child stock cascades. */
PRINT 'BEFORE discontinued-product deletion';
SELECT p.SKU, p.ProductName, p.ProductStatus, i.WarehouseID, i.Quantity
FROM dbo.Products AS p
LEFT JOIN dbo.Inventory AS i ON i.ProductID = p.ProductID
WHERE p.ProductStatus = 'DISCONTINUED'
ORDER BY p.SKU;

DELETE FROM dbo.Products
WHERE ProductStatus = 'DISCONTINUED';

PRINT 'AFTER discontinued-product deletion (zero rows expected)';
SELECT SKU, ProductName, ProductStatus
FROM dbo.Products WHERE ProductStatus = 'DISCONTINUED';

PRINT 'Remaining products and inventory (10 and 12 rows expected)';
SELECT 'Products' AS TableName, COUNT(*) AS RowCount FROM dbo.Products
UNION ALL SELECT 'Inventory', COUNT(*) FROM dbo.Inventory;
GO
