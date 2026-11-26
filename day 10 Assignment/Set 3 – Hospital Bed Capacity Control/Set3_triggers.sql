IF DB_ID('Day10Hospital') IS NULL CREATE DATABASE Day10Hospital;
GO
USE Day10Hospital;
GO
CREATE TABLE dbo.wards(ward_id int PRIMARY KEY, ward_name nvarchar(100) NOT NULL, capacity int NOT NULL CHECK(capacity>0), occupied_beds int NOT NULL DEFAULT 0 CHECK(occupied_beds>=0 AND occupied_beds<=capacity));
CREATE TABLE dbo.admissions(admission_id int PRIMARY KEY, patient_name nvarchar(100) NOT NULL, ward_id int NOT NULL REFERENCES dbo.wards(ward_id), admission_time datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
CREATE TABLE dbo.admission_audit(audit_id bigint IDENTITY PRIMARY KEY, admission_id int NOT NULL, operation varchar(6) NOT NULL, old_ward_id int, new_ward_id int, old_patient_name nvarchar(100), new_patient_name nvarchar(100), old_admission_time datetime2, new_admission_time datetime2, changed_by sysname DEFAULT ORIGINAL_LOGIN(), changed_at datetime2 DEFAULT SYSUTCDATETIME());
GO
-- Atomic ward counter updates take exclusive locks on affected ward rows.
-- A failed capacity check rolls back the entire admission statement.
CREATE OR ALTER TRIGGER dbo.tr_capacity ON dbo.admissions AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted) AND UPDATE(admission_id) THROW 50020,'Admission ID cannot be changed.',1;
 DECLARE @delta TABLE(ward_id int PRIMARY KEY, net_change int NOT NULL);
 INSERT @delta SELECT ward_id,SUM(delta) FROM (SELECT ward_id,1 AS delta FROM inserted UNION ALL SELECT ward_id,-1 FROM deleted) x GROUP BY ward_id HAVING SUM(delta)<>0;
 DECLARE @expected int=(SELECT COUNT(*) FROM @delta);
 UPDATE w SET occupied_beds=w.occupied_beds+d.net_change
 FROM dbo.wards w JOIN @delta d ON w.ward_id=d.ward_id
 WHERE w.occupied_beds+d.net_change BETWEEN 0 AND w.capacity;
 IF @@ROWCOUNT<>@expected THROW 50021,'Admission rejected: ward bed capacity exceeded or invalid occupancy.',1;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_admission_audit ON dbo.admissions AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 INSERT dbo.admission_audit(admission_id,operation,old_ward_id,new_ward_id,old_patient_name,new_patient_name,old_admission_time,new_admission_time)
 SELECT COALESCE(i.admission_id,d.admission_id),CASE WHEN d.admission_id IS NULL THEN 'INSERT' WHEN i.admission_id IS NULL THEN 'DELETE' ELSE 'UPDATE' END,d.ward_id,i.ward_id,d.patient_name,i.patient_name,d.admission_time,i.admission_time
 FROM inserted i FULL JOIN deleted d ON i.admission_id=d.admission_id;
END;
GO
EXEC sys.sp_settriggerorder @triggername=N'dbo.tr_capacity',@order=N'First',@stmttype=N'INSERT';
EXEC sys.sp_settriggerorder @triggername=N'dbo.tr_capacity',@order=N'First',@stmttype=N'UPDATE';
EXEC sys.sp_settriggerorder @triggername=N'dbo.tr_capacity',@order=N'First',@stmttype=N'DELETE';
GO
CREATE ROLE hospital_writer;
GRANT SELECT ON dbo.wards TO hospital_writer;
GRANT SELECT,INSERT,UPDATE,DELETE ON dbo.admissions TO hospital_writer;
DENY INSERT,UPDATE,DELETE ON dbo.wards TO hospital_writer;
DENY INSERT,UPDATE,DELETE ON dbo.admission_audit TO hospital_writer;
GO
-- CHECK constraints are preferable for single-row rules, such as capacity>0.
-- A stored procedure is preferable for an explicit admission workflow with
-- validation and notifications. Direct writes must then be restricted.
-- This demo counts every admission row as an occupied bed; discharge is DELETE.
