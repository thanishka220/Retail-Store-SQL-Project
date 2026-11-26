---------------------------Order Details-------------------------------
CREATE VIEW dbo.vw_OrderDetails
AS
SELECT
    O.OrderID,
    O.OrderDate,
    O.OrderStatus,
    C.CustomerID,
    C.CustomerName,
    S.StoreID,
    S.StoreName,
    E.EmployeeID,
    E.EmployeeName,
    P.ProductID,
    P.ProductName,
    CAT.CategoryName,
    OP.OrderQuantity,
    OP.ItemPrice,
    OP.OrderQuantity * OP.ItemPrice AS ItemTotal
FROM dbo.Orders O
INNER JOIN dbo.Customers C
    ON O.CustomerID = C.CustomerID
INNER JOIN dbo.Stores S
    ON O.StoreID = S.StoreID
INNER JOIN dbo.Employees E
    ON O.EmployeeID = E.EmployeeID
INNER JOIN dbo.OrderProducts OP
    ON O.OrderID = OP.OrderID
INNER JOIN dbo.Products P
    ON OP.ProductID = P.ProductID
INNER JOIN dbo.Categories CAT
    ON P.CategoryID = CAT.CategoryID;
