---------------------Duplicate Customers--------------------------------
CREATE PROCEDURE usp_Analysis_DuplicateCustomers
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SELECT
            C.CustomerID,
            C.CustomerName,
            C.PhoneNumber,
            C.Email,
            'Duplicate Phone Number' AS Issue_Type
        FROM dbo.Customers C
        WHERE
            C.PhoneNumber IS NOT NULL
            AND TRIM(C.PhoneNumber) <> ''
            AND EXISTS
            (
                SELECT 1
                FROM dbo.Customers C2
                WHERE TRIM(C2.PhoneNumber) = TRIM(C.PhoneNumber)
                  AND C2.CustomerID <> C.CustomerID
            )

        UNION ALL

        SELECT
            C.CustomerID,
            C.CustomerName,
            C.PhoneNumber,
            C.Email,
            'Duplicate Email' AS Issue_Type
        FROM dbo.Customers C
        WHERE
            C.Email IS NOT NULL
            AND TRIM(C.Email) <> ''
            AND EXISTS
            (
                SELECT 1
                FROM dbo.Customers C2
                WHERE LOWER(TRIM(C2.Email)) = LOWER(TRIM(C.Email))
                  AND C2.CustomerID <> C.CustomerID
            )

        ORDER BY CustomerID;

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while analyzing duplicate customers.';
        PRINT ERROR_MESSAGE();
    END CATCH;
END;
