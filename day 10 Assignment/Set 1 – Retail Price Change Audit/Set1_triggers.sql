-- SQL Server 2025. Run in a new demo database.
IF DB_ID('Day10Retail') IS NULL CREATE DATABASE Day10Retail;
GO
USE Day10Retail;
GO
CREATE TABLE dbo.product_price(product_id int PRIMARY KEY, cost decimal(12,2) NOT NULL CHECK(cost>=0), price decimal(12,2) NOT NULL CHECK(price>=cost));
CREATE TABLE dbo.price_audit(audit_id bigint IDENTITY PRIMARY KEY, product_id int NOT NULL, old_price decimal(12,2), new_price decimal(12,2), changed_by sysname NOT NULL DEFAULT ORIGINAL_LOGIN(), changed_at datetime2 NOT NULL DEFAULT SYSUTCDATETIME(), outcome varchar(20) NOT NULL);
GO
CREATE OR ALTER TRIGGER dbo.tr_price_audit ON dbo.product_price AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 INSERT dbo.price_audit(product_id,old_price,new_price,outcome)
 SELECT i.product_id,d.price,i.price,'ACCEPTED' FROM inserted i JOIN deleted d ON i.product_id=d.product_id WHERE i.price<>d.price;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_price_guard ON dbo.product_price INSTEAD OF UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF UPDATE(product_id) OR UPDATE(cost) THROW 50001,'Only price updates are supported.',1;
 IF EXISTS(SELECT 1 FROM inserted WHERE price<cost)
 BEGIN
  INSERT dbo.price_audit(product_id,old_price,new_price,outcome)
  SELECT i.product_id,d.price,i.price,'REJECTED' FROM inserted i JOIN deleted d ON i.product_id=d.product_id WHERE i.price< i.cost;
  -- Reject the whole update without THROW so the rejection log can commit.
  -- A caller rollback still rolls back this log; it is not autonomous.
  RAISERROR('Batch rejected: price below cost.',10,1);
  RETURN;
 END;
 UPDATE p SET price=i.price FROM dbo.product_price p JOIN inserted i ON p.product_id=i.product_id;
END;
GO
-- Restrict direct audit changes for ordinary users (not privileged admins).
CREATE ROLE retail_writer;
GRANT SELECT, UPDATE ON dbo.product_price TO retail_writer;
DENY INSERT, UPDATE, DELETE ON dbo.price_audit TO retail_writer;
GO
-- Pitfalls: hidden logic and cascading trigger effects. Application code is
-- better for external notifications/retries. Permissions alone do not provide
-- cryptographic tamper evidence; use SQL Server ledger/external digest for that.
