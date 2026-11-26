---------------------Insert Stores----------------------------------
ALTER PROCEDURE usp_InsertStore
    @StoreName VARCHAR(150) = NULL,
    @City VARCHAR(100) = NULL,
    @State VARCHAR(100) = NULL,
    @StoreStatus VARCHAR(20) = 'Active'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SET @StoreName = TRIM(@StoreName);
        SET @City = TRIM(@City);
        SET @State = TRIM(@State);
        SET @StoreStatus = TRIM(@StoreStatus);

        IF @StoreName IS NULL OR @StoreName = ''
        BEGIN
            PRINT 'Store name is required.';
            RETURN;
        END

        IF @City IS NULL OR @City = ''
        BEGIN
            PRINT 'City is required.';
            RETURN;
        END

        IF @State IS NULL OR @State = ''
        BEGIN
            PRINT 'State is required.';
            RETURN;
        END

        IF @StoreStatus IS NULL OR @StoreStatus = ''
        BEGIN
            PRINT 'Store status is required.';
            RETURN;
        END

        IF LEN(REPLACE(@StoreName, ' ', '')) < 3
           OR @StoreName LIKE '%[^A-Za-z ]%'
           OR @StoreName LIKE '%  %'
        BEGIN
            PRINT 'Store name must contain at least 3 letters and only single spaces.';
            RETURN;
        END

        IF LEN(REPLACE(@City, ' ', '')) < 3
           OR @City LIKE '%[^A-Za-z ]%'
           OR @City LIKE '%  %'
        BEGIN
            PRINT 'City must contain at least 3 letters and only single spaces.';
            RETURN;
        END

        IF LEN(REPLACE(@State, ' ', '')) < 3
           OR @State LIKE '%[^A-Za-z ]%'
           OR @State LIKE '%  %'
        BEGIN
            PRINT 'State must contain at least 3 letters and only single spaces.';
            RETURN;
        END

        IF @StoreStatus NOT IN ('Active', 'Inactive')
        BEGIN
            PRINT 'Invalid store status. Use Active or Inactive.';
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM dbo.Stores
            WHERE LOWER(TRIM(StoreName)) = LOWER(@StoreName)
        )
        BEGIN
            PRINT 'A store with this name already exists.';
            RETURN;
        END

        INSERT INTO dbo.Stores
        (
            StoreName,
            City,
            State,
            StoreStatus
        )
        VALUES
        (
            @StoreName,
            @City,
            @State,
            @StoreStatus
        );

        PRINT 'Store inserted successfully.';

    END TRY
    BEGIN CATCH

        PRINT CONCAT('Error inserting store: ', ERROR_MESSAGE());
        PRINT CONCAT('Error Line: ', ERROR_LINE());
        PRINT CONCAT('Error Number: ', ERROR_NUMBER());

    END CATCH
END;

------------------------------TestCases------------------------------
-- Insert store with all valid values
EXEC usp_InsertStore
    @StoreName = 'Central Mall',
    @City = 'Hyderabad',
    @State = 'Telangana',
    @StoreStatus = 'Active';

-- Insert store without status
EXEC usp_InsertStore
    @StoreName = 'City Center',
    @City = 'Hyderabad',
    @State = 'Telangana';

--Insert store with Inactive status
EXEC usp_InsertStore
    @StoreName = 'West Mall',
    @City = 'Chennai',
    @State = 'Tamil Nadu',
    @StoreStatus = 'Inactive';

--Leading and trailing spaces
EXEC usp_InsertStore
    @StoreName = '  North Plaza  ',
    @City = '  Hyderabad  ',
    @State = '  Telangana  ',
    @StoreStatus = ' Active ';

--Store name is NULL
EXEC usp_InsertStore
    @StoreName = NULL,
    @City = 'Hyderabad',
    @State = 'Telangana';

--Store name is empty
EXEC usp_InsertStore
    @StoreName = '',
    @City = 'Hyderabad',
    @State = 'Telangana';

--Store name contains only spaces
EXEC usp_InsertStore
    @StoreName = '   ',
    @City = 'Hyderabad',
    @State = 'Telangana';

--Store name has fewer than 3 letters
EXEC usp_InsertStore
    @StoreName = 'AB',
    @City = 'Hyderabad',
    @State = 'Telangana';

--Store name contains numbers
EXEC usp_InsertStore
    @StoreName = 'Mall123',
    @City = 'Hyderabad',
    @State = 'Telangana';

--Store name contains special characters
EXEC usp_InsertStore
    @StoreName = 'Mall@City',
    @City = 'Hyderabad',
    @State = 'Telangana';

--Store name contains consecutive spaces
EXEC usp_InsertStore
    @StoreName = 'Central  Mall',
    @City = 'Hyderabad',
    @State = 'Telangana';

--Duplicate store name
EXEC usp_InsertStore
    @StoreName = 'Central Mall',
    @City = 'Hyderabad',
    @State = 'Telangana';

--City is NULL
EXEC usp_InsertStore
    @StoreName = 'New Store One',
    @City = NULL,
    @State = 'Telangana';


--State is NULL
EXEC usp_InsertStore
    @StoreName = 'New Store Two',
    @City = 'Hyderabad',
    @State = NULL;

--Invalid store status
EXEC usp_InsertStore
    @StoreName = 'New Store Three',
    @City = 'Hyderabad',
    @State = 'Telangana',
    @StoreStatus = 'Pending';


--Store status is empty
EXEC usp_InsertStore
    @StoreName = 'New Store Four',
    @City = 'Hyderabad',
    @State = 'Telangana',
    @StoreStatus = '';

-- Store status is NULL
EXEC usp_InsertStore
    @StoreName = 'New Store Five',
    @City = 'Hyderabad',
    @State = 'Telangana',
    @StoreStatus = NULL;

SELECT * FROM Stores


