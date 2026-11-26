-----------------------Insert Inventory-------------------------
ALTER PROCEDURE usp_InsertInventory
    @StoreId VARCHAR(20) = NULL,
    @ProductId VARCHAR(20) = NULL,
    @StockQuantity VARCHAR(20) = NULL,
    @ReorderLevel VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @StoreIDValue INT,
                @ProductIDValue INT,
                @Stock INT,
                @Reorder INT

        SET @StoreId = TRIM(@StoreId);
        SET @ProductId = TRIM(@ProductId);
        SET @StockQuantity = TRIM(@StockQuantity);
        SET @ReorderLevel = TRIM(@ReorderLevel);

        IF @StoreId IS NULL OR @StoreId = ''
        BEGIN
            PRINT 'Store ID is required.';
            RETURN;
        END

        IF @ProductId IS NULL OR @ProductId = ''
        BEGIN
            PRINT 'Product ID is required.';
            RETURN;
        END

        IF @StockQuantity IS NULL OR @StockQuantity = ''
        BEGIN
            PRINT 'Stock quantity is required.';
            RETURN;
        END

        IF @ReorderLevel IS NULL OR @ReorderLevel = ''
        BEGIN
            PRINT 'Reorder level is required.';
            RETURN;
        END

        SET @StoreIDValue = TRY_CONVERT(INT, @StoreId);
        SET @ProductIDValue = TRY_CONVERT(INT, @ProductId);
        SET @Stock = TRY_CONVERT(INT, @StockQuantity);
        SET @Reorder = TRY_CONVERT(INT, @ReorderLevel);

        IF @StoreIDValue IS NULL OR @StoreIDValue <= 0
        BEGIN
            PRINT 'Enter a valid positive store ID.';
            RETURN;
        END

        IF @ProductIDValue IS NULL OR @ProductIDValue <= 0
        BEGIN
            PRINT 'Enter a valid positive product ID.';
            RETURN;
        END

        IF @Stock IS NULL OR @Stock < 0
        BEGIN
            PRINT 'Stock quantity must be a valid non-negative integer.';
            RETURN;
        END

        IF @Reorder IS NULL OR @Reorder < 0
        BEGIN
            PRINT 'Reorder level must be a valid non-negative integer.';
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
            FROM dbo.Products P
            INNER JOIN dbo.Categories C
                ON C.CategoryID = P.CategoryID
            WHERE P.ProductID = @ProductIDValue
              AND C.CategoryStatus = 'Active'
        )
        BEGIN
            PRINT 'Product does not exist or its category is inactive.';
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM dbo.Inventory
            WHERE StoreID = @StoreIDValue
              AND ProductID = @ProductIDValue
        )
        BEGIN
            PRINT 'Inventory already exists for this store and product.';
            RETURN;
        END

        BEGIN TRANSACTION;

        INSERT INTO dbo.Inventory
        (
            StoreID,
            ProductID,
            StockQuantity,
            ReorderLevel
        )
        VALUES
        (
            @StoreIDValue,
            @ProductIDValue,
            @Stock,
            @Reorder
        );

        COMMIT TRANSACTION;

        PRINT 'Inventory inserted successfully.';

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'Error occurred while inserting inventory.';
        PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
        PRINT CONCAT('Error Line: ', ERROR_LINE());
        PRINT CONCAT('Error Number: ', ERROR_NUMBER());

    END CATCH
END;

--------------------------------TestCases---------------------------------
--Insert valid inventory
EXEC usp_InsertInventory
    @StoreId = '2',
    @ProductId = '1',
    @StockQuantity = '50',
    @ReorderLevel = '10';

--Insert zero stock
EXEC usp_InsertInventory
    @StoreId = '2',
    @ProductId = '2',
    @StockQuantity = '0',
    @ReorderLevel = '10';

--Insert zero reorder level
EXEC usp_InsertInventory
    @StoreId = '3',
    @ProductId = '3',
    @StockQuantity = '50',
    @ReorderLevel = '0';

--Insert both quantities as zero
EXEC usp_InsertInventory
    @StoreId = '2',
    @ProductId = '4',
    @StockQuantity = '0',
    @ReorderLevel = '0';

--Store ID is NULL
EXEC usp_InsertInventory
    @StoreId = NULL,
    @ProductId = '1',
    @StockQuantity = '50',
    @ReorderLevel = '10';


-- INV06: Product ID is NULL
EXEC usp_InsertInventory
    @StoreId = '2',
    @ProductId = NULL,
    @StockQuantity = '50',
    @ReorderLevel = '10';


--Stock quantity is NULL
EXEC dbo.usp_InsertInventory
    @StoreId = '2',
    @ProductId = '1',
    @StockQuantity = NULL,
    @ReorderLevel = '10';


--Reorder level is NULL
EXEC usp_InsertInventory
    @StoreId = '1',
    @ProductId = '1',
    @StockQuantity = '50',
    @ReorderLevel = NULL;


--Store ID is empty
EXEC usp_InsertInventory
    @StoreId = '',
    @ProductId = '1',
    @StockQuantity = '50',
    @ReorderLevel = '10';

--Product ID contains alphabets
EXEC usp_InsertInventory
    @StoreId = '1',
    @ProductId = 'ABC',
    @StockQuantity = '50',
    @ReorderLevel = '10';


--Stock quantity contains alphabets
EXEC usp_InsertInventory
    @StoreId = '1',
    @ProductId = '1',
    @StockQuantity = 'Fifty',
    @ReorderLevel = '10';

--Reorder level contains alphabets
EXEC usp_InsertInventory
    @StoreId = '1',
    @ProductId = '1',
    @StockQuantity = '50',
    @ReorderLevel = 'Ten';


--Store ID is zero
EXEC usp_InsertInventory
    @StoreId = '0',
    @ProductId = '1',
    @StockQuantity = '50',
    @ReorderLevel = '10';

--Product ID is negative
EXEC usp_InsertInventory
    @StoreId = '1',
    @ProductId = '-1',
    @StockQuantity = '50',
    @ReorderLevel = '10';


--Negative stock quantity
EXEC usp_InsertInventory
    @StoreId = '1',
    @ProductId = '1',
    @StockQuantity = '-10',
    @ReorderLevel = '10';


--Negative reorder level
EXEC usp_InsertInventory
    @StoreId = '2',
    @ProductId = '1',
    @StockQuantity = '50',
    @ReorderLevel = '-5';

--Stock quantity contains decimal
EXEC usp_InsertInventory
    @StoreId = '1',
    @ProductId = '1',
    @StockQuantity = '10.5',
    @ReorderLevel = '10';


--Reorder level contains decimal
EXEC usp_InsertInventory
    @StoreId = '1',
    @ProductId = '1',
    @StockQuantity = '50',
    @ReorderLevel = '5.5';


--Store does not exist
EXEC usp_InsertInventory
    @StoreId = '99999',
    @ProductId = '1',
    @StockQuantity = '50',
    @ReorderLevel = '10';


--Product does not exist
EXEC usp_InsertInventory
    @StoreId = '2',
    @ProductId = '99999',
    @StockQuantity = '50',
    @ReorderLevel = '10';

--Store is Inactive
EXEC usp_InsertInventory
    @StoreId = '1',
    @ProductId = '1',
    @StockQuantity = '50',
    @ReorderLevel = '10';

--Duplicate inventory
EXEC dbo.usp_InsertInventory
    @StoreId = '2',
    @ProductId = '1',
    @StockQuantity = '100',
    @ReorderLevel = '20';

SELECT * FROM Inventory