

USE TelecomDB;
GO

-- 1. CURSOR-BASED PROCEDURE

CREATE OR ALTER PROCEDURE usp_CursorLowBalanceNotification
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SubscriberID INT;
    DECLARE @Balance DECIMAL(12,2);

    DECLARE subscriber_cursor CURSOR LOCAL FAST_FORWARD
    FOR
        SELECT SubscriberID,Balance
        FROM Subscribers
        WHERE SubscriberType = 'Prepaid'
          AND Balance < 50;

    OPEN subscriber_cursor;

    FETCH NEXT FROM subscriber_cursor
    INTO @SubscriberID,@Balance;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        INSERT INTO NotificationLog
        (
            SubscriberID,
            Message,
            IsRead,
            CreatedAt
        )
        VALUES
        (
            @SubscriberID,
            'Your prepaid balance is below 50. Please recharge.',
            0,
            GETDATE()
        );

        FETCH NEXT FROM subscriber_cursor
        INTO @SubscriberID,@Balance;

    END;

    CLOSE subscriber_cursor;
    DEALLOCATE subscriber_cursor;
END;
GO

-- EXECUTE CURSOR PROCEDURE

EXEC usp_CursorLowBalanceNotification;
GO

-- 2. SET-BASED IMPLEMENTATION

INSERT INTO NotificationLog
(
    SubscriberID,
    Message,
    IsRead,
    CreatedAt
)
SELECT
    SubscriberID,
    'Your prepaid balance is below 50. Please recharge.',
    0,
    GETDATE()
FROM Subscribers
WHERE SubscriberType = 'Prepaid'
  AND Balance < 50;
GO

-- 3. DISPLAY NOTIFICATIONS

SELECT * FROM NotificationLog;
GO

-- 4. EXECUTION TIME COMPARISON
-- Both tests are rolled back to avoid keeping
-- duplicate test notifications.

SET STATISTICS TIME ON;

BEGIN TRANSACTION;

EXEC usp_CursorLowBalanceNotification;

ROLLBACK TRANSACTION;

SET STATISTICS TIME OFF;
GO

SET STATISTICS TIME ON;

BEGIN TRANSACTION;

INSERT INTO NotificationLog
(
    SubscriberID,
    Message,
    IsRead,
    CreatedAt
)
SELECT
    SubscriberID,
    'Your prepaid balance is below 50. Please recharge.',
    0,
    GETDATE()
FROM Subscribers
WHERE SubscriberType = 'Prepaid'
  AND Balance < 50;

ROLLBACK TRANSACTION;

SET STATISTICS TIME OFF;
GO
