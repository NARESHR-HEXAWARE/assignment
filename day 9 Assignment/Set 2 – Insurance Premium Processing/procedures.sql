

USE InsuranceDB;
GO

-- 1. STORED PROCEDURE: RENEW POLICY

CREATE OR ALTER PROCEDURE usp_RenewPolicy
    @PolicyID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldPremium DECIMAL(12,2);
    DECLARE @NewPremium DECIMAL(12,2);
    DECLARE @Status VARCHAR(30);

    BEGIN TRY

        BEGIN TRANSACTION;

        -- Validate and lock policy

        SELECT
            @OldPremium = PremiumAmount,
            @Status = Status
        FROM Policies WITH (UPDLOCK,HOLDLOCK)
        WHERE PolicyID = @PolicyID;

        IF @Status IS NULL
            THROW 50001,'Policy not found',1;

        IF @Status <> 'Active'
            THROW 50002,'Policy is not active',1;

        -- Check pending claims

        IF EXISTS
        (
            SELECT 1
            FROM Claims
            WHERE PolicyID = @PolicyID
              AND ClaimStatus = 'Pending'
        )
            THROW 50003,'Pending claim exists',1;

        -- Recalculate premium
        -- Example: 10% increase

        SET @NewPremium = @OldPremium * 1.10;

        -- Update policy

        UPDATE Policies
        SET
            PremiumAmount = @NewPremium,
            RenewalDate = DATEADD(YEAR,1,RenewalDate)
        WHERE PolicyID = @PolicyID;

        -- Insert premium audit

        INSERT INTO PolicyAudit
        (
            PolicyID,
            OldPremium,
            NewPremium,
            ActionDate,
            Remarks
        )
        VALUES
        (
            @PolicyID,
            @OldPremium,
            @NewPremium,
            GETDATE(),
            'Premium recalculated and policy renewed'
        );

        -- Insert renewal audit

        INSERT INTO PolicyRenewalAudit
        (
            PolicyID,
            ActionDate,
            Remarks
        )
        VALUES
        (
            @PolicyID,
            GETDATE(),
            'Policy renewal completed'
        );

        COMMIT TRANSACTION;

        SELECT @NewPremium AS RenewedPremium;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
GO

-- TEST PROCEDURE
-- Policy 101 has no pending claim.

EXEC usp_RenewPolicy @PolicyID = 101;
GO

-- 2. SCALAR FUNCTION: NO CLAIM DISCOUNT

CREATE OR ALTER FUNCTION dbo.fn_PremiumWithNoClaimDiscount
(
    @Premium DECIMAL(12,2),
    @NoClaim BIT
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @FinalPremium DECIMAL(12,2);

    IF @NoClaim = 1
        SET @FinalPremium = @Premium * 0.90;
    ELSE
        SET @FinalPremium = @Premium;

    RETURN @FinalPremium;
END;
GO

-- TEST SCALAR FUNCTION

SELECT
    PolicyID,
    PremiumAmount,
    dbo.fn_PremiumWithNoClaimDiscount(
        PremiumAmount,1
    ) AS DiscountedPremium
FROM Policies;
GO

-- 3. TABLE-VALUED FUNCTION: AGENT QUOTES

CREATE OR ALTER FUNCTION dbo.fn_AgentRenewalQuotes
(
    @AgentID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        PolicyID,
        CustomerID,
        AgentID,
        PremiumAmount AS CurrentPremium,
        PremiumAmount * 1.10 AS RenewalQuote,
        RenewalDate
    FROM Policies
    WHERE AgentID = @AgentID
      AND Status = 'Active'
);
GO

-- TEST TABLE-VALUED FUNCTION

SELECT *
FROM dbo.fn_AgentRenewalQuotes(10);
GO
