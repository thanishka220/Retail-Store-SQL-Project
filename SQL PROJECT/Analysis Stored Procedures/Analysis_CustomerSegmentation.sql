---------------------------Customer Segmentation----------------------------------
ALTER PROCEDURE usp_Analysis_CustomerSegmentation
    @CustomerID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        IF @CustomerID IS NOT NULL
        BEGIN
            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.Customers
                WHERE CustomerID = @CustomerID
            )
            BEGIN
                PRINT 'Invalid Customer ID. Customer does not exist.';
                RETURN;
            END;
        END;

        WITH OrderSummary AS
        (
            SELECT
                CustomerID,
                COUNT(*) AS TotalOrders
            FROM dbo.Orders
            WHERE OrderStatus = 'Completed'
            GROUP BY CustomerID
        ),
        SpendingSummary AS
        (
            SELECT
                O.CustomerID,
                SUM(OP.OrderQuantity * OP.ItemPrice) AS TotalSpending
            FROM dbo.Orders O
            INNER JOIN dbo.OrderProducts OP
                ON O.OrderID = OP.OrderID
            WHERE O.OrderStatus = 'Completed'
            GROUP BY O.CustomerID
        )
        SELECT
            C.CustomerID,
            C.CustomerName,
            ISNULL(OS.TotalOrders, 0) AS TotalOrders,
            ISNULL(SS.TotalSpending, 0) AS TotalSpending,
            CASE
                WHEN ISNULL(OS.TotalOrders, 0) = 0
                    THEN 'No Orders'
                WHEN ISNULL(SS.TotalSpending, 0) >= 50000
                    THEN 'High Value'
                WHEN ISNULL(SS.TotalSpending, 0) >= 20000
                    THEN 'Medium Value'
                ELSE 'Low Value'
            END AS CustomerSegment
        FROM dbo.Customers C
        LEFT JOIN OrderSummary OS
            ON C.CustomerID = OS.CustomerID
        LEFT JOIN SpendingSummary SS
            ON C.CustomerID = SS.CustomerID
        WHERE @CustomerID IS NULL
           OR C.CustomerID = @CustomerID
        ORDER BY TotalSpending DESC;

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while analyzing customer segmentation.';
        PRINT ERROR_MESSAGE();
    END CATCH;
END;

--------------------------------Testcases----------------------------------------
EXEC usp_Analysis_CustomerSegmentation

EXEC usp_Analysis_CustomerSegmentation @CustomerID = 1

EXEC usp_Analysis_CustomerSegmentation @CustomerID = 999