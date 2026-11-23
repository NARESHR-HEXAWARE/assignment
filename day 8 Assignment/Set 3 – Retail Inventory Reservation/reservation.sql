CREATE DATABASE RetailDB;
GO

USE RetailDB;
GO

CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(50)
);

CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50),
    CategoryID INT,
    Stock INT CHECK (Stock >= 0),
    Price DECIMAL(10,2),
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerName VARCHAR(50),
    OrderDate DATETIME DEFAULT GETDATE(),
    OrderStatus VARCHAR(20)
);

CREATE TABLE OrderDetails (
    OrderDetailID INT PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    Quantity INT CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE TABLE Sales (
    SaleID INT PRIMARY KEY,
    ProductID INT,
    SaleDate DATE,
    Quantity INT,
    Amount DECIMAL(10,2),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

INSERT INTO Categories VALUES
(1, 'Electronics'),
(2, 'Clothing'),
(3, 'Accessories');

INSERT INTO Products VALUES
(101, 'Laptop', 1, 20, 50000),
(102, 'Mobile', 1, 15, 20000),
(103, 'Headphones', 1, 5, 2000),
(104, 'Shirt', 2, 30, 1000),
(105, 'Jeans', 2, 10, 1500),
(106, 'Jacket', 2, 8, 3000),
(107, 'Watch', 3, 12, 2500),
(108, 'Wallet', 3, 4, 800);

-- Successful stock reservation
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE Products
    SET Stock = Stock - 2
    WHERE ProductID = 101
      AND Stock >= 2;

    IF @@ROWCOUNT = 0
        THROW 50001, 'Insufficient laptop stock', 1;

    UPDATE Products
    SET Stock = Stock - 3
    WHERE ProductID = 102
      AND Stock >= 3;

    IF @@ROWCOUNT = 0
        THROW 50002, 'Insufficient mobile stock', 1;

    INSERT INTO Orders
    VALUES (1001, 'Arun', GETDATE(), 'CONFIRMED');

    INSERT INTO OrderDetails VALUES
    (1, 1001, 101, 2, 50000),
    (2, 1001, 102, 3, 20000);

    COMMIT TRANSACTION;
    PRINT 'Order placed successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
END CATCH;

-- Verify successful reservation
SELECT * FROM Products;
SELECT * FROM Orders;
SELECT * FROM OrderDetails;

-- Insufficient stock rollback demonstration
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE Products
    SET Stock = Stock - 100
    WHERE ProductID = 101
      AND Stock >= 100;

    IF @@ROWCOUNT = 0
        THROW 50003, 'Insufficient stock - transaction rolled back', 1;

    INSERT INTO Orders
    VALUES (1002, 'Bala', GETDATE(), 'CONFIRMED');

    INSERT INTO OrderDetails
    VALUES (3, 1002, 101, 100, 50000);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
END CATCH;

-- Verify rollback
SELECT * FROM Products;
SELECT * FROM Orders;

-- Release stock when payment fails
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE Orders
    SET OrderStatus = 'CANCELLED'
    WHERE OrderID = 1001
      AND OrderStatus = 'CONFIRMED';

    IF @@ROWCOUNT = 0
        THROW 50004, 'Order cannot be cancelled', 1;

    UPDATE P
    SET P.Stock = P.Stock + OD.Quantity
    FROM Products P
    INNER JOIN OrderDetails OD
        ON P.ProductID = OD.ProductID
    WHERE OD.OrderID = 1001;

    COMMIT TRANSACTION;
    PRINT 'Stock released successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
END CATCH;

SELECT * FROM Products;
SELECT * FROM Orders;