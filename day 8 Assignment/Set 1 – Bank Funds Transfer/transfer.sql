CREATE DATABASE BankDB;
GO

USE BankDB;
GO

CREATE TABLE Accounts (
    AccountID INT PRIMARY KEY,
    AccountHolder VARCHAR(50),
    Balance DECIMAL(12,2),
    Status VARCHAR(20)
);

INSERT INTO Accounts VALUES
(101, 'Arun', 10000, 'ACTIVE'),
(102, 'Bala', 5000, 'ACTIVE'),
(103, 'Charan', 3000, 'INACTIVE');

-- Transfer with COMMIT
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE Accounts
    SET Balance = Balance - 2000
    WHERE AccountID = 101
      AND Status = 'ACTIVE'
      AND Balance >= 2000;

    IF @@ROWCOUNT = 0
        THROW 50001, 'Insufficient balance or invalid sender', 1;

    UPDATE Accounts
    SET Balance = Balance + 2000
    WHERE AccountID = 102
      AND Status = 'ACTIVE';

    IF @@ROWCOUNT = 0
        THROW 50002, 'Invalid receiver account', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
END CATCH;

SELECT * FROM Accounts;

-- Rollback evidence: deliberate failure
SELECT * FROM Accounts;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE Accounts
    SET Balance = Balance - 1000
    WHERE AccountID = 101;

    THROW 50003, 'Deliberate transaction failure', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'Transaction rolled back';
    PRINT ERROR_MESSAGE();
END CATCH;

-- Verify balances remain unchanged
SELECT * FROM Accounts;

-- Savepoint example
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE Accounts
    SET Balance = Balance - 500
    WHERE AccountID = 101;

    UPDATE Accounts
    SET Balance = Balance + 500
    WHERE AccountID = 102;

    SAVE TRANSACTION FeeSavepoint;

    BEGIN TRY
        UPDATE Accounts
        SET Balance = Balance - 100
        WHERE AccountID = 101;

        THROW 50004, 'Fee posting failed', 1;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION FeeSavepoint;
        PRINT 'Fee operation rolled back';
    END CATCH;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
END CATCH;

SELECT * FROM Accounts;