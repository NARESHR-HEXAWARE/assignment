

USE master;
GO

IF DB_ID('TelecomDB') IS NULL
    CREATE DATABASE TelecomDB;
GO

USE TelecomDB;
GO

-- 1. CREATE TABLES

CREATE TABLE Plans
(
    PlanID INT PRIMARY KEY,
    PlanName VARCHAR(100),
    PlanAmount DECIMAL(10,2),
    ValidityDays INT
);
GO

CREATE TABLE Subscribers
(
    SubscriberID INT PRIMARY KEY,
    SubscriberName VARCHAR(100),
    PhoneNumber VARCHAR(15),
    SubscriberType VARCHAR(20),
    Balance DECIMAL(12,2) NOT NULL,
    PlanID INT,
    ValidityEndDate DATE,

    FOREIGN KEY (PlanID) REFERENCES Plans(PlanID)
);
GO

CREATE TABLE Recharges
(
    RechargeID INT IDENTITY(1,1) PRIMARY KEY,
    SubscriberID INT,
    RechargeAmount DECIMAL(12,2),
    RechargeDate DATETIME DEFAULT GETDATE(),
    PlanID INT,

    FOREIGN KEY (SubscriberID)
        REFERENCES Subscribers(SubscriberID),

    FOREIGN KEY (PlanID)
        REFERENCES Plans(PlanID)
);
GO

CREATE TABLE NotificationLog
(
    NotificationID INT IDENTITY(1,1) PRIMARY KEY,
    SubscriberID INT,
    Message VARCHAR(200),
    IsRead BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (SubscriberID)
        REFERENCES Subscribers(SubscriberID)
);
GO

-- 2. INSERT SAMPLE DATA

INSERT INTO Plans
VALUES
(1,'Basic Plan',99,28),
(2,'Standard Plan',199,56),
(3,'Premium Plan',299,84);
GO

INSERT INTO Subscribers
VALUES
(101,'Arun','9876543210','Prepaid',30,1,
 DATEADD(DAY,10,GETDATE())),

(102,'Kumar','9876543211','Prepaid',100,2,
 DATEADD(DAY,30,GETDATE())),

(103,'Ravi','9876543212','Prepaid',20,1,
 DATEADD(DAY,5,GETDATE())),

(104,'Suresh','9876543213','Postpaid',500,3,
 DATEADD(DAY,60,GETDATE()));
GO

INSERT INTO Recharges
(SubscriberID,RechargeAmount,RechargeDate,PlanID)
VALUES
(101,99,DATEADD(DAY,-10,GETDATE()),1),
(101,199,DATEADD(DAY,-5,GETDATE()),2),
(102,199,GETDATE(),2),
(103,99,DATEADD(DAY,-15,GETDATE()),1),
(103,99,DATEADD(DAY,-3,GETDATE()),1);
GO

-- 3. PREPAID SUBSCRIBERS VIEW

CREATE OR ALTER VIEW vw_prepaid_subscribers
AS
SELECT
    SubscriberID,
    SubscriberName,
    PhoneNumber,
    Balance,
    PlanID,
    ValidityEndDate
FROM Subscribers
WHERE SubscriberType = 'Prepaid';
GO

-- 4. RECHARGE SUMMARY VIEW

CREATE OR ALTER VIEW vw_recharge_summary
AS
SELECT
    s.SubscriberID,
    s.SubscriberName,
    COUNT(r.RechargeID) AS TotalRecharges,
    ISNULL(SUM(r.RechargeAmount),0) AS TotalAmount,
    MAX(r.RechargeDate) AS LastRechargeDate
FROM Subscribers s
LEFT JOIN Recharges r
    ON s.SubscriberID = r.SubscriberID
GROUP BY
    s.SubscriberID,
    s.SubscriberName;
GO

-- 5. TEST VIEWS

SELECT * FROM vw_prepaid_subscribers;

SELECT * FROM vw_recharge_summary;
GO
