----------------------Month Over Month Growth------------------------
ALTER PROCEDURE dbo.usp_Analysis_MonthOverMonthGrowth
    @Month INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        IF @Month IS NOT NULL AND (@Month < 1 OR @Month > 12)
        BEGIN
            PRINT 'Invalid Month. Enter a month between 1 and 12.';
            RETURN;
        END;

        WITH MonthlySales AS
        (
            SELECT
                YEAR(O.OrderDate) AS Sales_Year,
                MONTH(O.OrderDate) AS Sales_Month,
                SUM(OP.OrderQuantity * OP.ItemPrice) AS Total_Sales
            FROM dbo.Orders O
            INNER JOIN dbo.OrderProducts OP
                ON O.OrderID = OP.OrderID
            WHERE O.OrderStatus = 'Completed'
            GROUP BY
                YEAR(O.OrderDate),
                MONTH(O.OrderDate)
        ),
        PreviousMonthSales AS
        (
            SELECT
                Sales_Year,
                Sales_Month,
                Total_Sales,
                LAG(Total_Sales) OVER
                (
                    ORDER BY Sales_Year, Sales_Month
                ) AS Previous_Month_Sales
            FROM MonthlySales
        )
        SELECT
            Sales_Year,
            Sales_Month,
            DATENAME
            (
                MONTH,
                DATEFROMPARTS(Sales_Year, Sales_Month, 1)
            ) AS Month_Name,
            Total_Sales AS Current_Month_Sales,
            Previous_Month_Sales,
            CAST
            (
                (Total_Sales - Previous_Month_Sales) * 100.0
                / NULLIF(Previous_Month_Sales, 0)
                AS DECIMAL(10,2)
            ) AS Growth_Percentage
        FROM PreviousMonthSales
        WHERE @Month IS NULL
           OR Sales_Month = @Month
        ORDER BY Sales_Year, Sales_Month;

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while analyzing month-over-month growth.';
        PRINT ERROR_MESSAGE();
    END CATCH;
END;

---------------------------------Testcases----------------------------------------
EXEC usp_Analysis_MonthOverMonthGrowth

EXEC usp_Analysis_MonthOverMonthGrowth @Month = 6

EXEC usp_Analysis_MonthOverMonthGrowth @Month = 13
