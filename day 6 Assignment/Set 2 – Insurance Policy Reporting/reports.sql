/*
INSURANCE POLICY ADMINISTRATION – MANAGEMENT REPORTS
SQL Server 2019+ | Run this complete script in SSMS.
This self-contained demonstration uses a separate database and RECREATES its sample
objects on each run. All monetary amounts are illustrative, not real customer data.
Date-dependent reports use the server's current date (GETDATE()).

OUTPUT GUIDE:
R1: Expiring policies: PolicyNumberMasked, CustomerName, ProductName,
    ExpiryDate, DaysToExpiry, AgentName.
R2: ProductName, PremiumCollected, PaymentCount (paid transactions only).
R3: CustomerID, CustomerName, ActivePolicyCount, ActivePolicyNumbers.
R4: ProductName, PaidPremium, SettledClaims, ClaimRatioPercent.
    Claim ratio = settled claim amounts / paid premiums * 100 (not claim count).
R5: PolicyID, PolicyNumberMasked, CustomerName, ProductName.
R6: AgeBand, AveragePaidPremiumPerPolicy, PoliciesWithPayments.
R7: PolicyMonth, NewPolicies.
R8: AgentName, TotalPremiumCollected, PaymentCount.
R9: PolicyAgeBand, PolicyNumberMasked, CustomerName, DaysSinceStart (functions demo).

WHERE VS HAVING: In R3, WHERE filters individual policy rows to Active
before grouping; HAVING filters grouped customers to COUNT(*) > 1.
*/
SET NOCOUNT ON;
GO
IF DB_ID(N'InsuranceManagementReportsDB') IS NULL
    CREATE DATABASE InsuranceManagementReportsDB;
GO
USE InsuranceManagementReportsDB;
GO
-- Remove only this demonstration's tables, in dependency order.
DROP TABLE IF EXISTS dbo.Claims;
DROP TABLE IF EXISTS dbo.PremiumPayments;
DROP TABLE IF EXISTS dbo.Policies;
DROP TABLE IF EXISTS dbo.Agents;
DROP TABLE IF EXISTS dbo.Products;
DROP TABLE IF EXISTS dbo.Customers;
GO
CREATE TABLE dbo.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(60) NOT NULL,
    LastName NVARCHAR(60) NOT NULL,
    DateOfBirth DATE NOT NULL
);
CREATE TABLE dbo.Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(80) NOT NULL UNIQUE
);
CREATE TABLE dbo.Agents (
    AgentID INT IDENTITY(1,1) PRIMARY KEY,
    AgentName NVARCHAR(100) NOT NULL
);
CREATE TABLE dbo.Policies (
    PolicyID INT IDENTITY(1,1) PRIMARY KEY,
    PolicyNumber VARCHAR(25) NOT NULL UNIQUE,
    CustomerID INT NOT NULL REFERENCES dbo.Customers(CustomerID),
    ProductID INT NOT NULL REFERENCES dbo.Products(ProductID),
    AgentID INT NOT NULL REFERENCES dbo.Agents(AgentID),
    StartDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL,
    Status VARCHAR(15) NOT NULL CHECK (Status IN ('Active','Expired','Cancelled')),
    CONSTRAINT CK_PolicyDates CHECK (ExpiryDate > StartDate)
);
CREATE TABLE dbo.PremiumPayments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    PolicyID INT NOT NULL REFERENCES dbo.Policies(PolicyID),
    PaymentDate DATE NOT NULL,
    Amount DECIMAL(12,2) NOT NULL CHECK (Amount > 0),
    PaymentStatus VARCHAR(15) NOT NULL CHECK (PaymentStatus IN ('Paid','Pending','Failed'))
);
CREATE TABLE dbo.Claims (
    ClaimID INT IDENTITY(1,1) PRIMARY KEY,
    PolicyID INT NOT NULL REFERENCES dbo.Policies(PolicyID),
    ClaimDate DATE NOT NULL,
    ClaimedAmount DECIMAL(12,2) NOT NULL CHECK (ClaimedAmount >= 0),
    SettledAmount DECIMAL(12,2) NULL CHECK (SettledAmount >= 0),
    Status VARCHAR(15) NOT NULL CHECK (Status IN ('Submitted','UnderReview','Settled','Rejected')),
    CONSTRAINT CK_ClaimSettlement CHECK
       ((Status = 'Settled' AND SettledAmount IS NOT NULL) OR
        (Status <> 'Settled' AND SettledAmount IS NULL))
);
GO
INSERT INTO dbo.Customers(FirstName,LastName,DateOfBirth) VALUES
('Arun','Kumar','1994-05-03'),('Meera','Shah','1987-12-18'),
('Priya','Nair','2001-06-12'),('Rahul','Verma','1975-09-21'),
('Sana','Ali','1999-01-15'),('Karthik','Rao','1962-02-06'),
('Neha','Singh','1982-03-09'),('Dev','Patel','1990-10-28');
INSERT INTO dbo.Products(ProductName) VALUES
('Health'),('Motor'),('Life'),('Home'),('Travel');
INSERT INTO dbo.Agents(AgentName) VALUES
('Anika Bose'),('Vikram Das'),('Isha Menon'),('Kabir Jain'),('Riya Sen'),('Omar Khan');

DECLARE @Today DATE = CAST(GETDATE() AS DATE);
INSERT INTO dbo.Policies(PolicyNumber,CustomerID,ProductID,AgentID,StartDate,ExpiryDate,Status) VALUES
('POL-2026-0001',1,1,1,DATEADD(DAY,-200,@Today),DATEADD(DAY,10,@Today),'Active'),
('POL-2026-0002',1,2,2,DATEADD(DAY,-160,@Today),DATEADD(DAY,25,@Today),'Active'),
('POL-2026-0003',2,3,1,DATEADD(DAY,-90,@Today),DATEADD(DAY,270,@Today),'Active'),
('POL-2026-0004',2,4,3,DATEADD(DAY,-45,@Today),DATEADD(DAY,320,@Today),'Active'),
('POL-2026-0005',3,5,4,DATEADD(DAY,-15,@Today),DATEADD(DAY,15,@Today),'Active'),
('POL-2026-0006',4,1,5,DATEADD(DAY,-380,@Today),DATEADD(DAY,-15,@Today),'Expired'),
('POL-2026-0007',5,2,2,DATEADD(DAY,-65,@Today),DATEADD(DAY,300,@Today),'Active'),
('POL-2026-0008',6,3,3,DATEADD(DAY,-120,@Today),DATEADD(DAY,240,@Today),'Active'),
('POL-2026-0009',7,4,4,DATEADD(DAY,-12,@Today),DATEADD(DAY,350,@Today),'Active'),
('POL-2026-0010',8,5,6,DATEADD(DAY,-8,@Today),DATEADD(DAY,22,@Today),'Active'),
('POL-2026-0011',3,1,5,DATEADD(DAY,-3,@Today),DATEADD(DAY,362,@Today),'Active'),
('POL-2026-0012',5,4,1,DATEADD(DAY,-240,@Today),DATEADD(DAY,125,@Today),'Cancelled');

INSERT INTO dbo.PremiumPayments(PolicyID,PaymentDate,Amount,PaymentStatus) VALUES
(1,DATEADD(DAY,-195,@Today),10000,'Paid'),
(2,DATEADD(DAY,-150,@Today),6000,'Paid'),
(3,DATEADD(DAY,-85,@Today),15000,'Paid'),
(4,DATEADD(DAY,-40,@Today),8500,'Paid'),
(5,DATEADD(DAY,-12,@Today),2500,'Paid'),
(6,DATEADD(DAY,-370,@Today),9000,'Paid'),
(7,DATEADD(DAY,-60,@Today),7000,'Paid'),
(8,DATEADD(DAY,-110,@Today),18000,'Paid'),
(9,DATEADD(DAY,-9,@Today),8000,'Paid'),
(10,DATEADD(DAY,-5,@Today),3000,'Paid'),
(11,DATEADD(DAY,-1,@Today),11000,'Paid'),
(12,DATEADD(DAY,-235,@Today),7500,'Paid'),
(1,DATEADD(DAY,-4,@Today),1000,'Paid'),
(7,DATEADD(DAY,-2,@Today),700,'Pending'),
(10,DATEADD(DAY,-2,@Today),400,'Failed');

INSERT INTO dbo.Claims(PolicyID,ClaimDate,ClaimedAmount,SettledAmount,Status) VALUES
(1,DATEADD(DAY,-40,@Today),5000,4200,'Settled'),
(2,DATEADD(DAY,-55,@Today),3000,2500,'Settled'),
(3,DATEADD(DAY,-25,@Today),10000,NULL,'UnderReview'),
(6,DATEADD(DAY,-90,@Today),6000,5000,'Settled'),
(7,DATEADD(DAY,-20,@Today),2000,NULL,'Submitted'),
(8,DATEADD(DAY,-75,@Today),9000,7000,'Settled'),
(9,DATEADD(DAY,-5,@Today),1800,NULL,'Rejected'),
(11,DATEADD(DAY,-1,@Today),1500,NULL,'Submitted');
GO

-- R1. Policies expiring in the next 30 days (including today).
SELECT p.PolicyID,
       CONCAT('***',RIGHT(p.PolicyNumber,4)) AS PolicyNumberMasked,
       CONCAT(c.FirstName,' ',c.LastName) AS CustomerName,
       pr.ProductName,p.ExpiryDate,
       DATEDIFF(DAY,CAST(GETDATE() AS DATE),p.ExpiryDate) AS DaysToExpiry,
       a.AgentName
FROM dbo.Policies p
JOIN dbo.Customers c ON c.CustomerID=p.CustomerID
JOIN dbo.Products pr ON pr.ProductID=p.ProductID
JOIN dbo.Agents a ON a.AgentID=p.AgentID
WHERE p.Status='Active'
  AND p.ExpiryDate >= CAST(GETDATE() AS DATE)
  AND p.ExpiryDate <= DATEADD(DAY,30,CAST(GETDATE() AS DATE))
ORDER BY p.ExpiryDate,p.PolicyID;
-- EXPECTED sample: POL endings 0001,0005,0010,0002; days 10,15,22,25.

-- R2. Premium collected per product (payments actually paid).
SELECT pr.ProductName,CAST(COALESCE(SUM(pay.Amount),0) AS DECIMAL(14,2)) AS PremiumCollected,
       COUNT(pay.PaymentID) AS PaymentCount
FROM dbo.Products pr
LEFT JOIN dbo.Policies p ON p.ProductID=pr.ProductID
LEFT JOIN dbo.PremiumPayments pay ON pay.PolicyID=p.PolicyID AND pay.PaymentStatus='Paid'
GROUP BY pr.ProductID,pr.ProductName
ORDER BY PremiumCollected DESC,pr.ProductName;
-- EXPECTED: Health 31000; Life 33000; Home 24000; Motor 13000; Travel 5500.

-- R3. Customers with more than one active policy: WHERE vs HAVING.
SELECT c.CustomerID,UPPER(CONCAT(c.FirstName,' ',c.LastName)) AS CustomerName,
       COUNT(*) AS ActivePolicyCount,
       STRING_AGG(p.PolicyNumber,', ') WITHIN GROUP (ORDER BY p.PolicyNumber) AS ActivePolicyNumbers
FROM dbo.Customers c
JOIN dbo.Policies p ON p.CustomerID=c.CustomerID
WHERE p.Status='Active' AND p.StartDate<=CAST(GETDATE() AS DATE)
  AND p.ExpiryDate>=CAST(GETDATE() AS DATE)
GROUP BY c.CustomerID,c.FirstName,c.LastName
HAVING COUNT(*)>1
ORDER BY ActivePolicyCount DESC,c.CustomerID;
-- EXPECTED: Arun Kumar (2), Meera Shah (2), Priya Nair (2).

-- R4. Claim ratio per product: settled claims / collected premiums.
-- Pre-aggregate payments and claims by policy to avoid multiplying rows.
WITH Paid AS (
 SELECT PolicyID,SUM(Amount) AS PaidAmount
 FROM dbo.PremiumPayments WHERE PaymentStatus='Paid' GROUP BY PolicyID
), Settled AS (
 SELECT PolicyID,SUM(SettledAmount) AS SettledAmount
 FROM dbo.Claims WHERE Status='Settled' GROUP BY PolicyID
)
SELECT pr.ProductName,
       CAST(SUM(COALESCE(pa.PaidAmount,0)) AS DECIMAL(14,2)) AS PaidPremium,
       CAST(SUM(COALESCE(s.SettledAmount,0)) AS DECIMAL(14,2)) AS SettledClaims,
       CAST(ROUND(100.0*SUM(COALESCE(s.SettledAmount,0)) /
                    NULLIF(SUM(COALESCE(pa.PaidAmount,0)),0),2) AS DECIMAL(8,2)) AS ClaimRatioPercent
FROM dbo.Products pr
LEFT JOIN dbo.Policies p ON p.ProductID=pr.ProductID
LEFT JOIN Paid pa ON pa.PolicyID=p.PolicyID
LEFT JOIN Settled s ON s.PolicyID=p.PolicyID
GROUP BY pr.ProductID,pr.ProductName
ORDER BY pr.ProductName;
-- EXPECTED: Health 29.68%; Motor 19.23%; Life 21.21%; Home 0%; Travel 0%.
-- A product with zero collected premium will have NULL ratio (undefined), not 0.

-- R5. Policies with no claims of any status.
SELECT p.PolicyID,CONCAT('***',RIGHT(p.PolicyNumber,4)) AS PolicyNumberMasked,
       CONCAT(c.FirstName,' ',c.LastName) AS CustomerName,pr.ProductName
FROM dbo.Policies p
JOIN dbo.Customers c ON c.CustomerID=p.CustomerID
JOIN dbo.Products pr ON pr.ProductID=p.ProductID
LEFT JOIN dbo.Claims cl ON cl.PolicyID=p.PolicyID
WHERE cl.ClaimID IS NULL
ORDER BY p.PolicyID;
-- EXPECTED: policy IDs 4,5,10,12.

-- R6. Average total paid premium per policy, grouped by customer age.
-- Age at report date; the birthday correction avoids DATEDIFF(YEAR) overcount.
WITH CustomerAges AS (
 SELECT c.CustomerID,
        DATEDIFF(YEAR,c.DateOfBirth,CAST(GETDATE() AS DATE))
        - CASE WHEN DATEADD(YEAR,DATEDIFF(YEAR,c.DateOfBirth,CAST(GETDATE() AS DATE)),c.DateOfBirth)
                     > CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END AS AgeYears
 FROM dbo.Customers c
), PolicyPaid AS (
 SELECT p.PolicyID,p.CustomerID,SUM(pay.Amount) AS TotalPaid
 FROM dbo.Policies p
 JOIN dbo.PremiumPayments pay ON pay.PolicyID=p.PolicyID AND pay.PaymentStatus='Paid'
 GROUP BY p.PolicyID,p.CustomerID
), Banded AS (
 SELECT pp.PolicyID,pp.TotalPaid,
        CASE WHEN ca.AgeYears<30 THEN 'Under 30'
             WHEN ca.AgeYears<45 THEN '30-44'
             WHEN ca.AgeYears<60 THEN '45-59' ELSE '60+' END AS AgeBand
 FROM PolicyPaid pp JOIN CustomerAges ca ON ca.CustomerID=pp.CustomerID
)
SELECT AgeBand,
       CAST(ROUND(AVG(CAST(TotalPaid AS DECIMAL(18,4))),2) AS DECIMAL(14,2)) AS AveragePaidPremiumPerPolicy,
       COUNT(*) AS PoliciesWithPayments
FROM Banded GROUP BY AgeBand
ORDER BY CASE AgeBand WHEN 'Under 30' THEN 1 WHEN '30-44' THEN 2 WHEN '45-59' THEN 3 ELSE 4 END;
-- EXPECTED: Age groups depend on today's date; averages are per policy, not per transaction.

-- R7. Monthly new policies, calendar month based on StartDate.
SELECT CONVERT(CHAR(7),p.StartDate,120) AS PolicyMonth,
       COUNT(*) AS NewPolicies
FROM dbo.Policies p
GROUP BY CONVERT(CHAR(7),p.StartDate,120)
ORDER BY PolicyMonth;
-- EXPECTED: One row per distinct YYYY-MM, with count of policies started that month.

-- R8. Top five agents by collected premium (tie broken by AgentID).
SELECT TOP (5) a.AgentID,a.AgentName,
       CAST(SUM(pay.Amount) AS DECIMAL(14,2)) AS TotalPremiumCollected,
       COUNT(pay.PaymentID) AS PaymentCount
FROM dbo.Agents a
JOIN dbo.Policies p ON p.AgentID=a.AgentID
JOIN dbo.PremiumPayments pay ON pay.PolicyID=p.PolicyID AND pay.PaymentStatus='Paid'
GROUP BY a.AgentID,a.AgentName
ORDER BY TotalPremiumCollected DESC,a.AgentID;
-- EXPECTED: Anika 33500, Isha 26500, Riya 20000, Vikram 13000, Kabir 10500.

-- R9. Supplementary age-band / masked-number report for required SQL functions.
-- "PolicyAgeBand" here means years since policy StartDate, not customer's age.
SELECT p.PolicyID,
       CONCAT(UPPER(LEFT(pr.ProductName,3)),'-',REPLICATE('X',LEN(p.PolicyNumber)-4),RIGHT(p.PolicyNumber,4)) AS PolicyNumberMasked,
       CONCAT(UPPER(c.LastName),', ',c.FirstName) AS CustomerName,
       DATEDIFF(DAY,p.StartDate,CAST(GETDATE() AS DATE)) AS DaysSinceStart,
       CASE WHEN p.StartDate>CAST(GETDATE() AS DATE) THEN 'Not started'
            WHEN p.StartDate>DATEADD(MONTH,-3,CAST(GETDATE() AS DATE)) THEN '0-3 months'
            WHEN p.StartDate>DATEADD(YEAR,-1,CAST(GETDATE() AS DATE)) THEN '3-12 months'
            ELSE 'Over 1 year' END AS PolicyAgeBand
FROM dbo.Policies p
JOIN dbo.Customers c ON c.CustomerID=p.CustomerID
JOIN dbo.Products pr ON pr.ProductID=p.ProductID
ORDER BY p.PolicyID;
-- NOTE: FORMAT can be used for display: FORMAT(p.ExpiryDate,'dd MMM yyyy').
-- It is intentionally omitted from date predicates for better index utilization.
GO
