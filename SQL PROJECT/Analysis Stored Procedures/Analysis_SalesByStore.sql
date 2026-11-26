-------------------------Sales By Store----------------------------
ALTER PROCEDURE usp_Analysis_SalesByStore
    @StoreID INT = NULL
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY

        IF @StoreID IS NOT NULL
        BEGIN
            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.Stores
                WHERE StoreID = @StoreID
            )
            BEGIN
                PRINT 'Invalid Store ID. Store does not exist.'
                RETURN
            END
        END

        ;WITH OrderSummary AS
        (
            SELECT
                StoreID,
                COUNT(*) AS TotalOrders
            FROM dbo.Orders
            WHERE OrderStatus = 'Completed'
            GROUP BY StoreID
        ),
        SalesSummary AS
        (
            SELECT
                O.StoreID,
                SUM(OP.OrderQuantity) AS TotalProductsSold,
                SUM(OP.OrderQuantity * OP.ItemPrice) AS TotalSales
            FROM dbo.Orders O
            INNER JOIN dbo.OrderProducts OP
                ON O.OrderID = OP.OrderID
            WHERE O.OrderStatus = 'Completed'
            GROUP BY O.StoreID
        )
        SELECT
            S.StoreID,
            S.StoreName,
            ISNULL(OS.TotalOrders, 0) AS TotalOrders,
            ISNULL(SS.TotalProductsSold, 0) AS TotalProductsSold,
            ISNULL(SS.TotalSales, 0) AS TotalSales
        FROM dbo.Stores S
        LEFT JOIN OrderSummary OS
            ON S.StoreID = OS.StoreID
        LEFT JOIN SalesSummary SS
            ON S.StoreID = SS.StoreID
        WHERE @StoreID IS NULL
           OR S.StoreID = @StoreID
        ORDER BY TotalSales DESC

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while analyzing store sales.'
        PRINT ERROR_MESSAGE()
    END CATCH
END



