

USE RetailOrderDB;
GO

-- 1. CURSOR-BASED PROCEDURE

CREATE OR ALTER PROCEDURE usp_CursorOrderFollowUp
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OrderID INT;

    DECLARE order_cursor CURSOR LOCAL FAST_FORWARD
    FOR
        SELECT OrderID
        FROM Orders
        WHERE Status = 'Pending'
          AND OrderDate < DATEADD(DAY,-3,GETDATE());

    OPEN order_cursor;

    FETCH NEXT FROM order_cursor INTO @OrderID;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        INSERT INTO OrderFollowUps
        (OrderID,Remarks)
        VALUES
        (@OrderID,'Order pending for more than 3 days');

        FETCH NEXT FROM order_cursor INTO @OrderID;
    END;

    CLOSE order_cursor;
    DEALLOCATE order_cursor;
END;
GO

-- EXECUTE CURSOR

EXEC usp_CursorOrderFollowUp;
GO

-- 2. SET-BASED IMPLEMENTATION

INSERT INTO OrderFollowUps
(OrderID,Remarks)
SELECT
    OrderID,
    'Order pending for more than 3 days'
FROM Orders
WHERE Status = 'Pending'
  AND OrderDate < DATEADD(DAY,-3,GETDATE());
GO

-- 3. DISPLAY FOLLOW-UP RECORDS

SELECT * FROM OrderFollowUps;
GO
