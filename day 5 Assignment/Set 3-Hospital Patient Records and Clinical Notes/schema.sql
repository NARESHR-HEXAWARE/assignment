
USE master;
GO
IF DB_ID(N'HospitalClinicalDB') IS NULL
    CREATE DATABASE HospitalClinicalDB;
GO
USE HospitalClinicalDB;
GO
IF OBJECT_ID(N'dbo.Prescription', N'U') IS NOT NULL DROP TABLE dbo.Prescription;
IF OBJECT_ID(N'dbo.PatientBilling', N'U') IS NOT NULL DROP TABLE dbo.PatientBilling;
IF OBJECT_ID(N'dbo.Billing', N'U') IS NOT NULL DROP TABLE dbo.Billing;
IF OBJECT_ID(N'dbo.Visit', N'U') IS NOT NULL DROP TABLE dbo.Visit;
IF OBJECT_ID(N'dbo.Doctor', N'U') IS NOT NULL DROP TABLE dbo.Doctor;
IF OBJECT_ID(N'dbo.Patient', N'U') IS NOT NULL DROP TABLE dbo.Patient;
IF OBJECT_ID(N'dbo.Department', N'U') IS NOT NULL DROP TABLE dbo.Department;
GO
CREATE TABLE dbo.Department (
    department_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Department PRIMARY KEY,
    department_name NVARCHAR(100) NOT NULL CONSTRAINT UQ_Department_Name UNIQUE,
    floor_number INT NULL CONSTRAINT CK_Department_Floor CHECK (floor_number IS NULL OR floor_number BETWEEN 0 AND 30)
);
GO
CREATE TABLE dbo.Patient (
    patient_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Patient PRIMARY KEY,
    patient_name NVARCHAR(120) NOT NULL,
    address_line NVARCHAR(250) NOT NULL,
    phone VARCHAR(20) NULL CONSTRAINT UQ_Patient_Phone UNIQUE,
    date_of_birth DATE NULL
);
GO
CREATE TABLE dbo.Doctor (
    doctor_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Doctor PRIMARY KEY,
    doctor_name NVARCHAR(120) NOT NULL,
    department_id INT NOT NULL,
    license_number VARCHAR(30) NOT NULL CONSTRAINT UQ_Doctor_License UNIQUE,
    CONSTRAINT FK_Doctor_Department FOREIGN KEY (department_id)
        REFERENCES dbo.Department(department_id) ON DELETE NO ACTION
);
GO
CREATE TABLE dbo.Visit (
    visit_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Visit PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    visit_date DATE NOT NULL,
    diagnosis NVARCHAR(200) NOT NULL,
    visit_status VARCHAR(12) NOT NULL CONSTRAINT DF_Visit_Status DEFAULT ('Open'),
    CONSTRAINT CK_Visit_ValidDate CHECK (visit_date >= '2000-01-01' AND visit_date <= '2099-12-31'),
    CONSTRAINT CK_Visit_Status CHECK (visit_status IN ('Open','Completed','Cancelled')),
    CONSTRAINT CK_Visit_DiagnosisNonBlank CHECK (LEN(LTRIM(RTRIM(diagnosis))) > 0),
    CONSTRAINT FK_Visit_Patient FOREIGN KEY (patient_id) REFERENCES dbo.Patient(patient_id) ON DELETE NO ACTION,
    CONSTRAINT FK_Visit_Doctor FOREIGN KEY (doctor_id) REFERENCES dbo.Doctor(doctor_id) ON DELETE NO ACTION
);
GO
CREATE TABLE dbo.Billing (
    billing_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Billing PRIMARY KEY,
    visit_id INT NOT NULL CONSTRAINT UQ_Billing_Visit UNIQUE,
    bill_amount DECIMAL(12,2) NOT NULL CONSTRAINT CK_Billing_Nonnegative CHECK (bill_amount >= 0),
    payment_status VARCHAR(12) NOT NULL CONSTRAINT DF_Billing_PaymentStatus DEFAULT ('Unpaid'),
    CONSTRAINT CK_Billing_PaymentStatus CHECK (payment_status IN ('Unpaid','Paid','PartPaid')),
    CONSTRAINT FK_Billing_Visit FOREIGN KEY (visit_id) REFERENCES dbo.Visit(visit_id) ON DELETE CASCADE
);
GO
/* A visit may contain multiple prescriptions; this prevents repeating groups. */
CREATE TABLE dbo.Prescription (
    prescription_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Prescription PRIMARY KEY,
    visit_id INT NOT NULL,
    medication_name NVARCHAR(120) NOT NULL,
    dosage NVARCHAR(80) NOT NULL,
    CONSTRAINT FK_Prescription_Visit FOREIGN KEY (visit_id) REFERENCES dbo.Visit(visit_id) ON DELETE CASCADE
);
GO
CREATE INDEX IX_Visit_Date ON dbo.Visit (visit_date, patient_id);
CREATE INDEX IX_Doctor_Department ON dbo.Doctor (department_id);
GO

