

USE master;
GO

IF DB_ID('InsuranceDB') IS NULL
    CREATE DATABASE InsuranceDB;
GO

USE InsuranceDB;
GO

-- 1. CREATE TABLES

CREATE TABLE Customers
(
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100),
    Email VARCHAR(100),
    Phone VARCHAR(15),
    NationalID VARCHAR(30)
);
GO

CREATE TABLE Policies
(
    PolicyID INT PRIMARY KEY,
    CustomerID INT,
    AgentID INT,
    PremiumAmount DECIMAL(12,2),
    RenewalDate DATE,
    Status VARCHAR(30),
    CoverageAmount DECIMAL(12,2),

    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
GO

CREATE TABLE Claims
(
    ClaimID INT IDENTITY(1,1) PRIMARY KEY,
    PolicyID INT,
    ClaimStatus VARCHAR(30),

    FOREIGN KEY (PolicyID) REFERENCES Policies(PolicyID)
);
GO

CREATE TABLE PolicyAudit
(
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    PolicyID INT,
    OldPremium DECIMAL(12,2),
    NewPremium DECIMAL(12,2),
    ActionDate DATETIME,
    Remarks VARCHAR(200)
);
GO

CREATE TABLE PolicyRenewalAudit
(
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    PolicyID INT,
    ActionDate DATETIME,
    Remarks VARCHAR(200)
);
GO

CREATE TABLE PolicyLapseLog
(
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    PolicyID INT,
    PreviousStatus VARCHAR(30),
    NewStatus VARCHAR(30),
    LogDate DATETIME
);
GO

-- 2. INSERT SAMPLE DATA

INSERT INTO Customers
VALUES
(1,'Arun','arun@gmail.com','9876543210','ID101'),
(2,'Kumar','kumar@gmail.com','9876543211','ID102'),
(3,'Ravi','ravi@gmail.com','9876543212','ID103');
GO

INSERT INTO Policies
VALUES
(101,1,10,10000,DATEADD(DAY,10,GETDATE()),'Active',500000),
(102,2,10,15000,DATEADD(DAY,-5,GETDATE()),'Active',700000),
(103,3,20,20000,DATEADD(DAY,20,GETDATE()),'Active',900000);
GO

INSERT INTO Claims(PolicyID,ClaimStatus)
VALUES
(101,'Approved'),
(103,'Pending');
GO

-- 3. POLICY DUE VIEW

CREATE OR ALTER VIEW vw_policy_due
AS
SELECT
    p.PolicyID,
    c.CustomerID,
    c.CustomerName,
    c.Email,
    c.Phone,
    p.AgentID,
    p.PremiumAmount,
    p.RenewalDate,
    p.Status
FROM Policies p
JOIN Customers c
    ON p.CustomerID = c.CustomerID
WHERE p.RenewalDate >= CAST(GETDATE() AS DATE)
  AND p.RenewalDate < DATEADD(
      DAY,31,CAST(GETDATE() AS DATE)
  );
GO

-- TEST VIEW

SELECT * FROM vw_policy_due;
GO
