CREATE DATABASE RetailStore


----------------------------------------------STORES
CREATE TABLE Stores
(
    StoreID INT IDENTITY(1,1) PRIMARY KEY,
    StoreName VARCHAR(150) NOT NULL UNIQUE,
    City VARCHAR(100) NOT NULL,
    State VARCHAR(100) NOT NULL,
    StoreStatus VARCHAR(20) NOT NULL DEFAULT 'Active' 
                 CHECK (StoreStatus IN ('Active', 'Inactive')),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
)

------------------------------------------------CATEGORIES


CREATE TABLE Categories
(
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL UNIQUE,
    CategoryStatus VARCHAR(20) NOT NULL DEFAULT 'Active' 
                   CHECK (CategoryStatus IN ('Active', 'Inactive')),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
)

------------------------------------------CUSTOMERS


CREATE TABLE Customers
(
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    PhoneNumber VARCHAR(15),
    Email VARCHAR(150),
    DateOfBirth DATE 
                CHECK (DateOfBirth IS NULL OR DateOfBirth <= CAST(GETDATE() AS DATE)),
    Gender VARCHAR(10)
           CHECK (Gender IN ('Male', 'Female', 'Other') OR Gender IS NULL),
    RegisteredDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    CustomerStatus VARCHAR(20) NOT NULL DEFAULT 'Active'
                   CHECK (CustomerStatus IN ('Active', 'Inactive')),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
)

--------------------------------------------EMPLOYEES


CREATE TABLE Employees
(
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    StoreID INT NOT NULL
            REFERENCES Stores(StoreID),
    EmployeeName VARCHAR(100) NOT NULL,
    EmployeeSalary DECIMAL(10,2) NOT NULL
                    CHECK (EmployeeSalary >= 0),
    PhoneNumber VARCHAR(15),
    Email VARCHAR(150),
    Designation VARCHAR(100),
    EmployeeStatus VARCHAR(20) NOT NULL DEFAULT 'Active' 
                    CHECK (EmployeeStatus IN ('Active', 'Inactive')),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
)

-----------------------------------------------PRODUCTS


CREATE TABLE Products
(
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryID INT NOT NULL
               REFERENCES Categories(CategoryID),
    ProductName VARCHAR(150) NOT NULL,
    CostPrice DECIMAL(10,2) NOT NULL
              CHECK (CostPrice >= 0),
    SellingPrice DECIMAL(10,2) NOT NULL
                 CHECK (SellingPrice >= 0),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
)

--------------------------------------------------------------INVENTORY


CREATE TABLE Inventory
(
    InventoryID INT IDENTITY(1,1) PRIMARY KEY,
    StoreID INT NOT NULL
            REFERENCES Stores(StoreID),
    ProductID INT NOT NULL
               REFERENCES Products(ProductID),
    StockQuantity INT NOT NULL
                   CHECK (StockQuantity >= 0),
    ReorderLevel INT NOT NULL
                  CHECK (ReorderLevel >= 0),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UNIQUE (StoreId, ProductId)
)

------------------------------------------------------ORDERS


CREATE TABLE Orders
(
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL
               REFERENCES Customers(CustomerID),
    StoreID INT NOT NULL
            REFERENCES Stores(StoreID),
    EmployeeID INT NOT NULL
               REFERENCES Employees(EmployeeID),
    OrderDate DATETIME2 NOT NULL,
    OrderStatus VARCHAR(30) NOT NULL DEFAULT 'Pending'
                CHECK (OrderStatus IN ('Pending', 'Processing', 'Completed', 'Cancelled')),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
)

-------------------------------------------------------ORDER PRODUCTS


CREATE TABLE OrderProducts
(
    ItemID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL
            REFERENCES Orders(OrderID),
    ProductID INT NOT NULL
              REFERENCES Products(ProductID),
    OrderQuantity INT NOT NULL
                  CHECK (OrderQuantity > 0),
    ItemPrice DECIMAL(10,2) NOT NULL
              CHECK (ItemPrice >= 0),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UNIQUE (OrderId, ProductId)
)

----------------------------------------------------------PAYMENTS


CREATE TABLE Payments
(
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL
            REFERENCES Orders(OrderID),
    PaymentDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    PaymentMethod VARCHAR(30) NOT NULL
                   CHECK (PaymentMethod IN('Cash', 'Card', 'UPI', 'NetBanking')),
    PaymentStatus VARCHAR(30) NOT NULL DEFAULT 'Pending'
                   CHECK (PaymentStatus IN('Pending', 'Completed', 'Failed')),
    PaymentAmount DECIMAL(10,2) NOT NULL
                   CHECK (PaymentAmount > 0),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
)

---------------------------------------------------RETURNS

CREATE TABLE Returns
(
    ReturnID INT IDENTITY(1,1) PRIMARY KEY,
    ItemID INT NOT NULL
           REFERENCES OrderProducts(ItemID),
    ReturnDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ReturnQuantity INT NOT NULL
                   CHECK (ReturnQuantity > 0),
    ReturnStatus VARCHAR(30) NOT NULL DEFAULT 'Pending'
                 CHECK (ReturnStatus IN('Pending', 'Approved', 'Rejected', 'Completed')),
    Reason NVARCHAR(255),
    ReturnAmount DECIMAL(10,2) NOT NULL
        CHECK (ReturnAmount >= 0),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
)