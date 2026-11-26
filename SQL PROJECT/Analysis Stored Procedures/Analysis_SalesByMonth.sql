-------------------------Sales By Month----------------------------

ALTER PROCEDURE usp_Analysis_SalesByMonth
    @Month INT = NULL
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY

        IF @Month IS NOT NULL
           AND (@Month < 1 OR @Month > 12)
        BEGIN
            PRINT 'Invalid Month. Enter a month between 1 and 12.'
            RETURN
        END

        ;WITH OrderSummary AS
        (
            SELECT
                MONTH(OrderDate) AS SalesMonth,
                COUNT(*) AS TotalOrders
            FROM dbo.Orders
            WHERE OrderStatus = 'Completed'
            GROUP BY MONTH(OrderDate)
        ),
        SalesSummary AS
        (
            SELECT
                MONTH(O.OrderDate) AS SalesMonth,
                SUM(OP.OrderQuantity) AS TotalProductsSold,
                SUM(OP.OrderQuantity * OP.ItemPrice) AS TotalSales
            FROM dbo.Orders O
            INNER JOIN dbo.OrderProducts OP
                ON O.OrderID = OP.OrderID
            WHERE O.OrderStatus = 'Completed'
            GROUP BY MONTH(O.OrderDate)
        )
        SELECT
            OS.SalesMonth,
            DATENAME(MONTH, DATEFROMPARTS(2000, OS.SalesMonth, 1)) AS MonthName,
            OS.TotalOrders,
            ISNULL(SS.TotalProductsSold, 0) AS TotalProductsSold,
            ISNULL(SS.TotalSales, 0) AS TotalSales
        FROM OrderSummary OS
        LEFT JOIN SalesSummary SS
            ON OS.SalesMonth = SS.SalesMonth
        WHERE @Month IS NULL
           OR OS.SalesMonth = @Month
        ORDER BY OS.SalesMonth

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while analyzing monthly sales.'
        PRINT ERROR_MESSAGE()
    END CATCH
END


