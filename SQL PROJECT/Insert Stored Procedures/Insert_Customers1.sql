------------------------Insert Customers-------------------------------
ALTER PROCEDURE dbo.usp_InsertCustomer
    @CustomerName VARCHAR(100) = NULL,
    @PhoneNumber VARCHAR(15) = NULL,
    @Email VARCHAR(150) = NULL,
    @DateOfBirth VARCHAR(30) = NULL,
    @Gender VARCHAR(10) = NULL,
    @RegisteredDate VARCHAR(30) = NULL,
    @CustomerStatus VARCHAR(20) = 'Active'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @DOB DATE,
                @RegDate DATE;
        SET @CustomerName = TRIM(@CustomerName);
        SET @PhoneNumber = NULLIF(TRIM(@PhoneNumber), '');
        SET @Email = NULLIF(TRIM(@Email), '');
        SET @Gender = NULLIF(TRIM(@Gender), '');
        SET @DateOfBirth = NULLIF(TRIM(@DateOfBirth), '');
        SET @RegisteredDate = NULLIF(TRIM(@RegisteredDate), '');
        SET @CustomerStatus = TRIM(@CustomerStatus);

        IF @CustomerName IS NULL OR @CustomerName = ''
        BEGIN
            PRINT 'Customer name is required.';
            RETURN;
        END

        IF @CustomerStatus IS NULL OR @CustomerStatus = ''
        BEGIN
            PRINT 'Customer status is required.';
            RETURN;
        END

        IF LEN(REPLACE(@CustomerName, ' ', '')) < 3
           OR @CustomerName LIKE '%[^A-Za-z ]%'
           OR @CustomerName LIKE '%  %'
        BEGIN
            PRINT 'Customer name must contain at least 3 letters and only single spaces.';
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

        IF @DateOfBirth IS NOT NULL
        BEGIN
            SET @DOB = TRY_CONVERT(DATE, @DateOfBirth, 23);

            IF @DOB IS NULL
            BEGIN
                PRINT 'Invalid date of birth. Use YYYY-MM-DD format.';
                RETURN;
            END

            IF @DOB > CAST(GETDATE() AS DATE)
            BEGIN
                PRINT 'Date of birth cannot be in the future.';
                RETURN;
            END
        END

        IF @RegisteredDate IS NOT NULL
        BEGIN
            SET @RegDate = TRY_CONVERT(DATE, @RegisteredDate, 23);

            IF @RegDate IS NULL
            BEGIN
                PRINT 'Invalid registered date. Use YYYY-MM-DD format.';
                RETURN;
            END

            IF @RegDate > CAST(GETDATE() AS DATE)
            BEGIN
                PRINT 'Registered date cannot be in the future.';
                RETURN;
            END
        END
        ELSE
            SET @RegDate = CAST(GETDATE() AS DATE);

        IF @DOB IS NOT NULL AND @DOB > @RegDate
        BEGIN
            PRINT 'Date of birth cannot be after the registered date.';
            RETURN;
        END

        IF @Gender IS NOT NULL
           AND @Gender NOT IN ('Male', 'Female', 'Other')
        BEGIN
            PRINT 'Invalid gender. Use Male, Female or Other.';
            RETURN;
        END

        IF @CustomerStatus NOT IN ('Active', 'Inactive')
        BEGIN
            PRINT 'Invalid customer status.';
            RETURN;
        END

        INSERT INTO dbo.Customers
        (
            CustomerName,
            PhoneNumber,
            Email,
            DateOfBirth,
            Gender,
            RegisteredDate,
            CustomerStatus
        )
        VALUES
        (
            @CustomerName,
            @PhoneNumber,
            @Email,
            @DOB,
            @Gender,
            @RegDate,
            @CustomerStatus
        );

        PRINT 'Customer inserted successfully.';

    END TRY
    BEGIN CATCH
        PRINT CONCAT('Error inserting customer: ', ERROR_MESSAGE());
        PRINT CONCAT('Error Line: ', ERROR_LINE());
        PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    END CATCH
END;

--------------------------------------TestCases----------------------------------------
--With all valid values
EXEC usp_InsertCustomer
    @CustomerName = 'Thanishka',
    @PhoneNumber = '9876543210',
    @Email = 'Thanu@gmail.com',
    @DateOfBirth = '2000-05-20',
    @Gender = 'Female',
    @RegisteredDate = '2026-11-25',
    @CustomerStatus = 'Active'

--With only required customer name
EXEC usp_InsertCustomer
    @CustomerName = 'Priya';

--Without phone number
EXEC usp_InsertCustomer
    @CustomerName = 'Kiran',
    @PhoneNumber = NULL;

--Without email
EXEC usp_InsertCustomer
    @CustomerName = 'Rahul',
    @Email = NULL;

--Without DOB and gender
EXEC usp_InsertCustomer
    @CustomerName = 'Anitha',
    @DateOfBirth = NULL,
    @Gender = NULL;

--With Inactive status
EXEC usp_InsertCustomer
    @CustomerName = 'Inactive Customer',
    @CustomerStatus = 'Inactive';

--With valid date format
EXEC usp_InsertCustomer
    @CustomerName = 'Rose',
    @DateOfBirth = '1995-10-15',
    @RegisteredDate = '2020-01-01';

--Customer name is NULL
EXEC dbo.usp_InsertCustomer
    @CustomerName = NULL;

--Customer name is empty
EXEC usp_InsertCustomer
    @CustomerName = '';


--Customer name contains only spaces
EXEC usp_InsertCustomer
    @CustomerName = '   ';


--Invalid Customer Name
EXEC dbo.usp_InsertCustomer
    @CustomerName = 'AB';


--Customer name contains numbers
EXEC usp_InsertCustomer
    @CustomerName = 'Th123';

--Customer name contains special characters
EXEC usp_InsertCustomer
    @CustomerName = 'Thanu@';

--Customer name contains consecutive spaces
EXEC usp_InsertCustomer
    @CustomerName = 'Thanishka  Reddy';

--Invalid Phone Number
EXEC usp_InsertCustomer
    @CustomerName = 'Lily',
    @PhoneNumber = '987654321';


--Invalid Phone Number
EXEC usp_InsertCustomer
    @CustomerName = 'Jake',
    @PhoneNumber = '98765432101';


--Phone number contains alphabets
EXEC usp_InsertCustomer
    @CustomerName = 'Ram',
    @PhoneNumber = '98765ABCDE';

--Phone number contains special characters
EXEC usp_InsertCustomer
    @CustomerName = 'John',
    @PhoneNumber = '98765-43210';

--Phone number is empty
EXEC usp_InsertCustomer
    @CustomerName = 'Mary',
    @PhoneNumber = '';

--Email without @
EXEC usp_InsertCustomer
    @CustomerName = 'Jim',
    @Email = 'jimgmail.com';

-- Email without username
EXEC usp_InsertCustomer
    @CustomerName = 'Kate',
    @Email = '@gmail.com';

--Email without domain
EXEC usp_InsertCustomer
    @CustomerName = 'Jim',
    @Email = 'Jim@';

--Email with spaces
EXEC usp_InsertCustomer
    @CustomerName = 'Jim',
    @Email = 'Jim @gmail.com';

--Invalid Email Format
EXEC usp_InsertCustomer
    @CustomerName = 'Jim',
    @Email = 'Jim@@gmail.com';

--Invalid DOB format
EXEC usp_InsertCustomer
    @CustomerName = 'Jake',
    @DateOfBirth = '25-11-2000';


--Invalid DOB
EXEC usp_InsertCustomer
    @CustomerName = 'Jake',
    @DateOfBirth = '2000-15-40';

--Future DOB
EXEC usp_InsertCustomer
    @CustomerName = 'Jake',
    @DateOfBirth = '2030-01-01';

--Future registration date
EXEC usp_InsertCustomer
    @CustomerName = 'Jake',
    @RegisteredDate = '2030-01-01';

--DOB later than registration date
EXEC usp_InsertCustomer
    @CustomerName = 'Jake',
    @DateOfBirth = '2005-01-01',
    @RegisteredDate = '2000-01-01';

--Invalid gender
EXEC usp_InsertCustomer
    @CustomerName = 'Jim',
    @Gender = 'Unknown';

--Invalid customer status
EXEC usp_InsertCustomer
    @CustomerName = 'Jim',
    @CustomerStatus = 'Pending';


--Customer status is NULL
EXEC usp_InsertCustomer
    @CustomerName = 'Jim',
    @CustomerStatus = NULL;

SELECT * FROM CUSTOMERS

