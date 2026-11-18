
IF DB_ID(N'RetailInventoryDB') IS NULL
    CREATE DATABASE RetailInventoryDB;
GO
USE RetailInventoryDB;
GO
IF OBJECT_ID(N'dbo.Inventory', N'U') IS NOT NULL DROP TABLE dbo.Inventory;
IF OBJECT_ID(N'dbo.Products', N'U') IS NOT NULL DROP TABLE dbo.Products;
IF OBJECT_ID(N'dbo.Warehouses', N'U') IS NOT NULL DROP TABLE dbo.Warehouses;
IF OBJECT_ID(N'dbo.Suppliers', N'U') IS NOT NULL DROP TABLE dbo.Suppliers;
IF OBJECT_ID(N'dbo.Categories', N'U') IS NOT NULL DROP TABLE dbo.Categories;
GO
CREATE TABLE dbo.Categories (
    CategoryID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Categories PRIMARY KEY,
    CategoryName NVARCHAR(80) NOT NULL CONSTRAINT UQ_Categories_Name UNIQUE
);
CREATE TABLE dbo.Suppliers (
    SupplierID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Suppliers PRIMARY KEY,
    SupplierName NVARCHAR(100) NOT NULL CONSTRAINT UQ_Suppliers_Name UNIQUE,
    SupplierPhone VARCHAR(20) NOT NULL
);
CREATE TABLE dbo.Warehouses (
    WarehouseID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Warehouses PRIMARY KEY,
    WarehouseName NVARCHAR(80) NOT NULL CONSTRAINT UQ_Warehouses_Name UNIQUE,
    City NVARCHAR(80) NOT NULL
);
CREATE TABLE dbo.Products (
    ProductID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Products PRIMARY KEY,
    SKU VARCHAR(25) NOT NULL CONSTRAINT UQ_Products_SKU UNIQUE,
    ProductName NVARCHAR(120) NOT NULL,
    CategoryID INT NOT NULL,
    SupplierID INT NOT NULL,
    ReorderLevel INT NOT NULL CONSTRAINT DF_Products_ReorderLevel DEFAULT (5),
    ProductStatus VARCHAR(15) NOT NULL CONSTRAINT DF_Products_Status DEFAULT ('ACTIVE'),
    CONSTRAINT CK_Products_ReorderLevel CHECK (ReorderLevel >= 0),
    CONSTRAINT CK_Products_Status CHECK (ProductStatus IN ('ACTIVE', 'DISCONTINUED')),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID)
        REFERENCES dbo.Categories(CategoryID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY (SupplierID)
        REFERENCES dbo.Suppliers(SupplierID) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE TABLE dbo.Inventory (
    ProductID INT NOT NULL,
    WarehouseID INT NOT NULL,
    Quantity INT NOT NULL CONSTRAINT DF_Inventory_Quantity DEFAULT (0),
    LastUpdated DATETIME2(0) NOT NULL CONSTRAINT DF_Inventory_LastUpdated DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_Inventory PRIMARY KEY (ProductID, WarehouseID),
    CONSTRAINT CK_Inventory_Quantity CHECK (Quantity >= 0),
    CONSTRAINT FK_Inventory_Products FOREIGN KEY (ProductID)
        REFERENCES dbo.Products(ProductID) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT FK_Inventory_Warehouses FOREIGN KEY (WarehouseID)
        REFERENCES dbo.Warehouses(WarehouseID) ON DELETE NO ACTION ON UPDATE NO ACTION
);
GO
