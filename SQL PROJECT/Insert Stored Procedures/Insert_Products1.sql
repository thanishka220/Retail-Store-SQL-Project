-------------------------Insert Product-----------------------
ALTER PROCEDURE usp_InsertProduct
    @CategoryId VARCHAR(20) = NULL,
    @ProductName VARCHAR(150) = NULL,
    @CostPrice VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @CategoryIDValue INT,
                @Cost DECIMAL(10,2),
                @Selling DECIMAL(10,2);

        SET @CategoryId = TRIM(@CategoryId);
        SET @ProductName = NULLIF(TRIM(@ProductName), '');
        SET @CostPrice = TRIM(@CostPrice);

   
        IF @CategoryId IS NULL OR @CategoryId = ''
        BEGIN
            PRINT 'Category ID is required.';
            RETURN;
        END

        IF @ProductName IS NULL
        BEGIN
            PRINT 'Product name is required.';
            RETURN;
        END

        IF @CostPrice IS NULL OR @CostPrice = ''
        BEGIN
            PRINT 'Cost price is required.';
            RETURN;
        END

        SET @CategoryIDValue = TRY_CONVERT(INT, @CategoryId);
        SET @Cost = TRY_CONVERT(DECIMAL(10,2), @CostPrice);


        IF @CategoryIDValue IS NULL OR @CategoryIDValue <= 0
        BEGIN
            PRINT 'Enter a valid positive category ID.';
            RETURN;
        END

        IF @Cost IS NULL OR @Cost < 0
        BEGIN
            PRINT 'Enter a valid cost price.';
            RETURN;
        END


        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Categories
            WHERE CategoryID = @CategoryIDValue
        )
        BEGIN
            PRINT 'Category does not exist.';
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM dbo.Categories
            WHERE CategoryID = @CategoryIDValue
              AND CategoryStatus = 'Inactive'
        )
        BEGIN
            PRINT 'Cannot add products to an inactive category.';
            RETURN;
        END


        IF EXISTS
        (
            SELECT 1
            FROM dbo.Products
            WHERE CategoryID = @CategoryIDValue
              AND LOWER(TRIM(ProductName)) = LOWER(@ProductName)
        )
        BEGIN
            PRINT 'Product already exists in this category.';
            RETURN;
        END

        SET @Selling = ROUND(@Cost / 0.85, 2);

        INSERT INTO dbo.Products
        (
            CategoryID,
            ProductName,
            CostPrice,
            SellingPrice
        )
        VALUES
        (
            @CategoryIDValue,
            @ProductName,
            @Cost,
            @Selling
        );

        PRINT 'Product inserted successfully.';
        PRINT CONCAT('Calculated Selling Price: ', @Selling);

    END TRY

    BEGIN CATCH

        PRINT 'Product insertion failed.';
        PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
        PRINT CONCAT('Error Line: ', ERROR_LINE());
        PRINT CONCAT('Error Number: ', ERROR_NUMBER());

    END CATCH
END;

---------------------------TestCases----------------------------------
--Insert product with valid values
EXEC usp_InsertProduct
    @CategoryId = '1',
    @ProductName = 'Laptop',
    @CostPrice = '50000';

EXEC usp_InsertProduct
    @CategoryId = '1',
    @ProductName = 'Mobile Phone',
    @CostPrice = '20000';

--Insert product with decimal cost price
EXEC usp_InsertProduct
    @CategoryId = '1',
    @ProductName = 'Wireless Speaker',
    @CostPrice = '1500.50';

--Insert product with zero cost price
EXEC usp_InsertProduct
    @CategoryId = '1',
    @ProductName = 'Free Sample',
    @CostPrice = '0';


--Adding Product in an invalidategory
EXEC usp_InsertProduct
    @CategoryId = '3',
    @ProductName = 'Laptop',
    @CostPrice = '45000';

    -- PR06: Category ID is NULL
EXEC dbo.usp_InsertProduct
    @CategoryId = NULL,
    @ProductName = 'Keyboard',
    @CostPrice = '1000';
GO

--Category ID is empty
EXEC dbo.usp_InsertProduct
    @CategoryId = '',
    @ProductName = 'Keyboard',
    @CostPrice = '1000';

--Category ID contains alphabets
EXEC dbo.usp_InsertProduct
    @CategoryId = 'ABC',
    @ProductName = 'Keyboard',
    @CostPrice = '1000';

--Category ID is zero
EXEC usp_InsertProduct
    @CategoryId = '0',
    @ProductName = 'Keyboard',
    @CostPrice = '1000';


--Category does not exist
EXEC dbo.usp_InsertProduct
    @CategoryId = '99999',
    @ProductName = 'Keyboard',
    @CostPrice = '1000';

--Product name is NULL
EXEC dbo.usp_InsertProduct
    @CategoryId = '1',
    @ProductName = NULL,
    @CostPrice = '1000';


--Product name contains only spaces
EXEC dbo.usp_InsertProduct
    @CategoryId = '1',
    @ProductName = '   ',
    @CostPrice = '1000';

--Cost price is NULL
EXEC dbo.usp_InsertProduct
    @CategoryId = '1',
    @ProductName = 'Mouse',
    @CostPrice = NULL;


--Cost price is empty
EXEC dbo.usp_InsertProduct
    @CategoryId = '1',
    @ProductName = 'Mouse',
    @CostPrice = '';

--Cost price contains alphabets
EXEC dbo.usp_InsertProduct
    @CategoryId = '1',
    @ProductName = 'Mouse',
    @CostPrice = 'OneThousand';

--Cost price contains special characters
EXEC usp_InsertProduct
    @CategoryId = '1',
    @ProductName = 'Mouse',
    @CostPrice = '1000@';


--Negative cost price
EXEC usp_InsertProduct
    @CategoryId = '1',
    @ProductName = 'Mouse',
    @CostPrice = '-100';


--Duplicate product in same category
EXEC usp_InsertProduct
    @CategoryId = '1',
    @ProductName = 'Laptop',
    @CostPrice = '40000';

--Cost price exceeds range
EXEC usp_InsertProduct
    @CategoryId = '1',
    @ProductName = 'AC',
    @CostPrice = '999999999';

SELECT * FROM Products