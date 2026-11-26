------------------Store Inventory Status----------------------------------
CREATE VIEW vw_StoreInventoryStatus
AS
SELECT
    I.InventoryID,
    S.StoreID,
    S.StoreName,
    S.City,
    P.ProductID,
    P.ProductName,
    C.CategoryName,
    I.StockQuantity,
    I.ReorderLevel,
    CASE
        WHEN I.StockQuantity = 0 THEN 'Out of Stock'
        WHEN I.StockQuantity <= I.ReorderLevel THEN 'Low Stock'
        ELSE 'In Stock'
    END AS StockStatus
FROM dbo.Inventory I
INNER JOIN dbo.Stores S
    ON I.StoreID = S.StoreID
INNER JOIN dbo.Products P
    ON I.ProductID = P.ProductID
INNER JOIN dbo.Categories C
    ON P.CategoryID = C.CategoryID;

SELECT * FROM dbo.vw_OrderDetails
