----------------Order Products Table
CREATE NONCLUSTERED INDEX IX_OrderProducts_ProductID
ON dbo.OrderProducts (ProductID)
INCLUDE (OrderID, OrderQuantity, ItemPrice);
