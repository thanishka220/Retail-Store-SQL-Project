--------------Orders Table
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID_OrderStatus
ON dbo.Orders (CustomerID, OrderStatus)
INCLUDE (OrderID, OrderDate);
