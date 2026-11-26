USE Day10Hospital;
GO
INSERT dbo.wards(ward_id,ward_name,capacity) VALUES(1,'General',2),(2,'ICU',1);
INSERT dbo.admissions(admission_id,patient_name,ward_id) VALUES(101,'Patient A',1);
BEGIN TRY
 INSERT dbo.admissions(admission_id,patient_name,ward_id) VALUES(102,'Patient B',1),(103,'Patient C',1),(104,'Patient D',2);
 THROW 51020,'Expected capacity failure did not occur',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50021 THROW;
 SELECT ERROR_MESSAGE() AS expected_error;
END CATCH;
IF (SELECT COUNT(*) FROM dbo.admissions)<>1 OR (SELECT occupied_beds FROM dbo.wards WHERE ward_id=2)<>0 THROW 51021,'Batch rollback failed',1;
INSERT dbo.admissions(admission_id,patient_name,ward_id) VALUES(102,'Patient B',1),(104,'Patient D',2);
UPDATE dbo.admissions SET patient_name='Patient A Updated' WHERE admission_id=101;
BEGIN TRY
 UPDATE dbo.admissions SET ward_id=2 WHERE admission_id=101;
 THROW 51022,'Expected transfer failure did not occur',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50021 THROW;
 SELECT ERROR_MESSAGE() AS expected_error;
END CATCH;
DELETE dbo.admissions WHERE admission_id=104;
UPDATE dbo.admissions SET ward_id=2 WHERE admission_id=101;
SELECT * FROM dbo.wards;
SELECT * FROM dbo.admissions;
SELECT * FROM dbo.admission_audit ORDER BY audit_id;
IF EXISTS(SELECT 1 FROM dbo.wards w WHERE w.occupied_beds<>(SELECT COUNT(*) FROM dbo.admissions a WHERE a.ward_id=w.ward_id)) THROW 51023,'Occupancy mismatch',1;
IF (SELECT COUNT(*) FROM dbo.admission_audit)<>6 THROW 51024,'Admission audit failed',1;
PRINT 'Hospital tests passed';
