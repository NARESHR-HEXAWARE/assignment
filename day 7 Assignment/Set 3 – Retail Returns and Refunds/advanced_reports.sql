
SET NOCOUNT ON;
GO
-- Safe rerun: remove only objects created by this assignment.
DROP TABLE IF EXISTS dbo.RR_ReturnFeedback, dbo.RR_Refunds, dbo.RR_Returns,
                     dbo.RR_SaleItems, dbo.RR_Sales, dbo.RR_Employees,
                     dbo.RR_Products, dbo.RR_Customers, dbo.RR_Stores;
GO
CREATE TABLE dbo.RR_Stores (
 StoreID int PRIMARY KEY, StoreName nvarchar(60) NOT NULL,
 Region nvarchar(40) NOT NULL
);
CREATE TABLE dbo.RR_Customers (
 CustomerID int PRIMARY KEY, CustomerName nvarchar(80) NOT NULL
);
CREATE TABLE dbo.RR_Products (
 ProductID int PRIMARY KEY, ProductName nvarchar(80) NOT NULL
);
CREATE TABLE dbo.RR_Employees (
 EmployeeID int PRIMARY KEY, EmployeeName nvarchar(80) NOT NULL,
 StoreID int NOT NULL REFERENCES dbo.RR_Stores(StoreID),
 ManagerID int NULL REFERENCES dbo.RR_Employees(EmployeeID)
);
CREATE TABLE dbo.RR_Sales (
 SaleID int PRIMARY KEY, CustomerID int NOT NULL REFERENCES dbo.RR_Customers(CustomerID),
 StoreID int NOT NULL REFERENCES dbo.RR_Stores(StoreID), SaleDate date NOT NULL
);
CREATE TABLE dbo.RR_SaleItems (
 SaleItemID int PRIMARY KEY, SaleID int NOT NULL REFERENCES dbo.RR_Sales(SaleID),
 ProductID int NOT NULL REFERENCES dbo.RR_Products(ProductID),
 Quantity int NOT NULL CHECK (Quantity > 0),
 UnitPrice decimal(12,2) NOT NULL CHECK (UnitPrice >= 0)
);
CREATE TABLE dbo.RR_Returns (
 ReturnID int PRIMARY KEY, SaleItemID int NOT NULL REFERENCES dbo.RR_SaleItems(SaleItemID),
 ReturnQty int NOT NULL CHECK (ReturnQty > 0), ReturnDate date NOT NULL,
 Reason nvarchar(120) NULL
);
CREATE TABLE dbo.RR_Refunds (
 RefundID int PRIMARY KEY, ReturnID int NULL REFERENCES dbo.RR_Returns(ReturnID),
 Amount decimal(12,2) NOT NULL CHECK (Amount >= 0),
 RefundDate date NOT NULL,
 Status varchar(12) NOT NULL CHECK (Status IN ('Completed','Pending','Rejected'))
);
CREATE TABLE dbo.RR_ReturnFeedback (
 FeedbackID int PRIMARY KEY, ReturnID int NOT NULL UNIQUE REFERENCES dbo.RR_Returns(ReturnID),
 Rating int NULL CHECK (Rating BETWEEN 1 AND 5), Comments nvarchar(200) NULL
);
GO
INSERT dbo.RR_Stores VALUES (1,N'Central',N'North'),(2,N'Market',N'North'),(3,N'Plaza',N'South'),(4,N'Mall',N'South'),(5,N'Outlet',N'West');
INSERT dbo.RR_Customers VALUES (1,N'Asha'),(2,N'Bala'),(3,N'Chitra'),(4,N'Dinesh'),(5,N'Esha');
INSERT dbo.RR_Products VALUES (1,N'Shoes'),(2,N'Bag'),(3,N'Shirt'),(4,N'Bottle');
INSERT dbo.RR_Employees(EmployeeID,EmployeeName,StoreID,ManagerID) VALUES
 (1,N'Anita',1,NULL),(3,N'Carol',2,NULL),(5,N'Fathima',3,NULL),(7,N'Hari',4,NULL),
 (2,N'Bhavya',1,1),(4,N'Dev',2,3),(6,N'Gopi',3,5),(8,N'Isha',4,7);
INSERT dbo.RR_Sales VALUES
 (101,1,1,'2026-10-01'),(102,2,1,'2026-10-02'),(103,3,2,'2026-10-03'),
 (104,1,2,'2026-10-04'),(105,4,3,'2026-10-05'),(106,5,4,'2026-10-06'),
 (107,2,4,'2026-10-07'),(108,3,3,'2026-10-08'),(109,4,5,'2026-10-09');
INSERT dbo.RR_SaleItems VALUES
 (1001,101,1,10,100),(1002,101,2,2,500),
 (1003,102,1,10,100),(1004,102,3,8,250),
 (1005,103,1,10,100),(1006,103,2,2,500),
 (1007,104,3,10,250),(1008,105,1,10,100),
 (1009,105,4,10,100),(1010,106,1,10,100),
 (1011,107,2,2,500),(1012,108,3,10,250),
 (1013,109,4,10,100);
INSERT dbo.RR_Returns VALUES
 (201,1001,2,'2026-10-10',N'Damaged'),
 (202,1003,1,'2026-10-11',N'Wrong size'),
 (203,1005,1,'2026-10-12',N'Damaged'),
 (204,1007,2,'2026-10-13',N'Wrong fit'),
 (205,1008,2,'2026-10-14',N'Damaged'),
 (206,1010,1,'2026-10-15',N'Wrong size'),
 (207,1011,1,'2026-10-16',N'Not required'),
 (208,1012,1,'2026-10-17',N'Wrong fit');
INSERT dbo.RR_Refunds VALUES
 (301,201,200,'2026-10-11','Completed'),
 (302,202,100,'2026-10-12','Completed'),
 (303,203,100,'2026-10-13','Pending'),
 (304,204,500,'2026-10-14','Completed'),
 (305,205,200,'2026-10-15','Completed'),
 (306,206,100,'2026-10-16','Completed'),
 (307,207,500,'2026-10-17','Completed'),
 (308,NULL,50,'2026-10-18','Rejected'); -- INTENTIONAL NULL for NOT IN demo
INSERT dbo.RR_ReturnFeedback VALUES
 (401,201,2,N'Packaging damage'),(402,202,3,N'Size mismatch'),
 (403,203,1,N'Waiting for refund'),(404,204,4,N'Easy return'),
 (405,205,2,N'Damaged during delivery'),(406,207,5,N'Quick refund');
GO
PRINT 'Q1: Products with return rate above 10% (returned units / sold units)';
WITH Sold AS (SELECT ProductID, SUM(Quantity) SoldUnits FROM dbo.RR_SaleItems GROUP BY ProductID),
Returned AS (SELECT si.ProductID, SUM(r.ReturnQty) ReturnedUnits
 FROM dbo.RR_Returns r JOIN dbo.RR_SaleItems si ON si.SaleItemID=r.SaleItemID GROUP BY si.ProductID)
SELECT p.ProductID,p.ProductName,s.SoldUnits,COALESCE(rt.ReturnedUnits,0) ReturnedUnits,
 CAST(100.0*COALESCE(rt.ReturnedUnits,0)/NULLIF(s.SoldUnits,0) AS decimal(8,2)) ReturnRatePct
FROM Sold s JOIN dbo.RR_Products p ON p.ProductID=s.ProductID
LEFT JOIN Returned rt ON rt.ProductID=s.ProductID
WHERE 100.0*COALESCE(rt.ReturnedUnits,0)/NULLIF(s.SoldUnits,0)>10
ORDER BY ReturnRatePct DESC;

PRINT 'Q2: Customers with returns but NO completed refund on any of their returns';
SELECT c.CustomerID,c.CustomerName FROM dbo.RR_Customers c
WHERE EXISTS (SELECT 1 FROM dbo.RR_Sales s JOIN dbo.RR_SaleItems si ON si.SaleID=s.SaleID
 JOIN dbo.RR_Returns r ON r.SaleItemID=si.SaleItemID WHERE s.CustomerID=c.CustomerID)
AND NOT EXISTS (SELECT 1 FROM dbo.RR_Sales s JOIN dbo.RR_SaleItems si ON si.SaleID=s.SaleID
 JOIN dbo.RR_Returns r ON r.SaleItemID=si.SaleItemID
 JOIN dbo.RR_Refunds f ON f.ReturnID=r.ReturnID AND f.Status='Completed'
 WHERE s.CustomerID=c.CustomerID);

PRINT 'Q3: Stores ranked by completed refund value';
SELECT st.StoreID,st.StoreName,st.Region,COALESCE(SUM(f.Amount),0) RefundValue
FROM dbo.RR_Stores st LEFT JOIN dbo.RR_Sales s ON s.StoreID=st.StoreID
LEFT JOIN dbo.RR_SaleItems si ON si.SaleID=s.SaleID
LEFT JOIN dbo.RR_Returns r ON r.SaleItemID=si.SaleItemID
LEFT JOIN dbo.RR_Refunds f ON f.ReturnID=r.ReturnID AND f.Status='Completed'
GROUP BY st.StoreID,st.StoreName,st.Region ORDER BY RefundValue DESC,st.StoreID;

PRINT 'Q4: Employees and their managers (self join)';
SELECT e.EmployeeID,e.EmployeeName,st.StoreName,m.EmployeeName AS ManagerName
FROM dbo.RR_Employees e LEFT JOIN dbo.RR_Employees m ON m.EmployeeID=e.ManagerID
JOIN dbo.RR_Stores st ON st.StoreID=e.StoreID ORDER BY e.EmployeeID;

PRINT 'Q5: Returns not yet fully refunded (no completed refund)';
SELECT r.ReturnID,p.ProductName,r.ReturnQty,r.Reason
FROM dbo.RR_Returns r JOIN dbo.RR_SaleItems si ON si.SaleItemID=r.SaleItemID
JOIN dbo.RR_Products p ON p.ProductID=si.ProductID
WHERE NOT EXISTS (SELECT 1 FROM dbo.RR_Refunds f WHERE f.ReturnID=r.ReturnID AND f.Status='Completed')
ORDER BY r.ReturnID;

PRINT 'Q6: Customers with at least two distinct returns';
SELECT c.CustomerID,c.CustomerName,COUNT(DISTINCT r.ReturnID) AS ReturnCount
FROM dbo.RR_Customers c JOIN dbo.RR_Sales s ON s.CustomerID=c.CustomerID
JOIN dbo.RR_SaleItems si ON si.SaleID=s.SaleID JOIN dbo.RR_Returns r ON r.SaleItemID=si.SaleItemID
GROUP BY c.CustomerID,c.CustomerName HAVING COUNT(DISTINCT r.ReturnID)>=2;

PRINT 'Q7: Completed refunds as percentage of store sales value';
WITH SalesValue AS (
 SELECT s.StoreID,SUM(si.Quantity*si.UnitPrice) AS GrossSales
 FROM dbo.RR_Sales s JOIN dbo.RR_SaleItems si ON si.SaleID=s.SaleID GROUP BY s.StoreID
), RefundValue AS (
 SELECT s.StoreID,SUM(f.Amount) AS TotalRefund
 FROM dbo.RR_Refunds f JOIN dbo.RR_Returns r ON r.ReturnID=f.ReturnID
 JOIN dbo.RR_SaleItems si ON si.SaleItemID=r.SaleItemID JOIN dbo.RR_Sales s ON s.SaleID=si.SaleID
 WHERE f.Status='Completed' GROUP BY s.StoreID
)
SELECT st.StoreName,COALESCE(sv.GrossSales,0) GrossSales,COALESCE(rv.TotalRefund,0) TotalRefund,
 CAST(100.0*COALESCE(rv.TotalRefund,0)/NULLIF(sv.GrossSales,0) AS decimal(8,2)) RefundPct
FROM dbo.RR_Stores st LEFT JOIN SalesValue sv ON sv.StoreID=st.StoreID
LEFT JOIN RefundValue rv ON rv.StoreID=st.StoreID ORDER BY st.StoreID;

PRINT 'Q8: Return feedback with customer and product details';
SELECT r.ReturnID,c.CustomerName,p.ProductName,fb.Rating,fb.Comments
FROM dbo.RR_Returns r JOIN dbo.RR_SaleItems si ON si.SaleItemID=r.SaleItemID
JOIN dbo.RR_Sales s ON s.SaleID=si.SaleID JOIN dbo.RR_Customers c ON c.CustomerID=s.CustomerID
JOIN dbo.RR_Products p ON p.ProductID=si.ProductID
LEFT JOIN dbo.RR_ReturnFeedback fb ON fb.ReturnID=r.ReturnID ORDER BY r.ReturnID;

PRINT 'Q9: Stores with completed refunds greater than average across THEIR region (correlated)';
WITH Totals AS (
 SELECT st.StoreID,st.StoreName,st.Region,COALESCE(SUM(f.Amount),0) RefundTotal
 FROM dbo.RR_Stores st LEFT JOIN dbo.RR_Sales s ON s.StoreID=st.StoreID
 LEFT JOIN dbo.RR_SaleItems si ON si.SaleID=s.SaleID
 LEFT JOIN dbo.RR_Returns r ON r.SaleItemID=si.SaleItemID
 LEFT JOIN dbo.RR_Refunds f ON f.ReturnID=r.ReturnID AND f.Status='Completed'
 GROUP BY st.StoreID,st.StoreName,st.Region
)
SELECT t.StoreName,t.Region,t.RefundTotal FROM Totals t
WHERE t.RefundTotal>(SELECT AVG(CAST(t2.RefundTotal AS decimal(18,2))) FROM Totals t2
 WHERE t2.Region=t.Region) ORDER BY t.Region,t.StoreName;

PRINT 'Q10: Products ranked by estimated value of units returned';
SELECT p.ProductName,COUNT(DISTINCT r.ReturnID) ReturnCases,
 SUM(r.ReturnQty) ReturnedUnits,SUM(r.ReturnQty*si.UnitPrice) ReturnedValue
FROM dbo.RR_Returns r JOIN dbo.RR_SaleItems si ON si.SaleItemID=r.SaleItemID
JOIN dbo.RR_Products p ON p.ProductID=si.ProductID
GROUP BY p.ProductID,p.ProductName ORDER BY ReturnedValue DESC;

PRINT 'S1: IN - customers with returns';
SELECT CustomerID,CustomerName FROM dbo.RR_Customers
WHERE CustomerID IN (SELECT s.CustomerID FROM dbo.RR_Sales s
 JOIN dbo.RR_SaleItems si ON si.SaleID=s.SaleID JOIN dbo.RR_Returns r ON r.SaleItemID=si.SaleItemID);

PRINT 'S2: NULL pitfall - NOT IN yields no rows because Refunds.ReturnID contains NULL';
SELECT ReturnID FROM dbo.RR_Returns WHERE ReturnID NOT IN
 (SELECT ReturnID FROM dbo.RR_Refunds); -- returns ZERO rows on this sample

PRINT 'S3: Correct NOT EXISTS - returns without ANY refund record';
SELECT r.ReturnID FROM dbo.RR_Returns r
WHERE NOT EXISTS (SELECT 1 FROM dbo.RR_Refunds f WHERE f.ReturnID=r.ReturnID)
ORDER BY r.ReturnID; -- expected 208

PRINT 'S4: Safer NOT IN only after NULL removal';
SELECT r.ReturnID FROM dbo.RR_Returns r
WHERE r.ReturnID NOT IN (SELECT f.ReturnID FROM dbo.RR_Refunds f WHERE f.ReturnID IS NOT NULL);

PRINT 'S5: ANY/ALL compare store refund totals to OTHER stores within region';
WITH Totals AS (
 SELECT st.StoreID,st.StoreName,st.Region,CAST(COALESCE(SUM(f.Amount),0) AS decimal(18,2)) RefundTotal
 FROM dbo.RR_Stores st LEFT JOIN dbo.RR_Sales s ON s.StoreID=st.StoreID
 LEFT JOIN dbo.RR_SaleItems si ON si.SaleID=s.SaleID
 LEFT JOIN dbo.RR_Returns r ON r.SaleItemID=si.SaleItemID
 LEFT JOIN dbo.RR_Refunds f ON f.ReturnID=r.ReturnID AND f.Status='Completed'
 GROUP BY st.StoreID,st.StoreName,st.Region
)
SELECT t.StoreID,t.StoreName,t.Region,t.RefundTotal,
 CASE WHEN EXISTS (SELECT 1 FROM Totals o WHERE o.Region=t.Region AND o.StoreID<>t.StoreID)
       AND t.RefundTotal > ANY (SELECT o.RefundTotal FROM Totals o
           WHERE o.Region=t.Region AND o.StoreID<>t.StoreID)
      THEN 'Yes' ELSE 'No' END AS GreaterThanAnyPeer,
 CASE WHEN EXISTS (SELECT 1 FROM Totals o WHERE o.Region=t.Region AND o.StoreID<>t.StoreID)
       AND t.RefundTotal > ALL (SELECT o.RefundTotal FROM Totals o
           WHERE o.Region=t.Region AND o.StoreID<>t.StoreID)
      THEN 'Yes' ELSE 'No' END AS GreaterThanAllPeers
FROM Totals t ORDER BY t.Region,t.StoreID;

PRINT 'N1: Nested subquery: customers who returned products sold above avg unit price';
SELECT DISTINCT c.CustomerID,c.CustomerName FROM dbo.RR_Customers c
WHERE c.CustomerID IN (
 SELECT s.CustomerID FROM dbo.RR_Sales s WHERE s.SaleID IN (
  SELECT si.SaleID FROM dbo.RR_SaleItems si WHERE si.SaleItemID IN (
   SELECT r.SaleItemID FROM dbo.RR_Returns r)
   AND si.UnitPrice > (SELECT AVG(CAST(UnitPrice AS decimal(18,2))) FROM dbo.RR_SaleItems)))
ORDER BY c.CustomerID;

PRINT 'N2: Nested subquery: stores with refund totals above average store refund total';
WITH StoreTotals AS (
 SELECT st.StoreID,st.StoreName,COALESCE(SUM(f.Amount),0) RefundTotal
 FROM dbo.RR_Stores st LEFT JOIN dbo.RR_Sales s ON s.StoreID=st.StoreID
 LEFT JOIN dbo.RR_SaleItems si ON si.SaleID=s.SaleID
 LEFT JOIN dbo.RR_Returns r ON r.SaleItemID=si.SaleItemID
 LEFT JOIN dbo.RR_Refunds f ON f.ReturnID=r.ReturnID AND f.Status='Completed'
 GROUP BY st.StoreID,st.StoreName
)
SELECT x.StoreID,x.StoreName,x.RefundTotal FROM StoreTotals x
WHERE x.StoreID IN (
 SELECT y.StoreID FROM StoreTotals y
 WHERE y.RefundTotal > (SELECT AVG(CAST(z.RefundTotal AS decimal(18,2))) FROM StoreTotals z))
ORDER BY x.StoreID;
