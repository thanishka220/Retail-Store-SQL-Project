----------------------Store Sales Ranking-------------------------------
ALTER PROCEDURE usp_Analysis_StoreSalesRanking
    @StoreID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

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
                PRINT 'Invalid Store ID. Store does not exist.';
                RETURN;
            END;
        END;

        WITH OrderSummary AS
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
                SUM(OP.OrderQuantity * OP.ItemPrice) AS TotalSales
            FROM dbo.Orders O
            INNER JOIN dbo.OrderProducts OP
                ON O.OrderID = OP.OrderID
            WHERE O.OrderStatus = 'Completed'
            GROUP BY O.StoreID
        ),
        StoreSales AS
        (
            SELECT
                S.StoreID,
                S.StoreName,
                S.City,
                ISNULL(OS.TotalOrders, 0) AS TotalOrders,
                ISNULL(SS.TotalSales, 0) AS TotalSales
            FROM dbo.Stores S
            LEFT JOIN OrderSummary OS
                ON S.StoreID = OS.StoreID
            LEFT JOIN SalesSummary SS
                ON S.StoreID = SS.StoreID
        )
        SELECT
            StoreID,
            StoreName,
            City,
            TotalOrders,
            TotalSales,
            RANK() OVER (ORDER BY TotalSales DESC) AS Sales_Rank
        FROM StoreSales
        WHERE @StoreID IS NULL
           OR StoreID = @StoreID
        ORDER BY Sales_Rank;

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while analyzing store sales ranking.';
        PRINT ERROR_MESSAGE();
    END CATCH;
END;


--------------------------Testcases---------------------------
EXEC usp_Analysis_StoreSalesRanking

EXEC usp_Analysis_StoreSalesRanking @StoreID = 1

EXEC usp_Analysis_StoreSalesRanking @StoreID = 999
