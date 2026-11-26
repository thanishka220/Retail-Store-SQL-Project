--------------------------Insert Employees--------------------------------
ALTER PROCEDURE usp_InsertEmployee
    @StoreId VARCHAR(20) = NULL,
    @EmployeeName VARCHAR(100) = NULL,
    @EmployeeSalary VARCHAR(30) = NULL,
    @PhoneNumber VARCHAR(15) = NULL,
    @Email VARCHAR(150) = NULL,
    @Designation VARCHAR(100) = NULL,
    @EmployeeStatus VARCHAR(20) = 'Active'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @StoreIDValue INT,
                @Salary DECIMAL(10,2);

        SET @StoreId = TRIM(@StoreId);
        SET @EmployeeName = TRIM(@EmployeeName);
        SET @EmployeeSalary = TRIM(@EmployeeSalary);
        SET @PhoneNumber = NULLIF(TRIM(@PhoneNumber), '');
        SET @Email = NULLIF(TRIM(@Email), '');
        SET @Designation = NULLIF(TRIM(@Designation), '');
        SET @EmployeeStatus = TRIM(@EmployeeStatus);


        SET @StoreIDValue = TRY_CONVERT(INT, @StoreId);
        SET @Salary = TRY_CONVERT(DECIMAL(10,2), @EmployeeSalary);


        IF @StoreIDValue IS NULL OR @StoreIDValue <= 0
        BEGIN
            PRINT 'Enter a valid positive store ID.';
            RETURN;
        END


        IF @EmployeeName IS NULL
           OR LEN(REPLACE(@EmployeeName, ' ', '')) < 3
           OR @EmployeeName LIKE '%[^A-Za-z ]%'
           OR @EmployeeName LIKE '%  %'
        BEGIN
            PRINT 'Employee name must contain at least 3 letters and only single spaces.';
            RETURN;
        END


        IF @Salary IS NULL OR @Salary < 0
        BEGIN
            PRINT 'Enter a valid non-negative employee salary.';
            RETURN;
        END


        IF @PhoneNumber IS NOT NULL
           AND
           (
               LEN(@PhoneNumber) <> 10
               OR @PhoneNumber LIKE '%[^0-9]%'
           )
        BEGIN
            PRINT 'Phone number must contain exactly 10 digits.';
            RETURN;
        END


        IF @Email IS NOT NULL
           AND
           (
               @Email LIKE '% %'
               OR @Email NOT LIKE '%_@_%._%'
               OR LEN(@Email) - LEN(REPLACE(@Email, '@', '')) <> 1
               OR @Email LIKE '%..%'
               OR @Email LIKE '.%'
               OR @Email LIKE '%@.%'
               OR RIGHT(@Email, 1) = '.'
               OR CHARINDEX('.', @Email, CHARINDEX('@', @Email)) <= CHARINDEX('@', @Email) + 1
           )
        BEGIN
            PRINT 'Please enter a valid email address.';
            RETURN;
        END

 
        IF @Designation IS NOT NULL
           AND
           (
               LEN(REPLACE(@Designation, ' ', '')) < 3
               OR @Designation LIKE '%[^A-Za-z ]%'
               OR @Designation LIKE '%  %'
           )
        BEGIN
            PRINT 'Designation must contain at least 3 letters and only single spaces.';
            RETURN;
        END

  
        IF @EmployeeStatus NOT IN ('Active', 'Inactive')
        BEGIN
            PRINT 'Invalid employee status.';
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
            PRINT 'Cannot insert employee. Store does not exist or is inactive.';
            RETURN;
        END


        INSERT INTO dbo.Employees
        (
            StoreID,
            EmployeeName,
            EmployeeSalary,
            PhoneNumber,
            Email,
            Designation,
            EmployeeStatus
        )
        VALUES
        (
            @StoreIDValue,
            @EmployeeName,
            @Salary,
            @PhoneNumber,
            @Email,
            @Designation,
            @EmployeeStatus
        );

        PRINT 'Employee inserted successfully.';

    END TRY

    BEGIN CATCH
        PRINT 'Error inserting employee.';
        PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
        PRINT CONCAT('Error Line: ', ERROR_LINE());
        PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    END CATCH
END;
