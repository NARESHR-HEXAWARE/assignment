/* Execute AFTER schema.sql in SQL Server Management Studio.
   Covers INSERT, UPDATE, DELETE, ALTER TABLE ADD, sp_rename, DROP CONSTRAINT,
   and WHERE / LIKE queries. This demo uses fictional identities and diagnoses. */
USE HospitalClinicalDB;
GO
SET NOCOUNT ON;

INSERT INTO dbo.Department (department_name, floor_number) VALUES
(N'Cardiology',2),(N'Neurology',3),(N'Orthopedics',1),(N'Pediatrics',4),
(N'Dermatology',2),(N'ENT',1),(N'General Medicine',0),(N'Oncology',5),
(N'Ophthalmology',3),(N'Pulmonology',4);

INSERT INTO dbo.Patient (patient_name,address_line,phone,date_of_birth) VALUES
(N'Aarav Shah',N'12 Lake Road','9000000001','1990-06-10'),
(N'Diya Rao',N'8 Park Street','9000000002','2001-02-02'),
(N'Kiran Iyer',N'44 Hill View','9000000003','1985-03-15'),
(N'Meera Nair',N'3 River Avenue','9000000004','1976-09-12'),
(N'Rohan Das',N'51 Market Road','9000000005','1998-12-04'),
(N'Sana Ali',N'21 Palm Lane','9000000006','2002-11-08'),
(N'Vikram Bose',N'19 Garden Road','9000000007','1968-04-20'),
(N'Ananya Menon',N'30 East Street','9000000008','1995-08-07'),
(N'Harish Kumar',N'15 West End','9000000009','1980-05-01'),
(N'Lakshmi Pillai',N'70 Main Street','9000000010','1989-10-30');

INSERT INTO dbo.Doctor (doctor_name,department_id,license_number) VALUES
(N'Dr. Priya Raman',1,'MED-1001'),(N'Dr. Arjun Nair',2,'MED-1002'),
(N'Dr. Swetha Iyer',3,'MED-1003'),(N'Dr. Asha Menon',4,'MED-1004'),
(N'Dr. Karthik Rao',5,'MED-1005'),(N'Dr. Nisha Ali',6,'MED-1006'),
(N'Dr. Dev Sharma',7,'MED-1007'),(N'Dr. Leena Bose',8,'MED-1008'),
(N'Dr. Rahul Das',9,'MED-1009'),(N'Dr. Farah Khan',10,'MED-1010');

INSERT INTO dbo.Visit (patient_id,doctor_id,visit_date,diagnosis,visit_status) VALUES
(1,1,'2026-10-03',N'Hypertension','Completed'),
(2,7,'2026-10-05',N'Seasonal fever','Completed'),
(3,3,'2026-10-08',N'Knee sprain','Completed'),
(4,6,'2026-10-12',N'Sinusitis','Completed'),
(5,5,'2026-10-15',N'Eczema','Completed'),
(6,2,'2026-10-18',N'Migraine','Open'),
(7,1,'2026-10-20',N'Chest discomfort','Open'),
(8,9,'2026-10-22',N'Dry eyes','Completed'),
(9,10,'2026-10-26',N'Asthma','Open'),
(10,7,'2026-10-29',N'General consultation','Completed'),
(1,1,'2026-11-02',N'Blood pressure follow-up','Open'),
(3,3,'2026-11-07',N'Sprain follow-up','Open');
/* The default visit_status is 'Open' if omitted. */
INSERT INTO dbo.Visit (patient_id,doctor_id,visit_date,diagnosis)
VALUES (2,7,'2026-11-12',N'Routine assessment');

INSERT INTO dbo.Billing (visit_id,bill_amount,payment_status) VALUES
(1,1200,'Paid'),(2,500,'Paid'),(3,1800,'Paid'),(4,800,'Paid'),
(5,900,'Paid'),(6,1500,'Unpaid'),(7,2200,'Unpaid'),(8,700,'Paid'),
(9,1600,'PartPaid'),(10,400,'Paid'),(11,650,'Unpaid'),
(12,600,'Unpaid'),(13,350,'Unpaid');

INSERT INTO dbo.Prescription (visit_id,medication_name,dosage) VALUES
(1,N'Demo Medicine A',N'1 tablet daily'),(2,N'Demo Medicine B',N'1 tablet twice daily'),
(3,N'Demo Gel C',N'Apply daily'),(4,N'Demo Spray D',N'1 spray daily'),
(5,N'Demo Cream E',N'Apply twice daily'),(6,N'Demo Medicine F',N'As directed'),
(7,N'Demo Medicine G',N'As directed'),(8,N'Demo Drops H',N'2 drops daily'),
(9,N'Demo Inhaler I',N'As directed'),(10,N'Demo Medicine J',N'As directed'),
(11,N'Demo Medicine A',N'1 tablet daily'),(12,N'Demo Gel C',N'Apply daily'),
(13,N'Demo Medicine B',N'As directed');

PRINT 'BEFORE UPDATE';
SELECT patient_id,patient_name,address_line FROM dbo.Patient WHERE patient_id=2;
UPDATE dbo.Patient SET address_line=N'10 Park Street, Updated' WHERE patient_id=2;
PRINT 'AFTER UPDATE';
SELECT patient_id,patient_name,address_line FROM dbo.Patient WHERE patient_id=2;

/* Temporary record inserted and deleted with WHERE, leaving real visit history intact. */
INSERT INTO dbo.Patient (patient_name,address_line,phone)
VALUES (N'Temporary Test Patient',N'Test Address','9000000099');
PRINT 'BEFORE DELETE';
SELECT patient_id,patient_name FROM dbo.Patient WHERE phone='9000000099';
DELETE FROM dbo.Patient WHERE phone='9000000099';
PRINT 'AFTER DELETE (0 rows expected)';
SELECT patient_id,patient_name FROM dbo.Patient WHERE phone='9000000099';

/* Patients who visited in October 2026, using a safe half-open range. */
SELECT DISTINCT p.patient_id,p.patient_name
FROM dbo.Patient AS p
JOIN dbo.Visit AS v ON v.patient_id=p.patient_id
WHERE v.visit_date >= '2026-10-01' AND v.visit_date < '2026-11-01'
ORDER BY p.patient_name;

/* Doctors in a named department, using WHERE and LIKE. */
SELECT d.doctor_name,dept.department_name
FROM dbo.Doctor AS d
JOIN dbo.Department AS dept ON dept.department_id=d.department_id
WHERE dept.department_name LIKE N'Cardio%'
ORDER BY d.doctor_name;

/* ALTER TABLE demonstrations (run once after schema.sql): */
PRINT 'BEFORE ALTER - insurance_id is not present';
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Patient' AND COLUMN_NAME='insurance_id';
ALTER TABLE dbo.Patient ADD insurance_id VARCHAR(40) NULL;
PRINT 'AFTER ALTER - insurance_id column exists, old records remain NULL';
SELECT patient_id,patient_name,insurance_id FROM dbo.Patient WHERE patient_id<=3;
UPDATE dbo.Patient SET insurance_id='INS-0001' WHERE patient_id=1;
SELECT patient_id,patient_name,insurance_id FROM dbo.Patient WHERE patient_id=1;

PRINT 'BEFORE RENAME: dbo.Billing';
SELECT name FROM sys.tables WHERE name IN ('Billing','PatientBilling');
EXEC sys.sp_rename N'dbo.Billing', N'PatientBilling', N'OBJECT';
PRINT 'AFTER RENAME: dbo.PatientBilling retains data, columns and foreign keys';
SELECT TOP (3) billing_id,visit_id,bill_amount FROM dbo.PatientBilling ORDER BY billing_id;

PRINT 'BEFORE DROP CONSTRAINT: CK_Visit_DiagnosisNonBlank';
SELECT name FROM sys.check_constraints WHERE name='CK_Visit_DiagnosisNonBlank';
ALTER TABLE dbo.Visit DROP CONSTRAINT CK_Visit_DiagnosisNonBlank;
PRINT 'AFTER DROP: other Visit constraints remain, nonblank-diagnosis rule no longer enforced';
SELECT name FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'dbo.Visit');
GO
