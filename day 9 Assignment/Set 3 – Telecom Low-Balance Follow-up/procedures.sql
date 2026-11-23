

USE TelecomDB;
GO

-- 1. STORED PROCEDURE: RECHARGE

CREATE OR ALTER PROCEDURE usp_Recharge
    @SubscriberID INT,
    @Amount DECIMAL(12,2),
    @PlanID INT,
    @NewBalance DECIMAL(12,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PlanAmount DECIMAL(12,2);
    DECLARE @ValidityDays INT;

    BEGIN TRY

        BEGIN TRANSACTION;

        -- Validate amount

        IF @Amount <= 0
            THROW 50001,'Invalid recharge amount',1;

        -- Validate and lock prepaid subscriber

        IF NOT EXISTS
        (
            SELECT 1
            FROM Subscribers WITH (UPDLOCK,HOLDLOCK)
            WHERE SubscriberID = @SubscriberID
              AND SubscriberType = 'Prepaid'
        )
            THROW 50002,'Prepaid subscriber not found',1;

        -- Validate plan

        SELECT
            @PlanAmount = PlanAmount,
            @ValidityDays = ValidityDays
        FROM Plans
        WHERE PlanID = @PlanID;

        IF @PlanAmount IS NULL
            THROW 50003,'Invalid recharge plan',1;

        IF @Amount < @PlanAmount
            THROW 50004,'Recharge amount is below plan amount',1;

        -- Update balance and validity

        UPDATE Subscribers
        SET
            Balance = Balance + @Amount,
            PlanID = @PlanID,
            ValidityEndDate =
                DATEADD(DAY,@ValidityDays,CAST(GETDATE() AS DATE))
        WHERE SubscriberID = @SubscriberID;

        -- Insert recharge history

        INSERT INTO Recharges
        (
            SubscriberID,
            RechargeAmount,
            RechargeDate,
            PlanID
        )
        VALUES
        (
            @SubscriberID,
            @Amount,
            GETDATE(),
            @PlanID
        );

        -- Return new balance

        SELECT @NewBalance = Balance
        FROM Subscribers
        WHERE SubscriberID = @SubscriberID;

        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
GO

-- TEST RECHARGE PROCEDURE

DECLARE @Balance DECIMAL(12,2);

EXEC usp_Recharge
    @SubscriberID = 101,
    @Amount = 199,
    @PlanID = 2,
    @NewBalance = @Balance OUTPUT;

SELECT @Balance AS UpdatedBalance;
GO

-- 2. SCALAR FUNCTION: VALIDITY DAYS LEFT

CREATE OR ALTER FUNCTION dbo.fn_ValidityDaysLeft
(
    @SubscriberID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Days INT;

    SELECT @Days =
        DATEDIFF(
            DAY,
            CAST(GETDATE() AS DATE),
            ValidityEndDate
        )
    FROM Subscribers
    WHERE SubscriberID = @SubscriberID;

    RETURN @Days;
END;
GO

-- TEST SCALAR FUNCTION

SELECT
    SubscriberID,
    SubscriberName,
    dbo.fn_ValidityDaysLeft(SubscriberID) AS DaysLeft
FROM Subscribers;
GO

-- 3. TABLE-VALUED FUNCTION:
-- LAST FIVE RECHARGES

CREATE OR ALTER FUNCTION dbo.fn_LastFiveRecharges
(
    @SubscriberID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP 5
        RechargeID,
        SubscriberID,
        RechargeAmount,
        RechargeDate,
        PlanID
    FROM Recharges
    WHERE SubscriberID = @SubscriberID
    ORDER BY RechargeDate DESC,RechargeID DESC
);
GO

-- TEST TABLE-VALUED FUNCTION

SELECT *
FROM dbo.fn_LastFiveRecharges(101);
GO
