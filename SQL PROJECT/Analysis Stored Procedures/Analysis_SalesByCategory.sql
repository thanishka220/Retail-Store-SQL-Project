----------------------Sales By Category-----------------------------------
CREATE PROCEDURE dbo.usp_Analysis_SalesByCategory
    @CategoryID INT = NULL
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY

        IF @CategoryID IS NOT NULL
        BEGIN
            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.Categories
                WHERE CategoryID = @CategoryID
            )
            BEGIN
                PRINT 'Invalid Category ID. Category does not exist.'
                RETURN
            END
        END

        ;WITH OrderCategory AS
        (
            SELECT
                P.CategoryID,
                O.OrderID
            FROM dbo.Products P
            INNER JOIN dbo.OrderProducts OP
                ON P.ProductID = OP.ProductID
            INNER JOIN dbo.Orders O
                ON OP.OrderID = O.OrderID
            WHERE O.OrderStatus = 'Completed'
            GROUP BY
                P.CategoryID,
                O.OrderID
        ),
        OrderSummary AS
        (
            SELECT
                CategoryID,
                COUNT(*) AS TotalOrders
            FROM OrderCategory
            GROUP BY CategoryID
        ),
        SalesSummary AS
        (
            SELECT
                P.CategoryID,
                SUM(OP.OrderQuantity) AS TotalProductsSold,
                SUM(OP.OrderQuantity * OP.ItemPrice) AS TotalSales
            FROM dbo.Products P
            INNER JOIN dbo.OrderProducts OP
                ON P.ProductID = OP.ProductID
            INNER JOIN dbo.Orders O
                ON OP.OrderID = O.OrderID
            WHERE O.OrderStatus = 'Completed'
            GROUP BY P.CategoryID
        )
        SELECT
            C.CategoryID,
            C.CategoryName,
            ISNULL(OS.TotalOrders, 0) AS TotalOrders,
            ISNULL(SS.TotalProductsSold, 0) AS TotalProductsSold,
            ISNULL(SS.TotalSales, 0) AS TotalSales
        FROM dbo.Categories C
        LEFT JOIN OrderSummary OS
            ON C.CategoryID = OS.CategoryID
        LEFT JOIN SalesSummary SS
            ON C.CategoryID = SS.CategoryID
        WHERE @CategoryID IS NULL
           OR C.CategoryID = @CategoryID
        ORDER BY TotalSales DESC

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while analyzing sales by category.'
        PRINT ERROR_MESSAGE()
    END CATCH
END

