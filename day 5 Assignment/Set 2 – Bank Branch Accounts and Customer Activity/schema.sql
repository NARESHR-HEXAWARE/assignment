/* BANK BRANCH — schema.sql | SQL Server 2019+ | Run before seed_data.sql.
   Fresh demonstration database. Delete/recreate deliberately resets previous demo data. */
USE master;
GO
IF DB_ID(N'BankBranchAssignmentDB') IS NOT NULL
BEGIN
    ALTER DATABASE BankBranchAssignmentDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BankBranchAssignmentDB;
END;
GO
CREATE DATABASE BankBranchAssignmentDB;
GO
USE BankBranchAssignmentDB;
GO

/* 3NF / BCNF: each relation stores facts determined by its candidate key.
   Assumptions: email, employee code, branch code and account-type code are unique;
   one account is owned by one customer and managed by one relationship manager.
   Transactions are identified both by TransactionID and (AccountID, SequenceNo).
   Deletion policy: RESTRICT/NO ACTION for all financial parent relationships;
   deleting a customer/branch/manager cannot erase account/transaction history.
   ON UPDATE CASCADE for natural codes is unnecessary: FKs use immutable surrogate IDs.
*/
CREATE TABLE dbo.Branches (
    BranchID INT IDENTITY(1,1) CONSTRAINT PK_Branches PRIMARY KEY,
    BranchCode VARCHAR(12) NOT NULL CONSTRAINT UQ_Branches_Code UNIQUE,
    BranchName NVARCHAR(100) NOT NULL,
    City NVARCHAR(80) NOT NULL
);
GO
CREATE TABLE dbo.Customers (
    CustomerID INT IDENTITY(1,1) CONSTRAINT PK_Customers PRIMARY KEY,
    FullName NVARCHAR(120) NOT NULL,
    Email VARCHAR(150) NOT NULL CONSTRAINT UQ_Customers_Email UNIQUE,
    Phone VARCHAR(20) NULL,
    AddressLine NVARCHAR(200) NOT NULL,
    City NVARCHAR(80) NOT NULL
);
GO
CREATE TABLE dbo.AccountTypes (
    AccountTypeID INT IDENTITY(1,1) CONSTRAINT PK_AccountTypes PRIMARY KEY,
    TypeCode VARCHAR(12) NOT NULL CONSTRAINT UQ_AccountTypes_Code UNIQUE,
    TypeName NVARCHAR(60) NOT NULL CONSTRAINT UQ_AccountTypes_Name UNIQUE
);
GO
CREATE TABLE dbo.RelationshipManagers (
    ManagerID INT IDENTITY(1,1) CONSTRAINT PK_Managers PRIMARY KEY,
    EmployeeCode VARCHAR(16) NOT NULL CONSTRAINT UQ_Managers_EmployeeCode UNIQUE,
    ManagerName NVARCHAR(120) NOT NULL,
    BranchID INT NOT NULL,
    CONSTRAINT FK_Managers_Branches FOREIGN KEY (BranchID)
        REFERENCES dbo.Branches(BranchID) ON DELETE NO ACTION,
    CONSTRAINT UQ_Managers_ManagerBranch UNIQUE (ManagerID, BranchID)
);
GO
CREATE TABLE dbo.Accounts (
    AccountID INT IDENTITY(1,1) CONSTRAINT PK_Accounts PRIMARY KEY,
    AccountNumber VARCHAR(20) NOT NULL CONSTRAINT UQ_Accounts_Number UNIQUE,
    CustomerID INT NOT NULL,
    AccountTypeID INT NOT NULL,
    BranchID INT NOT NULL,
    ManagerID INT NOT NULL,
    Balance DECIMAL(18,2) NOT NULL CONSTRAINT DF_Accounts_Balance DEFAULT (0),
    OpenedDate DATE NOT NULL CONSTRAINT DF_Accounts_Opened DEFAULT (CONVERT(DATE,GETDATE())),
    AccountStatus VARCHAR(12) NOT NULL CONSTRAINT DF_Accounts_Status DEFAULT ('ACTIVE'),
    CONSTRAINT CK_Accounts_Status CHECK (AccountStatus IN ('ACTIVE','DORMANT','CLOSED')),
    /* Savings type is TypeCode SAV; the demonstration reserves AccountTypeID=1 for SAV.
       Stronger schema design: place MinBalanceAllowed in AccountTypes and enforce by
       trigger, or use an explicit stable AccountCategory column. Here we use an
       account-level SavingsFlag, checked against the chosen type by a trigger below. */
    SavingsFlag BIT NOT NULL,
    CONSTRAINT CK_Accounts_SavingsBalance CHECK (SavingsFlag = 0 OR Balance >= 0),
    CONSTRAINT FK_Accounts_Customers FOREIGN KEY (CustomerID)
        REFERENCES dbo.Customers(CustomerID) ON DELETE NO ACTION,
    CONSTRAINT FK_Accounts_Types FOREIGN KEY (AccountTypeID)
        REFERENCES dbo.AccountTypes(AccountTypeID) ON DELETE NO ACTION,
    CONSTRAINT FK_Accounts_Branches FOREIGN KEY (BranchID)
        REFERENCES dbo.Branches(BranchID) ON DELETE NO ACTION,
    CONSTRAINT FK_Accounts_ManagerBranch FOREIGN KEY (ManagerID, BranchID)
        REFERENCES dbo.RelationshipManagers(ManagerID, BranchID) ON DELETE NO ACTION
);
GO
/* Prevent mismatched SavingsFlag and account type; 'SAV' is a business code. */
CREATE TRIGGER dbo.TR_Accounts_ValidateSavingsFlag
ON dbo.Accounts AFTER INSERT, UPDATE AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (
      SELECT 1 FROM inserted AS i
      JOIN dbo.AccountTypes AS t ON t.AccountTypeID = i.AccountTypeID
      WHERE i.SavingsFlag <> (CASE WHEN t.TypeCode='SAV' THEN 1 ELSE 0 END)
  )
      THROW 51001, 'SavingsFlag must match SAV account type.', 1;
END;
GO
CREATE TABLE dbo.AccountTransactions (
    TransactionID BIGINT IDENTITY(1,1) CONSTRAINT PK_Transactions PRIMARY KEY,
    AccountID INT NOT NULL,
    SequenceNo INT NOT NULL CONSTRAINT CK_Transactions_Sequence CHECK (SequenceNo > 0),
    TransactionAt DATETIME2(0) NOT NULL CONSTRAINT DF_Transactions_At DEFAULT (SYSDATETIME()),
    TransactionType VARCHAR(12) NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    Description NVARCHAR(250) NULL,
    CONSTRAINT CK_Transactions_Type CHECK (TransactionType IN ('DEPOSIT','WITHDRAWAL','TRANSFER')),
    CONSTRAINT CK_Transactions_Amount CHECK (Amount > 0),
    CONSTRAINT UQ_Transactions_AccountSequence UNIQUE (AccountID, SequenceNo),
    CONSTRAINT FK_Transactions_Accounts FOREIGN KEY (AccountID)
        REFERENCES dbo.Accounts(AccountID) ON DELETE NO ACTION
);
GO
CREATE INDEX IX_Accounts_OpenedBalance ON dbo.Accounts(OpenedDate, Balance);
CREATE INDEX IX_Transactions_AccountAt ON dbo.AccountTransactions(AccountID, TransactionAt DESC);
GO
/* Candidate keys: Branches {BranchID}, {BranchCode}; Customers {CustomerID}, {Email};
   AccountTypes {AccountTypeID}, {TypeCode}, {TypeName}; Managers {ManagerID},
   {EmployeeCode}; Accounts {AccountID}, {AccountNumber}; Transactions
   {TransactionID}, {AccountID, SequenceNo} (composite candidate key).
   (ManagerID, BranchID) is a UNIQUE superkey for branch-consistent FK,
   NOT a minimal candidate key, since ManagerID alone is already unique. */
