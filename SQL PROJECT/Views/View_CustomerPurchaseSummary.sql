-----------------------------Customer Purchase Summary---------------------
CREATE VIEW dbo.vw_CustomerPurchaseSummary
AS
WITH OrderSummary AS
(
    SELECT
        CustomerID,
        COUNT(*) AS Total_Orders,
        MAX(OrderDate) AS Last_Order_Date
    FROM dbo.Orders
    WHERE OrderStatus = 'Completed'
    GROUP BY CustomerID
),
PurchaseSummary AS
(
    SELECT
        O.CustomerID,
        SUM(OP.OrderQuantity) AS Total_Products_Purchased,
        SUM(OP.OrderQuantity * OP.ItemPrice) AS Total_Amount_Spent
    FROM dbo.Orders O
    INNER JOIN dbo.OrderProducts OP
        ON O.OrderID = OP.OrderID
    WHERE O.OrderStatus = 'Completed'
    GROUP BY O.CustomerID
)
SELECT
    C.CustomerID,
    C.CustomerName,
    C.CustomerStatus,
    ISNULL(OS.Total_Orders, 0) AS Total_Orders,
    ISNULL(PS.Total_Products_Purchased, 0) AS Total_Products_Purchased,
    ISNULL(PS.Total_Amount_Spent, 0) AS Total_Amount_Spent,
    OS.Last_Order_Date
FROM dbo.Customers C
LEFT JOIN OrderSummary OS
    ON C.CustomerID = OS.CustomerID
LEFT JOIN PurchaseSummary PS
    ON C.CustomerID = PS.CustomerID;
