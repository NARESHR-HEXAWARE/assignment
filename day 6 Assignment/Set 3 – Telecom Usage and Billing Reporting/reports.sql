/*
  TELECOM USAGE AND BILLING REPORTS — SQL SERVER
  Deliverable: reports.sql

  Run the entire file in Microsoft SQL Server Management Studio (SSMS).
  This self-contained demonstration creates TelecomReportingDB and sample data.
  WARNING: Re-running drops and recreates the FIVE demonstration tables.

  Data model:
    plans(plan_id, plan_name, monthly_fee, data_limit_mb)
    subscribers(subscriber_id, subscriber_name, phone_number, circle, plan_id, joined_on)
    call_records(call_id, subscriber_id, call_started_at, duration_seconds)
    usage_records(usage_id, subscriber_id, used_at, data_used_mb, session_minutes)
    invoices(invoice_id, subscriber_id, invoice_number, bill_month, amount_due,
             amount_paid, issued_on, due_date, paid_on)

  Why usage_records? The four named tables alone do not contain measurable
  data consumption; this additional table makes data-limit and data-consumer
  reporting technically possible without misusing call duration as data usage.

  Assumptions:
  - All call and data usage reports use the CURRENT CALENDAR MONTH.
  - A subscriber's limit is the monthly data_limit_mb of their current plan.
  - Revenue is recognized here as collected invoice payments (amount_paid),
    reported by the invoice's bill_month, not necessarily payment date.
  - ARPU means the month's collected amount / all subscribers in that circle;
    circles with no collected amount show zero; no subscriber yields no row.
  - "No usage" means no calls AND no data events in the current month.
  - Overdue means unpaid balance > 0 and due_date < today - 15 days.
  - Amounts are in INR; data is measured in MB, and call time in minutes.
*/

IF DB_ID(N'TelecomReportingDB') IS NULL
    CREATE DATABASE TelecomReportingDB;
GO
USE TelecomReportingDB;
GO

DROP TABLE IF EXISTS dbo.invoices;
DROP TABLE IF EXISTS dbo.usage_records;
DROP TABLE IF EXISTS dbo.call_records;
DROP TABLE IF EXISTS dbo.subscribers;
DROP TABLE IF EXISTS dbo.plans;
GO

CREATE TABLE dbo.plans (
    plan_id INT NOT NULL PRIMARY KEY,
    plan_name NVARCHAR(60) NOT NULL UNIQUE,
    monthly_fee DECIMAL(10,2) NOT NULL CHECK (monthly_fee >= 0),
    data_limit_mb DECIMAL(12,2) NOT NULL CHECK (data_limit_mb > 0)
);

CREATE TABLE dbo.subscribers (
    subscriber_id INT NOT NULL PRIMARY KEY,
    subscriber_name NVARCHAR(100) NOT NULL,
    phone_number VARCHAR(15) NOT NULL UNIQUE,
    circle NVARCHAR(50) NOT NULL,
    plan_id INT NOT NULL REFERENCES dbo.plans(plan_id),
    joined_on DATE NOT NULL
);

CREATE TABLE dbo.call_records (
    call_id INT NOT NULL PRIMARY KEY,
    subscriber_id INT NOT NULL REFERENCES dbo.subscribers(subscriber_id),
    call_started_at DATETIME2(0) NOT NULL,
    duration_seconds INT NOT NULL CHECK (duration_seconds >= 0)
);

CREATE TABLE dbo.usage_records (
    usage_id INT NOT NULL PRIMARY KEY,
    subscriber_id INT NOT NULL REFERENCES dbo.subscribers(subscriber_id),
    used_at DATETIME2(0) NOT NULL,
    data_used_mb DECIMAL(12,2) NOT NULL CHECK (data_used_mb >= 0),
    session_minutes DECIMAL(10,2) NOT NULL CHECK (session_minutes >= 0)
);

CREATE TABLE dbo.invoices (
    invoice_id INT NOT NULL PRIMARY KEY,
    subscriber_id INT NOT NULL REFERENCES dbo.subscribers(subscriber_id),
    invoice_number VARCHAR(30) NOT NULL UNIQUE,
    bill_month DATE NOT NULL,
    amount_due DECIMAL(12,2) NOT NULL CHECK (amount_due >= 0),
    amount_paid DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
    issued_on DATE NOT NULL,
    due_date DATE NOT NULL,
    paid_on DATE NULL,
    CONSTRAINT CK_invoice_amount_paid CHECK (amount_paid <= amount_due),
    CONSTRAINT CK_invoice_dates CHECK (due_date >= issued_on),
    CONSTRAINT CK_invoice_paid_on CHECK (paid_on IS NULL OR paid_on >= issued_on)
);
GO

/* Sample data: dates are relative to the execution date so current-month and
   overdue reports remain useful whenever the file is executed. */
DECLARE @month_start DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
DECLARE @prev_month DATE = DATEADD(MONTH,-1,@month_start);
DECLARE @two_months_ago DATE = DATEADD(MONTH,-2,@month_start);
DECLARE @today DATE = CAST(GETDATE() AS DATE);

INSERT INTO dbo.plans (plan_id, plan_name, monthly_fee, data_limit_mb) VALUES
(1,N'Basic 2GB',199,2048),
(2,N'Standard 5GB',399,5120),
(3,N'Premium 10GB',699,10240),
(4,N'Unlimited Plus',999,102400),
(5,N'Student 1GB',149,1024);

INSERT INTO dbo.subscribers
(subscriber_id, subscriber_name, phone_number, circle, plan_id, joined_on) VALUES
(1,N'Arun Kumar','9000000001',N'Chennai',1,DATEADD(DAY,-220,@today)),
(2,N'Divya S','9000000002',N'Chennai',2,DATEADD(DAY,-198,@today)),
(3,N'Karthik N','9000000003',N'Chennai',3,DATEADD(DAY,-175,@today)),
(4,N'Meera P','9000000004',N'Mumbai',2,DATEADD(DAY,-160,@today)),
(5,N'Ravi V','9000000005',N'Mumbai',4,DATEADD(DAY,-130,@today)),
(6,N'Sana A','9000000006',N'Delhi',5,DATEADD(DAY,-105,@today)),
(7,N'Imran K','9000000007',N'Delhi',1,DATEADD(DAY,-99,@today)),
(8,N'Priya R','9000000008',N'Bengaluru',3,DATEADD(DAY,-88,@today)),
(9,N'Neha M','9000000009',N'Bengaluru',2,DATEADD(DAY,-70,@today)),
(10,N'Vijay T','9000000010',N'Chennai',5,DATEADD(DAY,-64,@today)),
(11,N'Farah H','9000000011',N'Mumbai',1,DATEADD(DAY,-44,@today)),
(12,N'Lokesh B','9000000012',N'Delhi',4,DATEADD(DAY,-35,@today));

INSERT INTO dbo.call_records (call_id, subscriber_id, call_started_at, duration_seconds) VALUES
(1,1,DATEADD(DAY,1,CAST(@month_start AS DATETIME2)),120),
(2,1,DATEADD(DAY,2,CAST(@month_start AS DATETIME2)),240),
(3,2,DATEADD(DAY,3,CAST(@month_start AS DATETIME2)),600),
(4,3,DATEADD(DAY,4,CAST(@month_start AS DATETIME2)),180),
(5,4,DATEADD(DAY,2,CAST(@month_start AS DATETIME2)),300),
(6,4,DATEADD(DAY,4,CAST(@month_start AS DATETIME2)),120),
(7,5,DATEADD(DAY,5,CAST(@month_start AS DATETIME2)),900),
(8,6,DATEADD(DAY,2,CAST(@month_start AS DATETIME2)),60),
(9,7,DATEADD(DAY,3,CAST(@month_start AS DATETIME2)),480),
(10,8,DATEADD(DAY,4,CAST(@month_start AS DATETIME2)),600),
(11,9,DATEADD(DAY,4,CAST(@month_start AS DATETIME2)),300),
(12,10,DATEADD(DAY,5,CAST(@month_start AS DATETIME2)),120),
(13,1,DATEADD(DAY,6,CAST(@month_start AS DATETIME2)),180),
(14,5,DATEADD(DAY,7,CAST(@month_start AS DATETIME2)),300),
(15,11,DATEADD(DAY,5,CAST(@prev_month AS DATETIME2)),360),
(16,12,DATEADD(DAY,6,CAST(@prev_month AS DATETIME2)),420);

INSERT INTO dbo.usage_records
(usage_id, subscriber_id, used_at, data_used_mb, session_minutes) VALUES
(1,1,DATEADD(DAY,1,CAST(@month_start AS DATETIME2)),1800,60),
(2,1,DATEADD(DAY,2,CAST(@month_start AS DATETIME2)),900,30),
(3,2,DATEADD(DAY,2,CAST(@month_start AS DATETIME2)),2700,55),
(4,2,DATEADD(DAY,3,CAST(@month_start AS DATETIME2)),2900,72),
(5,3,DATEADD(DAY,4,CAST(@month_start AS DATETIME2)),5800,91),
(6,3,DATEADD(DAY,5,CAST(@month_start AS DATETIME2)),2100,43),
(7,4,DATEADD(DAY,5,CAST(@month_start AS DATETIME2)),4800,84),
(8,5,DATEADD(DAY,1,CAST(@month_start AS DATETIME2)),14500,150),
(9,5,DATEADD(DAY,3,CAST(@month_start AS DATETIME2)),18300,170),
(10,6,DATEADD(DAY,1,CAST(@month_start AS DATETIME2)),1500,28),
(11,7,DATEADD(DAY,3,CAST(@month_start AS DATETIME2)),600,15),
(12,8,DATEADD(DAY,4,CAST(@month_start AS DATETIME2)),11000,100),
(13,9,DATEADD(DAY,2,CAST(@month_start AS DATETIME2)),3500,80),
(14,10,DATEADD(DAY,5,CAST(@month_start AS DATETIME2)),300,11),
(15,3,DATEADD(DAY,6,CAST(@month_start AS DATETIME2)),2800,52),
(16,11,DATEADD(DAY,5,CAST(@prev_month AS DATETIME2)),400,13),
(17,12,DATEADD(DAY,6,CAST(@prev_month AS DATETIME2)),3200,42);

/* Billing entries: one invoice per subscriber per bill month in this sample. */
INSERT INTO dbo.invoices
(invoice_id, subscriber_id, invoice_number, bill_month, amount_due, amount_paid,
 issued_on, due_date, paid_on) VALUES
(1,1,'INV-2026-0001',@prev_month,199,199,DATEADD(DAY,1,@prev_month),DATEADD(DAY,14,@prev_month),DATEADD(DAY,7,@prev_month)),
(2,2,'INV-2026-0002',@prev_month,399,399,DATEADD(DAY,1,@prev_month),DATEADD(DAY,14,@prev_month),DATEADD(DAY,9,@prev_month)),
(3,3,'INV-2026-0003',@prev_month,699,699,DATEADD(DAY,1,@prev_month),DATEADD(DAY,14,@prev_month),DATEADD(DAY,10,@prev_month)),
(4,4,'INV-2026-0004',@prev_month,399,0,DATEADD(DAY,1,@prev_month),DATEADD(DAY,14,@prev_month),NULL),
(5,5,'INV-2026-0005',@prev_month,999,999,DATEADD(DAY,1,@prev_month),DATEADD(DAY,14,@prev_month),DATEADD(DAY,10,@prev_month)),
(6,6,'INV-2026-0006',@prev_month,149,149,DATEADD(DAY,1,@prev_month),DATEADD(DAY,14,@prev_month),DATEADD(DAY,11,@prev_month)),
(7,7,'INV-2026-0007',@prev_month,199,0,DATEADD(DAY,1,@prev_month),DATEADD(DAY,14,@prev_month),NULL),
(8,8,'INV-2026-0008',@prev_month,699,350,DATEADD(DAY,1,@prev_month),DATEADD(DAY,14,@prev_month),DATEADD(DAY,12,@prev_month)),
(9,9,'INV-2026-0009',@prev_month,399,399,DATEADD(DAY,1,@prev_month),DATEADD(DAY,14,@prev_month),DATEADD(DAY,10,@prev_month)),
(10,10,'INV-2026-0010',@prev_month,149,149,DATEADD(DAY,1,@prev_month),DATEADD(DAY,14,@prev_month),DATEADD(DAY,9,@prev_month)),
(11,11,'INV-2026-0011',@two_months_ago,199,0,DATEADD(DAY,1,@two_months_ago),DATEADD(DAY,14,@two_months_ago),NULL),
(12,12,'INV-2026-0012',@two_months_ago,999,999,DATEADD(DAY,1,@two_months_ago),DATEADD(DAY,14,@two_months_ago),DATEADD(DAY,10,@two_months_ago)),
(13,1,'INV-2026-0013',@month_start,199,199,@month_start,DATEADD(DAY,20,@month_start),@month_start),
(14,2,'INV-2026-0014',@month_start,399,399,@month_start,DATEADD(DAY,20,@month_start),@month_start),
(15,3,'INV-2026-0015',@month_start,699,0,@month_start,DATEADD(DAY,20,@month_start),NULL),
(16,4,'INV-2026-0016',@month_start,399,0,@month_start,DATEADD(DAY,20,@month_start),NULL),
(17,5,'INV-2026-0017',@month_start,999,999,@month_start,DATEADD(DAY,20,@month_start),@month_start),
(18,6,'INV-2026-0018',@month_start,149,149,@month_start,DATEADD(DAY,20,@month_start),@month_start);
GO

/* ========================================================================
   REPORT 1 — TOTAL CALL MINUTES PER PLAN (CURRENT MONTH)
   Expected columns: plan_name, call_count, total_call_minutes.
   Expected: one row for EACH of 5 plans (even if no calls), in descending
   call minutes; durations are accurately converted from seconds to minutes.
   ======================================================================== */
SELECT p.plan_name,
       COUNT(c.call_id) AS call_count,
       CAST(ROUND(COALESCE(SUM(CAST(c.duration_seconds AS DECIMAL(18,2))),0)/60.0,2)
            AS DECIMAL(18,2)) AS total_call_minutes
FROM dbo.plans AS p
LEFT JOIN dbo.subscribers AS s ON s.plan_id = p.plan_id
LEFT JOIN dbo.call_records AS c
    ON c.subscriber_id = s.subscriber_id
   AND c.call_started_at >= DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
   AND c.call_started_at < DATEADD(MONTH,1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))
GROUP BY p.plan_id,p.plan_name
ORDER BY total_call_minutes DESC, p.plan_name;

/* ========================================================================
   REPORT 2 — SUBSCRIBERS EXCEEDING MONTHLY DATA LIMIT
   Expected: subscriber id, name, plan, limit, used MB, excess MB.
   Sample over-limit subscriber ids: 1, 2, 3, 6, 8.
   ======================================================================== */
WITH monthly_data AS (
 SELECT s.subscriber_id, s.subscriber_name, p.plan_name, p.data_limit_mb,
        COALESCE(SUM(u.data_used_mb),0) AS total_used_mb
 FROM dbo.subscribers AS s
 JOIN dbo.plans AS p ON p.plan_id=s.plan_id
 LEFT JOIN dbo.usage_records AS u
   ON u.subscriber_id=s.subscriber_id
  AND u.used_at >= DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
  AND u.used_at < DATEADD(MONTH,1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))
 GROUP BY s.subscriber_id,s.subscriber_name,p.plan_name,p.data_limit_mb
)
SELECT subscriber_id, subscriber_name, plan_name, data_limit_mb,
       total_used_mb,
       CAST(total_used_mb-data_limit_mb AS DECIMAL(12,2)) AS excess_mb
FROM monthly_data
WHERE total_used_mb > data_limit_mb
ORDER BY excess_mb DESC,subscriber_id;

/* ========================================================================
   REPORT 3 — MONTH-WISE COLLECTED REVENUE
   Expected: bill_month (yyyy-MM), total_collected, invoiced_amount,
   outstanding_amount. The latest three invoice months appear.
   ======================================================================== */
SELECT CONVERT(CHAR(7),i.bill_month,120) AS bill_month,
       SUM(i.amount_paid) AS total_collected,
       SUM(i.amount_due) AS invoiced_amount,
       SUM(i.amount_due-i.amount_paid) AS outstanding_amount
FROM dbo.invoices AS i
GROUP BY YEAR(i.bill_month),MONTH(i.bill_month),CONVERT(CHAR(7),i.bill_month,120)
ORDER BY bill_month;

/* ========================================================================
   REPORT 4 — INVOICES MORE THAN 15 DAYS OVERDUE
   Expected: formatted invoice, subscriber, due date, days overdue,
   unpaid balance, status. Includes unpaid and partly paid bills; excludes
   paid-in-full bills even if their due dates were long ago.
   ======================================================================== */
SELECT CONCAT('TEL-',RIGHT(CONCAT('000000',CAST(i.invoice_id AS VARCHAR(10))),6))
           AS formatted_invoice_number,
       i.invoice_number AS original_invoice_number,
       UPPER(s.subscriber_name) AS subscriber_name,
       i.due_date,
       DATEDIFF(DAY,i.due_date,CAST(GETDATE() AS DATE)) AS days_overdue,
       i.amount_due-i.amount_paid AS outstanding_balance,
       CASE WHEN i.amount_paid=0 THEN 'UNPAID'
            ELSE 'PARTIALLY PAID' END AS due_date_status
FROM dbo.invoices AS i
JOIN dbo.subscribers AS s ON s.subscriber_id=i.subscriber_id
WHERE i.amount_due > i.amount_paid
  AND i.due_date < DATEADD(DAY,-15,CAST(GETDATE() AS DATE))
ORDER BY days_overdue DESC,i.invoice_id;

/* ========================================================================
   REPORT 5 — SUBSCRIBERS WITH NO CURRENT-MONTH USAGE
   Expected: subscriber_id, subscriber_name, circle, plan_name.
   Sample: ids 11 and 12 (they have ONLY prior-month activity).
   ======================================================================== */
SELECT s.subscriber_id,s.subscriber_name,s.circle,p.plan_name
FROM dbo.subscribers AS s
JOIN dbo.plans AS p ON p.plan_id=s.plan_id
WHERE NOT EXISTS (
 SELECT 1 FROM dbo.call_records AS c
 WHERE c.subscriber_id=s.subscriber_id
   AND c.call_started_at >= DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
   AND c.call_started_at < DATEADD(MONTH,1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))
) AND NOT EXISTS (
 SELECT 1 FROM dbo.usage_records AS u
 WHERE u.subscriber_id=s.subscriber_id
   AND u.used_at >= DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
   AND u.used_at < DATEADD(MONTH,1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))
)
ORDER BY s.subscriber_id;

/* ========================================================================
   REPORT 6 — ARPU BY CIRCLE (CURRENT INVOICE MONTH)
   Expected: circle, subscribers, collected_revenue, ARPU_INR.
   ARPU denominator counts ALL subscribers in circle, including those with
   no invoice this month. Invoice sums are aggregated FIRST to prevent
   double-counting customers who have multiple invoices.
   ======================================================================== */
WITH current_invoice_totals AS (
 SELECT subscriber_id,SUM(amount_paid) AS paid_this_month
 FROM dbo.invoices
 WHERE bill_month = DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
 GROUP BY subscriber_id
)
SELECT s.circle,
       COUNT(*) AS subscriber_count,
       SUM(COALESCE(ci.paid_this_month,0)) AS collected_revenue,
       CAST(ROUND(SUM(COALESCE(ci.paid_this_month,0))*1.0/NULLIF(COUNT(*),0),2)
            AS DECIMAL(12,2)) AS arpu_inr
FROM dbo.subscribers AS s
LEFT JOIN current_invoice_totals AS ci ON ci.subscriber_id=s.subscriber_id
GROUP BY s.circle
ORDER BY arpu_inr DESC,s.circle;

/* ========================================================================
   REPORT 7 — PLAN POPULARITY
   Expected: plan name, subscriber count, percentage of subscriber base.
   Sample counts: Basic 2GB=3; Standard 5GB=3; Premium 10GB=2;
                  Unlimited Plus=2; Student 1GB=2.
   ======================================================================== */
SELECT p.plan_name,COUNT(s.subscriber_id) AS subscriber_count,
       CAST(ROUND(100.0*COUNT(s.subscriber_id)/NULLIF(
            (SELECT COUNT(*) FROM dbo.subscribers),0),2)
            AS DECIMAL(6,2)) AS popularity_percent
FROM dbo.plans AS p
LEFT JOIN dbo.subscribers AS s ON s.plan_id=p.plan_id
GROUP BY p.plan_id,p.plan_name
ORDER BY subscriber_count DESC,p.plan_name;

/* ========================================================================
   REPORT 8 — TOP 10 DATA CONSUMERS (CURRENT MONTH)
   Expected: id, name, circle, plan, data_used_mb, used_gb.
   All subscribers appear when fewer than 10 have current-month data;
   here exactly 10 have activity. Highest user: id 5 (32800 MB).
   ======================================================================== */
SELECT TOP (10) s.subscriber_id,s.subscriber_name,s.circle,p.plan_name,
       CAST(SUM(u.data_used_mb) AS DECIMAL(12,2)) AS data_used_mb,
       CAST(ROUND(SUM(u.data_used_mb)/1024.0,2) AS DECIMAL(12,2)) AS data_used_gb
FROM dbo.subscribers AS s
JOIN dbo.plans AS p ON p.plan_id=s.plan_id
JOIN dbo.usage_records AS u ON u.subscriber_id=s.subscriber_id
WHERE u.used_at >= DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
  AND u.used_at < DATEADD(MONTH,1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))
GROUP BY s.subscriber_id,s.subscriber_name,s.circle,p.plan_name
ORDER BY data_used_mb DESC,s.subscriber_id;

/* ========================================================================
   NULL DEMONSTRATION — SUM AND AVG WHEN USAGE ROWS ARE MISSING

   LEFT JOIN retains subscribers with no matching CURRENT-month usage.
   COUNT(*) counts the placeholder row (therefore >= 1 per subscriber).
   COUNT(u.usage_id) counts only actual usage rows.
   SUM(u.data_used_mb) and AVG(u.data_used_mb) ignore NULL inputs, but when
   there are ZERO non-NULL inputs they return NULL, not zero.
   COALESCE(SUM(...),0) gives a reporting-friendly zero; retaining the raw
   NULL AVG correctly conveys that no session average can be computed.

   Expected: subscribers 11 and 12 each have matched_usage_rows = 0,
   raw_sum_mb = NULL, raw_avg_mb = NULL, sum_for_display_mb = 0.
   ======================================================================== */
SELECT s.subscriber_id,s.subscriber_name,
       COUNT(*) AS joined_row_count,
       COUNT(u.usage_id) AS matched_usage_rows,
       SUM(u.data_used_mb) AS raw_sum_mb,
       AVG(u.data_used_mb) AS raw_avg_mb,
       COALESCE(SUM(u.data_used_mb),0) AS sum_for_display_mb
FROM dbo.subscribers AS s
LEFT JOIN dbo.usage_records AS u
 ON u.subscriber_id=s.subscriber_id
 AND u.used_at >= DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
 AND u.used_at < DATEADD(MONTH,1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))
GROUP BY s.subscriber_id,s.subscriber_name
ORDER BY s.subscriber_id;

/* END OF reports.sql */
