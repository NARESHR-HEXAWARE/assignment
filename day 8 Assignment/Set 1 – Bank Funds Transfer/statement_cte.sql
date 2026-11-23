USE BankDB;
GO

CREATE TABLE BankTransactions (
    TransactionID INT PRIMARY KEY,
    AccountID INT,
    TransactionDate DATE,
    TransactionType VARCHAR(10),
    Amount DECIMAL(12,2)
);

INSERT INTO BankTransactions VALUES
(1, 101, '2026-01-05', 'CREDIT', 5000),
(2, 101, '2026-01-10', 'DEBIT', 1000),
(3, 101, '2026-01-15', 'DEBIT', 500),
(4, 101, '2026-02-05', 'CREDIT', 2000),
(5, 101, '2026-02-10', 'DEBIT', 700),
(6, 101, '2026-02-15', 'CREDIT', 1000);

DECLARE @OpeningBalance DECIMAL(12,2) = 10000;

WITH TransactionDetails AS (
    SELECT
        TransactionID,
        AccountID,
        TransactionDate,
        TransactionType,
        Amount,
        CASE
            WHEN TransactionType = 'CREDIT' THEN Amount
            ELSE -Amount
        END AS NetAmount
    FROM BankTransactions
    WHERE AccountID = 101
),
RunningStatement AS (
    SELECT
        TransactionID,
        AccountID,
        TransactionDate,
        TransactionType,
        Amount,
        @OpeningBalance +
        SUM(NetAmount) OVER (
            PARTITION BY AccountID
            ORDER BY TransactionDate, TransactionID
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CurrentBalance
    FROM TransactionDetails
)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY TransactionDate, TransactionID
    ) AS SerialNumber,
    TransactionID,
    TransactionDate,
    TransactionType,
    Amount,
    LAG(CurrentBalance, 1, @OpeningBalance) OVER (
        ORDER BY TransactionDate, TransactionID
    ) AS PreviousBalance,
    CurrentBalance
FROM RunningStatement
ORDER BY TransactionDate, TransactionID;