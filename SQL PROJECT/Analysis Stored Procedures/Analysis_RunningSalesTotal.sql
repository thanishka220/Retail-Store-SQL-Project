--------------------------Running Sales Total------------------------------
ALTER PROCEDURE usp_Analysis_RunningSalesTotal
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        WITH MonthlySales AS
        (
            SELECT
                YEAR(O.OrderDate) AS SalesYear,
                MONTH(O.OrderDate) AS SalesMonth,
                SUM(OP.OrderQuantity * OP.ItemPrice) AS MonthlySales
            FROM dbo.Orders O
            INNER JOIN dbo.OrderProducts OP
                ON O.OrderID = OP.OrderID
            WHERE O.OrderStatus = 'Completed'
            GROUP BY
                YEAR(O.OrderDate),
                MONTH(O.OrderDate)
        )
        SELECT
            SalesYear,
            SalesMonth,
            DATENAME
            (
                MONTH,
                DATEFROMPARTS(SalesYear, SalesMonth, 1)
            ) AS [MonthName],
            MonthlySales,
            SUM(MonthlySales) OVER
            (
                ORDER BY Sales_Year, Sales_Month
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS RunningTotal
        FROM MonthlySales
        ORDER BY
            SalesYear,
            SalesMonth;

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while calculating running sales total.';
        PRINT ERROR_MESSAGE();
    END CATCH;
END;
