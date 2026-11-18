/* BANK BRANCH — seed_data.sql | Run AFTER schema.sql. */
USE BankBranchAssignmentDB;
GO
SET NOCOUNT ON;

INSERT dbo.Branches (BranchCode,BranchName,City) VALUES
('CHN01',N'Anna Nagar',N'Chennai'),('CHN02',N'Adyar',N'Chennai'),
('BLR01',N'Indiranagar',N'Bengaluru');
INSERT dbo.AccountTypes(TypeCode,TypeName) VALUES
('SAV',N'Savings'),('CUR',N'Current'),('SAL',N'Salary');
INSERT dbo.Customers(FullName,Email,Phone,AddressLine,City) VALUES
(N'Ananya Rao','ananya@example.test','9000000001',N'12 Lake Road',N'Chennai'),
(N'Vikram Iyer','vikram@example.test','9000000002',N'88 Park Street',N'Chennai'),
(N'Meera Nair','meera@example.test','9000000003',N'4 School Road',N'Chennai'),
(N'Arjun Kumar','arjun@example.test','9000000004',N'19 Temple Lane',N'Chennai'),
(N'Sara Thomas','sara@example.test','9000000005',N'5 Market Street',N'Bengaluru'),
(N'Rahul Das','rahul@example.test','9000000006',N'72 Station Road',N'Bengaluru'),
(N'Priya Menon','priya@example.test','9000000007',N'13 North Avenue',N'Chennai'),
(N'Kiran Shah','kiran@example.test','9000000008',N'22 South Street',N'Chennai'),
(N'Neha Jain','neha@example.test','9000000009',N'45 River Road',N'Bengaluru'),
(N'Rohan Sen','rohan@example.test','9000000010',N'8 Green Lane',N'Bengaluru'),
(N'Diya Bose','diya@example.test','9000000011',N'17 Central Road',N'Chennai'),
(N'Farhan Ali','farhan@example.test','9000000012',N'63 Hill Street',N'Chennai');
INSERT dbo.RelationshipManagers(EmployeeCode,ManagerName,BranchID) VALUES
('RM101',N'Lakshmi Krishnan',1),('RM102',N'Dev Patel',1),
('RM201',N'Ritu Kapoor',2),('RM301',N'Harish N',3);

/* Date range is PREVIOUS COMPLETED CALENDAR QUARTER, not last 90 days. */
DECLARE @ThisQuarterStart DATE = DATEADD(QUARTER,DATEDIFF(QUARTER,0,GETDATE()),0);
DECLARE @PrevQuarterStart DATE = DATEADD(QUARTER,-1,@ThisQuarterStart);
INSERT dbo.Accounts(AccountNumber,CustomerID,AccountTypeID,BranchID,ManagerID,Balance,OpenedDate,AccountStatus,SavingsFlag) VALUES
('AC100001',1,1,1,1,25000,DATEADD(DAY,5,@PrevQuarterStart),'ACTIVE',1),
('AC100002',2,1,1,2,4000,DATEADD(DAY,12,@PrevQuarterStart),'ACTIVE',1),
('AC100003',3,2,2,3,120000,DATEADD(DAY,20,@PrevQuarterStart),'ACTIVE',0),
('AC100004',4,1,2,3,80000,DATEADD(DAY,28,@PrevQuarterStart),'ACTIVE',1),
('AC100005',5,3,3,4,45000,DATEADD(DAY,39,@PrevQuarterStart),'ACTIVE',0),
('AC100006',6,1,3,4,1000,DATEADD(DAY,48,@PrevQuarterStart),'DORMANT',1),
('AC100007',7,1,1,1,55000,DATEADD(DAY,61,@PrevQuarterStart),'ACTIVE',1),
('AC100008',8,2,1,2,15000,DATEADD(DAY,75,@PrevQuarterStart),'ACTIVE',0),
('AC100009',9,1,3,4,9000,DATEADD(DAY,-15,@PrevQuarterStart),'ACTIVE',1),
('AC100010',10,1,3,4,67000,DATEADD(DAY,-35,@PrevQuarterStart),'ACTIVE',1),
('AC100011',11,3,2,3,31000,@ThisQuarterStart,'ACTIVE',0),
('AC100012',12,1,2,3,60000,DATEADD(DAY,2,@ThisQuarterStart),'ACTIVE',1);
INSERT dbo.AccountTransactions(AccountID,SequenceNo,TransactionAt,TransactionType,Amount,Description) VALUES
(1,1,DATEADD(DAY,-6,SYSDATETIME()),'DEPOSIT',1500,N'ATM cash deposit'),
(1,2,DATEADD(DAY,-2,SYSDATETIME()),'WITHDRAWAL',300,N'ATM withdrawal'),
(2,1,DATEADD(DAY,-3,SYSDATETIME()),'DEPOSIT',1000,N'Cash deposit'),
(3,1,DATEADD(DAY,-5,SYSDATETIME()),'TRANSFER',2500,N'Bill payment'),
(4,1,DATEADD(DAY,-5,SYSDATETIME()),'DEPOSIT',5000,N'Cheque deposit'),
(5,1,DATEADD(DAY,-4,SYSDATETIME()),'DEPOSIT',1200,N'Payroll'),
(6,1,DATEADD(DAY,-9,SYSDATETIME()),'WITHDRAWAL',200,N'Cash withdrawal'),
(7,1,DATEADD(DAY,-4,SYSDATETIME()),'TRANSFER',1200,N'Online transfer'),
(7,2,DATEADD(DAY,-1,SYSDATETIME()),'DEPOSIT',1800,N'Cash deposit'),
(8,1,DATEADD(DAY,-8,SYSDATETIME()),'DEPOSIT',3000,N'Business receipt'),
(9,1,DATEADD(DAY,-7,SYSDATETIME()),'WITHDRAWAL',500,N'Bill payment'),
(10,1,DATEADD(DAY,-6,SYSDATETIME()),'DEPOSIT',4000,N'Cash deposit'),
(11,1,DATEADD(DAY,-2,SYSDATETIME()),'DEPOSIT',2200,N'Payroll'),
(12,1,DATEADD(DAY,-1,SYSDATETIME()),'TRANSFER',1000,N'Online transfer');

/* Task 4: INSERT/UPDATE/DELETE, before-and-after SELECT */
SELECT 'Before update' AS Stage,AccountNumber,Balance,AccountStatus FROM dbo.Accounts WHERE AccountNumber='AC100002';
UPDATE dbo.Accounts SET Balance=6500,AccountStatus='ACTIVE' WHERE AccountNumber='AC100002';
SELECT 'After update' AS Stage,AccountNumber,Balance,AccountStatus FROM dbo.Accounts WHERE AccountNumber='AC100002';

/* Disposable record; deleting a customer with accounts would be disallowed. */
INSERT dbo.Customers(FullName,Email,AddressLine,City)
VALUES (N'Temporary Test Customer','temporary@example.test',N'1 Demo Street',N'Chennai');
SELECT 'Before delete' AS Stage,CustomerID,FullName FROM dbo.Customers WHERE Email='temporary@example.test';
DELETE dbo.Customers WHERE Email='temporary@example.test';
SELECT 'After delete (zero rows)' AS Stage,CustomerID,FullName FROM dbo.Customers WHERE Email='temporary@example.test';

DECLARE @ThisQ DATE = DATEADD(QUARTER,DATEDIFF(QUARTER,0,GETDATE()),0);
DECLARE @PrevQ DATE = DATEADD(QUARTER,-1,@ThisQ);
DECLARE @BalanceThreshold DECIMAL(18,2) = 20000;
/* AND + BETWEEN: the last complete calendar quarter, dates inclusive. */
SELECT a.AccountNumber,c.FullName,t.TypeName,a.Balance,a.OpenedDate
FROM dbo.Accounts a JOIN dbo.Customers c ON c.CustomerID=a.CustomerID
JOIN dbo.AccountTypes t ON t.AccountTypeID=a.AccountTypeID
WHERE a.OpenedDate BETWEEN @PrevQ AND DATEADD(DAY,-1,@ThisQ)
  AND a.Balance > @BalanceThreshold
ORDER BY a.OpenedDate;
/* OR + IN + AND: filter on branch or type; parentheses prevent precedence errors. */
SELECT AccountNumber,BranchID,AccountTypeID,Balance FROM dbo.Accounts
WHERE (BranchID IN (1,2) OR AccountTypeID IN (1,3)) AND Balance >= 30000
ORDER BY AccountNumber;

/* Task 3: each DDL/DML identity demo uses its OWN disposable table.
   SQL Server: DELETE preserves identity counter; TRUNCATE reseeds; DROP removes
   object entirely. All three are transactional inside an explicit transaction.
   SELECT rows after test INSERTS to observe identity values. */
IF OBJECT_ID('dbo.DemoDelete','U') IS NOT NULL DROP TABLE dbo.DemoDelete;
CREATE TABLE dbo.DemoDelete(ID INT IDENTITY(1,1) PRIMARY KEY,Note VARCHAR(30));
INSERT dbo.DemoDelete(Note) VALUES ('first'),('second');
BEGIN TRAN;
    DELETE FROM dbo.DemoDelete;
    SELECT 'DELETE inside transaction' AS Demo,COUNT(*) AS RowCount FROM dbo.DemoDelete;
ROLLBACK;
SELECT 'DELETE rollback restores rows' AS Demo,COUNT(*) AS RowCount FROM dbo.DemoDelete;
DELETE FROM dbo.DemoDelete;
INSERT dbo.DemoDelete(Note) VALUES ('after DELETE');
SELECT 'DELETE next ID is 3' AS Demo,ID,Note FROM dbo.DemoDelete;

IF OBJECT_ID('dbo.DemoTruncate','U') IS NOT NULL DROP TABLE dbo.DemoTruncate;
CREATE TABLE dbo.DemoTruncate(ID INT IDENTITY(1,1) PRIMARY KEY,Note VARCHAR(30));
INSERT dbo.DemoTruncate(Note) VALUES ('first'),('second');
BEGIN TRAN;
    TRUNCATE TABLE dbo.DemoTruncate;
    SELECT 'TRUNCATE inside transaction' AS Demo,COUNT(*) AS RowCount FROM dbo.DemoTruncate;
ROLLBACK;
SELECT 'TRUNCATE rollback restores rows' AS Demo,COUNT(*) AS RowCount FROM dbo.DemoTruncate;
TRUNCATE TABLE dbo.DemoTruncate;
INSERT dbo.DemoTruncate(Note) VALUES ('after TRUNCATE');
SELECT 'TRUNCATE next ID is 1' AS Demo,ID,Note FROM dbo.DemoTruncate;

IF OBJECT_ID('dbo.DemoDrop','U') IS NOT NULL DROP TABLE dbo.DemoDrop;
CREATE TABLE dbo.DemoDrop(ID INT IDENTITY(1,1) PRIMARY KEY,Note VARCHAR(30));
INSERT dbo.DemoDrop(Note) VALUES ('first'),('second');
BEGIN TRAN;
    DROP TABLE dbo.DemoDrop;
    SELECT 'DROP inside transaction (table absent)' AS Demo,OBJECT_ID('dbo.DemoDrop','U') AS TableObjectID;
ROLLBACK;
SELECT 'DROP rollback restores table' AS Demo,COUNT(*) AS RowCount FROM dbo.DemoDrop;
DROP TABLE dbo.DemoDrop;
SELECT 'DROP committed (table absent)' AS Demo,OBJECT_ID('dbo.DemoDrop','U') AS TableObjectID;
/* Recreate is a NEW identity sequence, starts at 1. */
CREATE TABLE dbo.DemoDrop(ID INT IDENTITY(1,1) PRIMARY KEY,Note VARCHAR(30));
INSERT dbo.DemoDrop(Note) VALUES ('new object');
SELECT 'Recreated DROP table starts at 1' AS Demo,ID,Note FROM dbo.DemoDrop;
DROP TABLE dbo.DemoDelete,dbo.DemoTruncate,dbo.DemoDrop;
GO
