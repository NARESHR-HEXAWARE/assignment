USE RetailDB;
GO

INSERT INTO Sales VALUES
(1, 101, '2026-01-10', 5, 250000),
(2, 101, '2026-02-10', 3, 150000),
(3, 102, '2026-01-15', 10, 200000),
(4, 102, '2026-02-15', 8, 160000),
(5, 103, '2026-01-20', 15, 30000),
(6, 104, '2026-01-12', 20, 20000),
(7, 104, '2026-02-12', 15, 15000),
(8, 105, '2026-01-18', 10, 15000),
(9, 106, '2026-01-25', 5, 15000),
(10, 107, '2026-01-28', 8, 20000),
(11, 108, '2026-01-30', 10, 8000);

-- Top 3 products by sales in each category
WITH ProductSales AS (
    SELECT
        P.ProductID,
        P.ProductName,
        C.CategoryName,
        SUM(S.Quantity) AS TotalQuantity,
        SUM(S.Amount) AS TotalSales
    FROM Products P
    INNER JOIN Categories C
        ON P.CategoryID = C.CategoryID
    INNER JOIN Sales S
        ON P.ProductID = S.ProductID
    GROUP BY
        P.ProductID,
        P.ProductName,
        C.CategoryName
),
RankedProducts AS (
    SELECT
        ProductID,
        ProductName,
        CategoryName,
        TotalQuantity,
        TotalSales,
        ROW_NUMBER() OVER (
            PARTITION BY CategoryName
            ORDER BY TotalSales DESC
        ) AS SalesRank
    FROM ProductSales
)
SELECT *
FROM RankedProducts
WHERE SalesRank <= 3
ORDER BY CategoryName, SalesRank;

-- Month-on-month sales using LAG and LEAD
WITH MonthlySales AS (
    SELECT
        ProductID,
        YEAR(SaleDate) AS SalesYear,
        MONTH(SaleDate) AS SalesMonth,
        SUM(Amount) AS TotalSales
    FROM Sales
    GROUP BY
        ProductID,
        YEAR(SaleDate),
        MONTH(SaleDate)
),
SalesComparison AS (
    SELECT
        ProductID,
        SalesYear,
        SalesMonth,
        TotalSales,
        LAG(TotalSales) OVER (
            PARTITION BY ProductID
            ORDER BY SalesYear, SalesMonth
        ) AS PreviousMonthSales,
        LEAD(TotalSales) OVER (
            PARTITION BY ProductID
            ORDER BY SalesYear, SalesMonth
        ) AS NextMonthSales
    FROM MonthlySales
)
SELECT
    ProductID,
    SalesYear,
    SalesMonth,
    TotalSales,
    PreviousMonthSales,
    NextMonthSales,
    TotalSales - PreviousMonthSales AS MonthOnMonthChange
FROM SalesComparison
ORDER BY ProductID, SalesYear, SalesMonth;