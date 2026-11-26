IF DB_ID('Day10Bank') IS NULL CREATE DATABASE Day10Bank;
GO
USE Day10Bank;
GO
CREATE TABLE dbo.accounts(account_id int PRIMARY KEY, account_type varchar(20) NOT NULL CHECK(account_type IN('Savings','Current')), balance decimal(14,2) NOT NULL CHECK(balance>=0));
CREATE TABLE dbo.account_transaction(transaction_id int PRIMARY KEY, account_id int NOT NULL REFERENCES dbo.accounts(account_id), amount decimal(14,2) NOT NULL);
CREATE TABLE dbo.transaction_audit(audit_id bigint IDENTITY PRIMARY KEY, transaction_id int NOT NULL, operation varchar(6) NOT NULL, old_account_id int NULL, new_account_id int NULL, old_amount decimal(14,2), new_amount decimal(14,2), changed_by sysname DEFAULT ORIGINAL_LOGIN(), changed_at datetime2 DEFAULT SYSUTCDATETIME());
CREATE TABLE dbo.balance_audit(audit_id bigint IDENTITY PRIMARY KEY, account_id int NOT NULL, old_balance decimal(14,2), new_balance decimal(14,2), changed_by sysname DEFAULT ORIGINAL_LOGIN(), changed_at datetime2 DEFAULT SYSUTCDATETIME());
GO
CREATE OR ALTER TRIGGER dbo.tr_transaction_audit ON dbo.account_transaction AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted) AND UPDATE(transaction_id) THROW 50010,'Transaction ID cannot be updated.',1;
 INSERT dbo.transaction_audit(transaction_id,operation,old_account_id,new_account_id,old_amount,new_amount)
 SELECT COALESCE(i.transaction_id,d.transaction_id),CASE WHEN d.transaction_id IS NULL THEN 'INSERT' WHEN i.transaction_id IS NULL THEN 'DELETE' ELSE 'UPDATE' END,d.account_id,i.account_id,d.amount,i.amount FROM inserted i FULL JOIN deleted d ON i.transaction_id=d.transaction_id;
END;
GO
CREATE VIEW dbo.v_accounts AS SELECT account_id,account_type,balance FROM dbo.accounts;
GO
CREATE OR ALTER TRIGGER dbo.tr_balance_guard ON dbo.v_accounts INSTEAD OF UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF UPDATE(account_id) OR UPDATE(account_type) THROW 50011,'Only balance updates are allowed.',1;
 IF EXISTS(SELECT 1 FROM inserted WHERE balance<0) THROW 50012,'Negative balance forbidden; entire batch rejected.',1;
 UPDATE a SET balance=i.balance FROM dbo.accounts a JOIN inserted i ON a.account_id=i.account_id;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_balance_audit ON dbo.accounts AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF UPDATE(account_id) THROW 50013,'Account ID is immutable.',1;
 INSERT dbo.balance_audit(account_id,old_balance,new_balance) SELECT i.account_id,d.balance,i.balance FROM inserted i JOIN deleted d ON i.account_id=d.account_id WHERE i.balance<>d.balance;
END;
GO
CREATE ROLE bank_writer;
GRANT SELECT,UPDATE ON dbo.v_accounts TO bank_writer;
GRANT SELECT,INSERT,UPDATE,DELETE ON dbo.account_transaction TO bank_writer;
DENY INSERT,UPDATE,DELETE ON dbo.balance_audit TO bank_writer;
DENY INSERT,UPDATE,DELETE ON dbo.transaction_audit TO bank_writer;
GO
-- Audit rows are protected from ordinary writers, not immutable against admins.
-- Transaction records and balances are independent in this demo; no automatic posting.
-- Nested triggers: a view update invokes the base-table audit trigger.
-- Avoid recursive writes to the source table; SQL Server caps nesting at 32.
CREATE TABLE dbo.recursion_demo(id int PRIMARY KEY, n int NOT NULL);
GO
ALTER DATABASE Day10Bank SET RECURSIVE_TRIGGERS ON;
GO
CREATE OR ALTER TRIGGER dbo.tr_recursion_demo ON dbo.recursion_demo AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF TRIGGER_NESTLEVEL(OBJECT_ID('dbo.tr_recursion_demo'),'AFTER','DML')>1 RETURN;
 UPDATE r SET n=r.n+1 FROM dbo.recursion_demo r JOIN inserted i ON r.id=i.id;
END;
GO
