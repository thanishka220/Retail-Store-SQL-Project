----------------------Return Rate------------------------------
ALTER PROCEDURE usp_Analysis_ProductReturnRate
    @ProductID INT = NULL
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        IF @ProductID IS NOT NULL
        BEGIN
            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.Products
                WHERE ProductID = @ProductID
            )
            BEGIN
                PRINT 'Invalid Product ID. Product does not exist.'
                RETURN
            END
        END

        ;WITH SalesSummary AS
        (
            SELECT
                OP.ProductID,
                SUM(OP.OrderQuantity) AS TotalQuantitySold
            FROM dbo.OrderProducts OP
            INNER JOIN dbo.Orders O
                ON OP.OrderID = O.OrderID
            WHERE O.OrderStatus = 'Completed'
            GROUP BY OP.ProductID
        ),
        ReturnSummary AS
        (
            SELECT
                OP.ProductID,
                SUM(R.ReturnQuantity) AS TotalReturnQuantity
            FROM dbo.Returns R
            INNER JOIN dbo.OrderProducts OP
                ON R.ItemID = OP.ItemID
            INNER JOIN dbo.Orders O
                ON OP.OrderID = O.OrderID
            WHERE R.ReturnStatus <> 'Rejected'
              AND O.OrderStatus = 'Completed'
            GROUP BY OP.ProductID
        )
        SELECT
            P.ProductID,
            P.ProductName,
            ISNULL(SS.TotalQuantitySold, 0) AS TotalQuantitySold,
            ISNULL(RS.TotalReturnQuantity, 0) AS TotalReturnQuantity,
            ISNULL
            (
                CAST
                (
                    RS.TotalReturnQuantity * 100.0
                    / NULLIF(SS.TotalQuantitySold, 0)
                    AS DECIMAL(10,2)
                ),
                0
            ) AS ReturnRate
        FROM dbo.Products P
        LEFT JOIN SalesSummary SS
            ON P.ProductID = SS.ProductID
        LEFT JOIN ReturnSummary RS
            ON P.ProductID = RS.ProductID
        WHERE @ProductID IS NULL
           OR P.ProductID = @ProductID
        ORDER BY ReturnRate DESC

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while analyzing product return rate.'
        PRINT ERROR_MESSAGE()
    END CATCH
END
