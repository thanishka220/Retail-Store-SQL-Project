-------------------------Best Selling Products-----------------------------
CREATE PROCEDURE usp_Analysis_BestSellingProducts
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

        SELECT
            P.ProductID,
            P.ProductName,
            ISNULL(SUM(OP.OrderQuantity), 0) AS TotalQuantitySold,
            ISNULL(SUM(OP.OrderQuantity * OP.ItemPrice), 0) AS TotalSales
        FROM dbo.Products P
        LEFT JOIN dbo.OrderProducts OP
            ON P.ProductID = OP.ProductID
        LEFT JOIN dbo.Orders O
            ON OP.OrderID = O.OrderID
           AND O.OrderStatus = 'Completed'
        WHERE (@CategoryID IS NULL OR P.CategoryID = @CategoryID)
          AND (OP.OrderID IS NULL OR O.OrderID IS NOT NULL)
        GROUP BY
            P.ProductID,
            P.ProductName
        ORDER BY
            TotalQuantitySold DESC

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while analyzing best-selling products.'
        PRINT ERROR_MESSAGE()
    END CATCH
END

--------------------------------Testcases--------------------------------------
EXEC usp_Analysis_BestSellingProducts

EXEC usp_Analysis_BestSellingProducts @CategoryID = 1

EXEC usp_Analysis_BestSellingProducts @CategoryID = 999