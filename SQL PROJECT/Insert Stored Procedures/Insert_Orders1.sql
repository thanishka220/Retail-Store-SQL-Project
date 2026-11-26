------------------------Insert Orders---------------------
ALTER PROCEDURE dbo.usp_InsertOrder
    @CustomerId VARCHAR(20) = NULL,
    @StoreId VARCHAR(20) = NULL,
    @EmployeeId VARCHAR(20) = NULL,
    @OrderDate VARCHAR(50) = NULL,
    @OrderStatus VARCHAR(30) = 'Pending'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @CustomerIDValue INT,
                @StoreIDValue INT,
                @EmployeeIDValue INT,
                @OrderDateValue DATETIME2;


        SET @CustomerId = TRIM(@CustomerId);
        SET @StoreId = TRIM(@StoreId);
        SET @EmployeeId = TRIM(@EmployeeId);
        SET @OrderDate = TRIM(@OrderDate);
        SET @OrderStatus = TRIM(@OrderStatus);

        IF @CustomerId IS NULL OR @CustomerId = ''
        BEGIN
            PRINT 'Customer ID is required.';
            RETURN;
        END

        IF @StoreId IS NULL OR @StoreId = ''
        BEGIN
            PRINT 'Store ID is required.';
            RETURN;
        END

        IF @EmployeeId IS NULL OR @EmployeeId = ''
        BEGIN
            PRINT 'Employee ID is required.';
            RETURN;
        END

        IF @OrderDate IS NULL OR @OrderDate = ''
        BEGIN
            PRINT 'Order date is required.';
            RETURN;
        END

        IF @OrderStatus IS NULL OR @OrderStatus = ''
        BEGIN
            PRINT 'Order status is required.';
            RETURN;
        END

        SET @CustomerIDValue = TRY_CONVERT(INT, @CustomerId);
        SET @StoreIDValue = TRY_CONVERT(INT, @StoreId);
        SET @EmployeeIDValue = TRY_CONVERT(INT, @EmployeeId);
        SET @OrderDateValue = TRY_CONVERT(DATETIME2, @OrderDate, 126);

        IF @CustomerIDValue IS NULL OR @CustomerIDValue <= 0
        BEGIN
            PRINT 'Enter a valid positive customer ID.';
            RETURN;
        END

        IF @StoreIDValue IS NULL OR @StoreIDValue <= 0
        BEGIN
            PRINT 'Enter a valid positive store ID.';
            RETURN;
        END

        IF @EmployeeIDValue IS NULL OR @EmployeeIDValue <= 0
        BEGIN
            PRINT 'Enter a valid positive employee ID.';
            RETURN;
        END


        IF @OrderDateValue IS NULL
        BEGIN
            PRINT 'Invalid order date. Use YYYY-MM-DDTHH:MM:SS format.';
            RETURN;
        END

        IF @OrderDateValue > SYSDATETIME()
        BEGIN
            PRINT 'Order date cannot be in the future.';
            RETURN;
        END

        IF @OrderStatus NOT IN ('Pending', 'Processing', 'Completed', 'Cancelled')
        BEGIN
            PRINT 'Invalid order status.';
            RETURN;
        END

        IF @OrderStatus <> 'Pending'
        BEGIN
            PRINT 'A new order must have Pending status.';
            RETURN;
        END

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Customers
            WHERE CustomerID = @CustomerIDValue
              AND CustomerStatus = 'Active'
        )
        BEGIN
            PRINT 'Customer does not exist or is inactive.';
            RETURN;
        END

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Stores
            WHERE StoreID = @StoreIDValue
              AND StoreStatus = 'Active'
        )
        BEGIN
            PRINT 'Store does not exist or is inactive.';
            RETURN;
        END

 
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Employees
            WHERE EmployeeID = @EmployeeIDValue
              AND StoreID = @StoreIDValue
              AND EmployeeStatus = 'Active'
        )
        BEGIN
            PRINT 'Employee does not exist, is inactive, or does not belong to the selected store.';
            RETURN;
        END

        INSERT INTO dbo.Orders
        (
            CustomerID,
            StoreID,
            EmployeeID,
            OrderDate,
            OrderStatus
        )
        VALUES
        (
            @CustomerIDValue,
            @StoreIDValue,
            @EmployeeIDValue,
            @OrderDateValue,
            'Pending'
        );

        PRINT 'Order inserted successfully.';

    END TRY

    BEGIN CATCH

        PRINT 'Error occurred while inserting order.';
        PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
        PRINT CONCAT('Error Line: ', ERROR_LINE());
        PRINT CONCAT('Error Number: ', ERROR_NUMBER());

    END CATCH
END;

--------------------------------TestCases-----------------------------------------
--Insert order with all valid values
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '1',
    @OrderDate = '2026-11-25T10:00:00',
    @OrderStatus = 'Pending';


--Insert order without status
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '1',
    @OrderDate = '2026-11-25T10:30:00';

--Customer ID is NULL
EXEC usp_InsertOrder
    @CustomerId = NULL,
    @StoreId = '2',
    @EmployeeId = '1',
    @OrderDate = '2026-11-25T10:00:00';


--Store ID is NULL
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = NULL,
    @EmployeeId = '1',
    @OrderDate = '2026-11-25T10:00:00';


--Employee ID is NULL
EXEC dbo.usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '1',
    @EmployeeId = NULL,
    @OrderDate = '2026-11-25T10:00:00';


--Customer ID contains alphabets
EXEC usp_InsertOrder
    @CustomerId = 'ABC',
    @StoreId = '2',
    @EmployeeId = '1',
    @OrderDate = '2026-11-25T10:00:00';


--Store ID is zero
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '0',
    @EmployeeId = '1',
    @OrderDate = '2026-11-25T10:00:00';

--Employee ID is negative
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '-1',
    @OrderDate = '2026-11-25T10:00:00';


--Customer does not exist
EXEC usp_InsertOrder
    @CustomerId = '99999',
    @StoreId = '2',
    @EmployeeId = '1',
    @OrderDate = '2026-11-25T10:00:00';


--Invalid Store ID
EXEC dbo.usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '99999',
    @EmployeeId = '1',
    @OrderDate = '2026-11-25T10:00:00';


--Invalid Employee ID
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '99999',
    @OrderDate = '2026-11-25T10:00:00';

-- ORD12: Inactive customer
EXEC dbo.usp_InsertOrder
    @CustomerId = '2',
    @StoreId = '1',
    @EmployeeId = '1',
    @OrderDate = '2026-11-25T10:00:00';
GO

-- ORD13: Inactive store
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '2',
    @OrderDate = '2026-11-25T10:00:00';


--Inactive employee
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '3',
    @EmployeeId = '5',
    @OrderDate = '2026-11-25T10:00:00';


--Employee belongs to a different store
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '4',
    @OrderDate = '2026-11-25T10:00:00';

--Order date is NULL
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '1',
    @OrderDate = NULL;


--Order date is empty
EXEC dbo.usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '1',
    @OrderDate = '';


--Invalid date format
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '1',
    @OrderDate = '25-11-2026';


--Invalid date
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '1',
    @OrderDate = '2026-15-40T10:00:00';


--Future order date
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '1',
    @OrderDate = '2030-01-01T10:00:00';


--Invalid status
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '1',
    @OrderDate = '2026-11-25T10:00:00',
    @OrderStatus = 'Unknown';

--Order with Completed status
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '1',
    @EmployeeId = '1',
    @OrderDate = '2026-11-25T10:00:00',
    @OrderStatus = 'Completed';


--New order with Cancelled status
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '1',
    @OrderDate = '2026-11-25T10:00:00',
    @OrderStatus = 'Cancelled';


--Order status is NULL
EXEC usp_InsertOrder
    @CustomerId = '1',
    @StoreId = '2',
    @EmployeeId = '1',
    @OrderDate = '2026-11-25T10:00:00',
    @OrderStatus = NULL



SELECT * FROM Orders