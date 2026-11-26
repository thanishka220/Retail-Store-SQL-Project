--------------------------Insert OrderProducts-------------------------------
ALTER PROCEDURE usp_InsertOrderProduct
    @OrderId VARCHAR(20) = NULL,
    @ProductId VARCHAR(20) = NULL,
    @OrderQuantity VARCHAR(20) = NULL,
    @ItemPrice VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @OrderIDValue INT,
                @ProductIDValue INT,
                @Quantity INT,
                @Price DECIMAL(10,2),
                @StoreIDValue INT;

        SET @OrderId = TRIM(@OrderId);
        SET @ProductId = TRIM(@ProductId);
        SET @OrderQuantity = TRIM(@OrderQuantity);
        SET @ItemPrice = NULLIF(TRIM(@ItemPrice), '');

        IF @OrderId IS NULL OR @OrderId = ''
        BEGIN
            PRINT 'Order ID is required.';
            RETURN;
        END

        IF @ProductId IS NULL OR @ProductId = ''
        BEGIN
            PRINT 'Product ID is required.';
            RETURN;
        END

        IF @OrderQuantity IS NULL OR @OrderQuantity = ''
        BEGIN
            PRINT 'Order quantity is required.';
            RETURN;
        END

        SET @OrderIDValue = TRY_CONVERT(INT, @OrderId);
        SET @ProductIDValue = TRY_CONVERT(INT, @ProductId);
        SET @Quantity = TRY_CONVERT(INT, @OrderQuantity);

        IF @OrderIDValue IS NULL OR @OrderIDValue <= 0
        BEGIN
            PRINT 'Enter a valid positive order ID.';
            RETURN;
        END

        IF @ProductIDValue IS NULL OR @ProductIDValue <= 0
        BEGIN
            PRINT 'Enter a valid positive product ID.';
            RETURN;
        END

        IF @Quantity IS NULL OR @Quantity <= 0
        BEGIN
            PRINT 'Order quantity must be a positive integer.';
            RETURN;
        END

        IF @ItemPrice IS NOT NULL
        BEGIN
            SET @Price = TRY_CONVERT(DECIMAL(10,2), @ItemPrice);

            IF @Price IS NULL OR @Price < 0
            BEGIN
                PRINT 'Item price must be a valid non-negative amount.';
                RETURN;
            END
        END

        BEGIN TRANSACTION;

        SELECT @StoreIDValue = StoreID
        FROM dbo.Orders
        WHERE OrderID = @OrderIDValue
          AND OrderStatus = 'Pending';

        IF @StoreIDValue IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Order does not exist or is not in Pending status.';
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM dbo.Payments
            WHERE OrderID = @OrderIDValue
              AND PaymentStatus = 'Completed'
        )
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Products cannot be added after a successful payment.';
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
            ROLLBACK TRANSACTION;
            PRINT 'Product does not exist or its category is inactive.';
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM dbo.OrderProducts
            WHERE OrderID = @OrderIDValue
              AND ProductID = @ProductIDValue
        )
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'This product is already added to the order.';
            RETURN;
        END

        IF @Price IS NULL
        BEGIN
            SELECT @Price = SellingPrice
            FROM dbo.Products
            WHERE ProductID = @ProductIDValue;
        END

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Inventory
            WHERE StoreID = @StoreIDValue
              AND ProductID = @ProductIDValue
              AND StockQuantity >= @Quantity
        )
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Inventory record is missing or available stock is insufficient.';
            RETURN;
        END

        -- Insert order product
        INSERT INTO dbo.OrderProducts
        (
            OrderID,
            ProductID,
            OrderQuantity,
            ItemPrice
        )
        VALUES
        (
            @OrderIDValue,
            @ProductIDValue,
            @Quantity,
            @Price
        );

        COMMIT TRANSACTION;

        PRINT 'Order product inserted successfully.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT CONCAT('Error inserting order product: ', ERROR_MESSAGE());
        PRINT CONCAT('Error Line: ', ERROR_LINE());
        PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    END CATCH
END;

---------------------------------TestCases-----------------------------------
--Insert product with automatic ItemPrice
EXEC usp_InsertOrderProduct
    @OrderId = '3',
    @ProductId = '1',
    @OrderQuantity = '2';

--Insert product with manually supplied ItemPrice
EXEC usp_InsertOrderProduct
    @OrderId = '4',
    @ProductId = '3',
    @OrderQuantity = '2',
    @ItemPrice = '1500';


--Insert product with decimal ItemPrice
EXEC usp_InsertOrderProduct
    @OrderId = '5',
    @ProductId = '3',
    @OrderQuantity = '1',
    @ItemPrice = '1500.50';

--Product with zero ItemPrice
EXEC usp_InsertOrderProduct
    @OrderId = '6',
    @ProductId = '1',
    @OrderQuantity = '1',
    @ItemPrice = '0';

--Order ID is NULL
EXEC usp_InsertOrderProduct
    @OrderId = NULL,
    @ProductId = '1',
    @OrderQuantity = '2';


--Product ID is NULL
EXEC dbo.usp_InsertOrderProduct
    @OrderId = '7',
    @ProductId = NULL,
    @OrderQuantity = '2';


--Quantity is NULL
EXEC dbo.usp_InsertOrderProduct
    @OrderId = '7',
    @ProductId = '1',
    @OrderQuantity = NULL;


--Order ID contains alphabets
EXEC dbo.usp_InsertOrderProduct
    @OrderId = 'ABC',
    @ProductId = '1',
    @OrderQuantity = '2';


--Product ID contains alphabets
EXEC dbo.usp_InsertOrderProduct
    @OrderId = '7',
    @ProductId = 'XYZ',
    @OrderQuantity = '2';


--Quantity contains alphabets
EXEC dbo.usp_InsertOrderProduct
    @OrderId = '7',
    @ProductId = '1',
    @OrderQuantity = 'Two';


--Quantity is zero
EXEC dbo.usp_InsertOrderProduct
    @OrderId = '7',
    @ProductId = '1',
    @OrderQuantity = '0';


--Quantity is negative
EXEC dbo.usp_InsertOrderProduct
    @OrderId = '7',
    @ProductId = '1',
    @OrderQuantity = '-2';


--Quantity contains decimal
EXEC dbo.usp_InsertOrderProduct
    @OrderId = '7',
    @ProductId = '1',
    @OrderQuantity = '2.5';


--Order does not exist
EXEC dbo.usp_InsertOrderProduct
    @OrderId = '99999',
    @ProductId = '1',
    @OrderQuantity = '2';


--Product does not exist
EXEC usp_InsertOrderProduct
    @OrderId = '7',
    @ProductId = '99999',
    @OrderQuantity = '2';

SELECT * FROM OrderProducts