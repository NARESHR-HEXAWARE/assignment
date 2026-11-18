

SET NOCOUNT ON;

SELECT l.LoanID, c.CustomerName, b.BranchName,
       COUNT(*) AS OverdueInstalmentCount,
       SUM(COALESCE(r.AmountDue, 0)) AS TotalScheduledAmountOverdue
FROM dbo.Loans AS l
JOIN dbo.Customers AS c ON c.CustomerID = l.CustomerID
JOIN dbo.Branches AS b ON b.BranchID = l.BranchID
JOIN dbo.Repayments AS r ON r.LoanID = l.LoanID
WHERE r.DueDate < CAST(GETDATE() AS date)
  AND r.PaidDate IS NULL
GROUP BY l.LoanID, c.CustomerName, b.BranchName
HAVING COUNT(*) > 3
ORDER BY OverdueInstalmentCount DESC, l.LoanID;

-- Q2. Customers who have loans in MORE THAN ONE DISTINCT branch.
SELECT c.CustomerID, c.CustomerName,
       COUNT(DISTINCT l.BranchID) AS BranchCount,
       COUNT(*) AS LoanCount
FROM dbo.Customers AS c
JOIN dbo.Loans AS l ON l.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CustomerName
HAVING COUNT(DISTINCT l.BranchID) > 1
ORDER BY BranchCount DESC, c.CustomerID;

-- Q3. Guarantors who are ALSO borrowers; Customers is joined twice (self-join).
-- A guarantor qualifies when they have at least one loan of their own.
SELECT DISTINCT g.CustomerID AS GuarantorCustomerID,
       guarantor.CustomerName AS GuarantorName,
       g.LoanID AS GuaranteedLoanID,
       borrower.CustomerName AS GuaranteedBorrowerName
FROM dbo.Guarantors AS g
JOIN dbo.Loans AS guaranteed_loan ON guaranteed_loan.LoanID = g.LoanID
JOIN dbo.Customers AS guarantor ON guarantor.CustomerID = g.CustomerID
JOIN dbo.Customers AS borrower ON borrower.CustomerID = guaranteed_loan.CustomerID
WHERE EXISTS (
    SELECT 1 FROM dbo.Loans AS own_loan
    WHERE own_loan.CustomerID = guarantor.CustomerID
)
ORDER BY GuarantorCustomerID, GuaranteedLoanID;

SELECT b.BranchID, b.BranchName
FROM dbo.Branches AS b
LEFT JOIN dbo.Loans AS l ON l.BranchID = b.BranchID
WHERE l.LoanID IS NULL
ORDER BY b.BranchID;


WITH CustomerBranchExposure AS (
    SELECT l.BranchID, l.CustomerID,
           SUM(COALESCE(l.OutstandingAmount, 0)) AS TotalExposure
    FROM dbo.Loans AS l
    GROUP BY l.BranchID, l.CustomerID
)
SELECT cbe.BranchID, b.BranchName, cbe.CustomerID, c.CustomerName,
       cbe.TotalExposure
FROM CustomerBranchExposure AS cbe
JOIN dbo.Branches AS b ON b.BranchID = cbe.BranchID
JOIN dbo.Customers AS c ON c.CustomerID = cbe.CustomerID
WHERE cbe.TotalExposure > (
    SELECT AVG(CAST(peer.TotalExposure AS decimal(19, 4)))
    FROM CustomerBranchExposure AS peer
    WHERE peer.BranchID = cbe.BranchID   -- correlated to the outer row
)
ORDER BY cbe.BranchID, cbe.TotalExposure DESC;

-- Q6. UNCORRELATED derived subquery: same definition and result as Q5.
-- The derived branch-average query does not refer to the outer query alias.
WITH CustomerBranchExposure AS (
    SELECT l.BranchID, l.CustomerID,
           SUM(COALESCE(l.OutstandingAmount, 0)) AS TotalExposure
    FROM dbo.Loans AS l
    GROUP BY l.BranchID, l.CustomerID
)
SELECT ce.BranchID, b.BranchName, ce.CustomerID, c.CustomerName,
       ce.TotalExposure, ba.AverageCustomerExposure
FROM CustomerBranchExposure AS ce
JOIN (
    SELECT BranchID,
           AVG(CAST(TotalExposure AS decimal(19, 4))) AS AverageCustomerExposure
    FROM CustomerBranchExposure
    GROUP BY BranchID
) AS ba ON ba.BranchID = ce.BranchID
JOIN dbo.Branches AS b ON b.BranchID = ce.BranchID
JOIN dbo.Customers AS c ON c.CustomerID = ce.CustomerID
WHERE ce.TotalExposure > ba.AverageCustomerExposure
ORDER BY ce.BranchID, ce.TotalExposure DESC;

SELECT c.CustomerID, c.CustomerName
FROM dbo.Customers AS c
WHERE EXISTS (
    SELECT 1 FROM dbo.Loans AS l
    WHERE l.CustomerID = c.CustomerID
)
AND NOT EXISTS (
    SELECT 1
    FROM dbo.Loans AS l
    JOIN dbo.Repayments AS r ON r.LoanID = l.LoanID
    WHERE l.CustomerID = c.CustomerID
      AND r.PaidDate >= DATEADD(DAY, -60, GETDATE())
      AND r.PaidDate <= GETDATE()
      AND COALESCE(r.AmountPaid, 0) > 0
)
ORDER BY c.CustomerID;

SELECT b.BranchID, b.BranchName,
       MAX(l.LoanAmount) AS BranchMaximumLoan
FROM dbo.Branches AS b
JOIN dbo.Loans AS l ON l.BranchID = b.BranchID
GROUP BY b.BranchID, b.BranchName
HAVING MAX(l.LoanAmount) > (
    SELECT AVG(CAST(branch_max.MaximumLoan AS decimal(19, 4)))
    FROM (
        SELECT MAX(l2.LoanAmount) AS MaximumLoan
        FROM dbo.Loans AS l2
        GROUP BY l2.BranchID
    ) AS branch_max
)
ORDER BY BranchMaximumLoan DESC, b.BranchID;

SELECT l.LoanID, c.CustomerName, b.BranchName,
       l.LoanAmount, l.OutstandingAmount
FROM dbo.Loans AS l
JOIN dbo.Customers AS c ON c.CustomerID = l.CustomerID
JOIN dbo.Branches AS b ON b.BranchID = l.BranchID
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Repayments AS r
    WHERE r.LoanID = l.LoanID
      AND r.PaidDate IS NOT NULL
      AND COALESCE(r.AmountPaid, 0) > 0
)
ORDER BY l.LoanID;

SELECT TOP (5) WITH TIES
       c.CustomerID, c.CustomerName,
       COUNT(l.LoanID) AS LoanCount,
       SUM(COALESCE(l.OutstandingAmount, 0)) AS TotalOutstandingExposure
FROM dbo.Customers AS c
JOIN dbo.Loans AS l ON l.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY TotalOutstandingExposure DESC;
