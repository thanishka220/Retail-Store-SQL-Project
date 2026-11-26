--------------------------Repeat Customers-------------------------------
ALTER PROCEDURE usp_Analysis_RepeatCustomers
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
            HAVING COUNT(*) > 1
        ),
        PurchaseSummary AS
        (
            SELECT
                O.CustomerID,
                SUM(OP.OrderQuantity) AS TotalProductsPurchased,
                SUM(OP.OrderQuantity * OP.ItemPrice) AS TotalAmountSpent
            FROM dbo.Orders O
            INNER JOIN dbo.OrderProducts OP
                ON O.OrderID = OP.OrderID
            WHERE O.OrderStatus = 'Completed'
            GROUP BY O.CustomerID
        )
        SELECT
            C.CustomerID,
            C.CustomerName,
            OS.TotalOrders,
            ISNULL(PS.TotalProductsPurchased, 0) AS TotalProductsPurchased,
            ISNULL(PS.TotalAmountSpent, 0) AS TotalAmountSpent
        FROM dbo.Customers C
        INNER JOIN OrderSummary OS
            ON C.CustomerID = OS.CustomerID
        LEFT JOIN PurchaseSummary PS
            ON C.CustomerID = PS.CustomerID
        WHERE @CustomerID IS NULL
           OR C.CustomerID = @CustomerID
        ORDER BY OS.TotalOrders DESC;

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while analyzing repeat customers.';
        PRINT ERROR_MESSAGE();
    END CATCH;
END;

---------------------------------Testcases-------------------------------
EXEC usp_Analysis_RepeatCustomers

EXEC usp_Analysis_RepeatCustomers @CustomerID = 1

EXEC usp_Analysis_RepeatCustomers @CustomerID = 999