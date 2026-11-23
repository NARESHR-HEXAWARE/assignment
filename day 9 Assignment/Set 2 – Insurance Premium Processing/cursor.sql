

USE InsuranceDB;
GO

-- 1. CURSOR-BASED PROCEDURE

CREATE OR ALTER PROCEDURE usp_CursorLapsePolicies
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PolicyID INT;
    DECLARE @OldStatus VARCHAR(30);

    DECLARE policy_cursor CURSOR LOCAL FAST_FORWARD
    FOR
        SELECT PolicyID,Status
        FROM Policies
        WHERE Status = 'Active'
          AND RenewalDate < CAST(GETDATE() AS DATE);

    OPEN policy_cursor;

    FETCH NEXT FROM policy_cursor
    INTO @PolicyID,@OldStatus;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        UPDATE Policies
        SET Status = 'Lapsed'
        WHERE PolicyID = @PolicyID;

        INSERT INTO PolicyLapseLog
        (
            PolicyID,
            PreviousStatus,
            NewStatus,
            LogDate
        )
        VALUES
        (
            @PolicyID,
            @OldStatus,
            'Lapsed',
            GETDATE()
        );

        FETCH NEXT FROM policy_cursor
        INTO @PolicyID,@OldStatus;
    END;

    CLOSE policy_cursor;
    DEALLOCATE policy_cursor;
END;
GO

-- EXECUTE CURSOR

EXEC usp_CursorLapsePolicies;
GO

-- 2. SET-BASED IMPLEMENTATION

BEGIN TRANSACTION;

UPDATE Policies
SET Status = 'Lapsed'
OUTPUT
    inserted.PolicyID,
    deleted.Status,
    inserted.Status,
    GETDATE()
INTO PolicyLapseLog
(
    PolicyID,
    PreviousStatus,
    NewStatus,
    LogDate
)
WHERE Status = 'Active'
  AND RenewalDate < CAST(GETDATE() AS DATE);

COMMIT TRANSACTION;
GO

-- 3. DISPLAY RESULTS

SELECT * FROM Policies;

SELECT * FROM PolicyLapseLog;
GO
