----------------------Product Returns--------------------------
CREATE PROCEDURE usp_Analysis_ProductReturns
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

        ;WITH ReturnSummary AS
        (
            SELECT
                OP.ProductID,
                COUNT(*) AS Total_Returns,
                SUM(R.ReturnQuantity) AS Total_Return_Quantity,
                SUM(R.ReturnAmount) AS Total_Return_Amount
            FROM dbo.Returns R
            INNER JOIN dbo.OrderProducts OP
                ON R.ItemID = OP.ItemID
            WHERE R.ReturnStatus <> 'Rejected'
            GROUP BY OP.ProductID
        )
        SELECT
            P.ProductID,
            P.ProductName,
            ISNULL(RS.Total_Returns, 0) AS Total_Returns,
            ISNULL(RS.Total_Return_Quantity, 0) AS Total_Return_Quantity,
            ISNULL(RS.Total_Return_Amount, 0) AS Total_Return_Amount
        FROM dbo.Products P
        LEFT JOIN ReturnSummary RS
            ON P.ProductID = RS.ProductID
        WHERE @ProductID IS NULL
           OR P.ProductID = @ProductID
        ORDER BY Total_Return_Quantity DESC

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while analyzing product returns.'
        PRINT ERROR_MESSAGE()
    END CATCH
END



