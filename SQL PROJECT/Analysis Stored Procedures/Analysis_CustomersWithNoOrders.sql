----------------------Customers With No Orders---------------------------------
CREATE PROCEDURE usp_Analysis_CustomersWithNoOrders
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY

        SELECT
            C.CustomerID,
            C.CustomerName
        FROM dbo.Customers C
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.Orders O
            WHERE O.CustomerID = C.CustomerID
        )
        ORDER BY C.CustomerName

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while analyzing customers with no orders.'
        PRINT ERROR_MESSAGE()
    END CATCH
END

