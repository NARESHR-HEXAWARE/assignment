


USE RetailOrderDB;
GO

-- 1. STORED PROCEDURE: PLACE ORDER

CREATE OR ALTER PROCEDURE usp_PlaceOrder
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT,
    @OrderID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Price DECIMAL(10,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Quantity <= 0
            THROW 50001, 'Invalid quantity', 1;

        -- Check and lock product stock

        SELECT @Price = SellingPrice
        FROM Products WITH (UPDLOCK, HOLDLOCK)
        WHERE ProductID = @ProductID
          AND StockQuantity >= @Quantity;

        IF @Price IS NULL
            THROW 50002, 'Product unavailable or insufficient stock', 1;

        -- Insert order

        INSERT INTO Orders(CustomerID,OrderDate,Status)
        VALUES(@CustomerID,GETDATE(),'Pending');

        SET @OrderID = SCOPE_IDENTITY();

        -- Insert order line

        INSERT INTO OrderLines
        (OrderID,ProductID,Quantity,UnitPrice)
        VALUES
        (@OrderID,@ProductID,@Quantity,@Price);

        -- Update stock

        UPDATE Products
        SET StockQuantity = StockQuantity - @Quantity
        WHERE ProductID = @ProductID;

        COMMIT TRANSACTION;

        SELECT @OrderID AS OrderNumber;
    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
GO

-- TEST PROCEDURE

DECLARE @NewOrderID INT;

EXEC usp_PlaceOrder
    @CustomerID = 105,
    @ProductID = 1,
    @Quantity = 2,
    @OrderID = @NewOrderID OUTPUT;

SELECT @NewOrderID AS GeneratedOrderNumber;
GO

-- 2. SCALAR FUNCTION: ORDER TOTAL WITH TAX

CREATE OR ALTER FUNCTION dbo.fn_OrderTotalWithTax
(
    @OrderID INT
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @Total DECIMAL(12,2);

    SELECT @Total =
        SUM(Quantity * UnitPrice) * 1.18
    FROM OrderLines
    WHERE OrderID = @OrderID;

    RETURN ISNULL(@Total,0);
END;
GO

-- TEST SCALAR FUNCTION

SELECT
    OrderID,
    dbo.fn_OrderTotalWithTax(OrderID) AS TotalWithTax
FROM Orders;
GO

-- 3. INLINE TABLE-VALUED FUNCTION

CREATE OR ALTER FUNCTION dbo.fn_CustomerOrders
(
    @CustomerID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        o.OrderID,
        o.OrderDate,
        o.Status,
        SUM(ol.Quantity * ol.UnitPrice) AS OrderTotal
    FROM Orders o
    JOIN OrderLines ol
        ON o.OrderID = ol.OrderID
    WHERE o.CustomerID = @CustomerID
    GROUP BY
        o.OrderID,
        o.OrderDate,
        o.Status
);
GO

-- TEST TABLE-VALUED FUNCTION

SELECT *
FROM dbo.fn_CustomerOrders(101);
GO
