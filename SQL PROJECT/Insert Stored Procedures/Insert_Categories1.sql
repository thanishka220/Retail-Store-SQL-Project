--------------------Insert Categories-------------------------
ALTER PROCEDURE dbo.usp_InsertCategory
    @CategoryName VARCHAR(100) = NULL,
    @CategoryStatus VARCHAR(20) = 'Active'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @CategoryName = TRIM(@CategoryName);
        SET @CategoryStatus = TRIM(@CategoryStatus);

        IF @CategoryName IS NULL OR @CategoryName = ''
        BEGIN
            PRINT 'Category name is required.';
            RETURN;
        END

        IF @CategoryStatus IS NULL OR @CategoryStatus = ''
        BEGIN
            PRINT 'Category status is required.';
            RETURN;
        END

        IF LEN(REPLACE(@CategoryName, ' ', '')) < 3
           OR @CategoryName LIKE '%[^A-Za-z ]%'
           OR @CategoryName LIKE '%  %'
        BEGIN
            PRINT 'Category name must contain at least 3 letters and only single spaces.';
            RETURN;
        END

        IF @CategoryStatus NOT IN ('Active', 'Inactive')
        BEGIN
            PRINT 'Invalid category status. Use Active or Inactive.';
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM dbo.Categories
            WHERE LOWER(TRIM(CategoryName)) = LOWER(@CategoryName)
        )
        BEGIN
            PRINT 'This category already exists.';
            RETURN;
        END

        INSERT INTO dbo.Categories
        (
            CategoryName,
            CategoryStatus
        )
        VALUES
        (
            @CategoryName,
            @CategoryStatus
        );

        PRINT 'Category inserted successfully.';

    END TRY
    BEGIN CATCH
        PRINT CONCAT('Error inserting category: ', ERROR_MESSAGE());
        PRINT CONCAT('Error Line: ', ERROR_LINE());
        PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    END CATCH
END;

------------------------------TestCases------------------------------------
--Insert valid category
EXEC usp_InsertCategory
    @CategoryName = 'Electronics',
    @CategoryStatus = 'Active';

--Insert without status
EXEC dbo.usp_InsertCategory
    @CategoryName = 'Furniture';

-- Insert Inactive category
EXEC usp_InsertCategory
    @CategoryName = 'Stationery',
    @CategoryStatus = 'Inactive';

--Leading and trailing spaces
EXEC usp_InsertCategory
    @CategoryName = '  Home Appliances  ',
    @CategoryStatus = ' Active ';

--Category name is NULL
EXEC dbo.usp_InsertCategory
    @CategoryName = NULL;

--Category name is empty
EXEC usp_InsertCategory
    @CategoryName = '';

--Category name contains only spaces
EXEC usp_InsertCategory
    @CategoryName = '   ';

--Category name has fewer than 3 letters
EXEC dbo.usp_InsertCategory
    @CategoryName = 'AB';

--Category name contains numbers
EXEC usp_InsertCategory
    @CategoryName = 'Electronics123';

--Category name contains special characters
EXEC usp_InsertCategory
    @CategoryName = 'Electronics@';

--Category name contains consecutive spaces
EXEC usp_InsertCategory
    @CategoryName = 'Home  Appliances';

--Duplicate category
EXEC dbo.usp_InsertCategory
    @CategoryName = 'Electronics';

--Duplicate category with different case
EXEC usp_InsertCategory
    @CategoryName = 'electronics';

--Invalid category status
EXEC usp_InsertCategory
    @CategoryName = 'Sports',
    @CategoryStatus = 'Pending';

--Category status is empty
EXEC usp_InsertCategory
    @CategoryName = 'Toys',
    @CategoryStatus = '';

--Category status is NULL
EXEC usp_InsertCategory
    @CategoryName = 'Books',
    @CategoryStatus = NULL;

--Category Name is not passed
EXEC usp_InsertCategory

SELECT * FROM Categories