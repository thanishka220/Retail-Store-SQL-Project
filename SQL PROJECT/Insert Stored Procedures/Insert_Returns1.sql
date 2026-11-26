-----------------------Insert Returns-------------------------------------------
ALTER PROCEDURE usp_InsertReturn
    @ItemId VARCHAR(20) = NULL,
    @ReturnQuantity VARCHAR(20) = NULL,
    @Reason VARCHAR(255) = NULL,
    @ReturnStatus VARCHAR(30) = 'Pending'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TransactionStarted BIT = 0;

    BEGIN TRY

        DECLARE @ItemIDValue INT,
                @Quantity INT,
                @PurchasedQuantity INT,
                @PreviouslyReturned INT,
                @ItemPrice DECIMAL(10,2),
                @ReturnAmount DECIMAL(10,2);

        SET @ItemId = TRIM(@ItemId);
        SET @ReturnQuantity = TRIM(@ReturnQuantity);
        SET @Reason = NULLIF(TRIM(@Reason), '');
        SET @ReturnStatus = TRIM(@ReturnStatus);

        IF @ItemId IS NULL OR @ItemId = ''
        BEGIN
            PRINT 'Item ID is required.';
            RETURN;
        END

        IF @ReturnQuantity IS NULL OR @ReturnQuantity = ''
        BEGIN
            PRINT 'Return quantity is required.';
            RETURN;
        END

        IF @ReturnStatus IS NULL OR @ReturnStatus = ''
        BEGIN
            PRINT 'Return status is required.';
            RETURN;
        END

        SET @ItemIDValue = TRY_CONVERT(INT, @ItemId);
        SET @Quantity = TRY_CONVERT(INT, @ReturnQuantity);

        IF @ItemIDValue IS NULL OR @ItemIDValue <= 0
        BEGIN
            PRINT 'Enter a valid positive item ID.';
            RETURN;
        END

        IF @Quantity IS NULL OR @Quantity <= 0
        BEGIN
            PRINT 'Return quantity must be a positive integer.';
            RETURN;
        END

        IF @ReturnStatus NOT IN ('Pending', 'Approved', 'Rejected', 'Completed')
        BEGIN
            PRINT 'Invalid return status.';
            RETURN;
        END

        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransactionStarted = 1;
        END


        SELECT
            @PurchasedQuantity = OP.OrderQuantity,
            @ItemPrice = OP.ItemPrice
        FROM dbo.OrderProducts OP
        INNER JOIN dbo.Orders O
            ON O.OrderID = OP.OrderID
        WHERE OP.ItemID = @ItemIDValue
          AND O.OrderStatus = 'Completed';

        IF @PurchasedQuantity IS NULL
        BEGIN
            IF @TransactionStarted = 1
                ROLLBACK TRANSACTION;

            PRINT 'Item does not exist or its order is not completed.';
            RETURN;
        END


        SELECT
            @PreviouslyReturned = ISNULL(SUM(ReturnQuantity), 0)
        FROM dbo.Returns
        WHERE ItemID = @ItemIDValue
          AND ReturnStatus <> 'Rejected';


        IF @Quantity > (@PurchasedQuantity - @PreviouslyReturned)
        BEGIN
            IF @TransactionStarted = 1
                ROLLBACK TRANSACTION;

            PRINT 'Return quantity exceeds the remaining returnable quantity.';
            RETURN;
        END


        IF @ReturnStatus = 'Rejected'
            SET @ReturnAmount = 0;
        ELSE
            SET @ReturnAmount = @Quantity * @ItemPrice;


        INSERT INTO dbo.Returns
        (
            ItemID,
            ReturnQuantity,
            ReturnStatus,
            Reason,
            ReturnAmount
        )
        VALUES
        (
            @ItemIDValue,
            @Quantity,
            @ReturnStatus,
            @Reason,
            @ReturnAmount
        );

        IF @TransactionStarted = 1
            COMMIT TRANSACTION;

        PRINT 'Return inserted successfully.';

    END TRY

    BEGIN CATCH

        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT CONCAT('Error inserting return: ', ERROR_MESSAGE());
        PRINT CONCAT('Error Line: ', ERROR_LINE());
        PRINT CONCAT('Error Number: ', ERROR_NUMBER());

    END CATCH
END;



---------------------------------TestCases-----------------------------------

--Insert return with default status

EXEC usp_InsertReturn
    @ItemId = '3',
    @ReturnQuantity = '1',
    @Reason = 'Product damaged';




/*Return remaining purchased quantity
Previously returned = 1
Remaining returnable quantity = 1 */

EXEC usp_InsertReturn
    @ItemId = '3',
    @ReturnQuantity = '1',
    @Reason = 'Product not working'




--Insert return without optional reason

EXEC usp_InsertReturn
    @ItemId = '4',
    @ReturnQuantity = '1';

--ItemID NULL

EXEC usp_InsertReturn
    @ItemId = NULL,
    @ReturnQuantity = '1';



--ReturnQuantity NULL

EXEC usp_InsertReturn
    @ItemId = '3',
    @ReturnQuantity = NULL;




--ItemID empty

EXEC usp_InsertReturn
    @ItemId = '',
    @ReturnQuantity = '1';

--ReturnQuantity empty

EXEC dbo.usp_InsertReturn
    @ItemId = '3',
    @ReturnQuantity = '';

--ItemID contains alphabets

EXEC usp_InsertReturn
    @ItemId = 'ABC',
    @ReturnQuantity = '1';



--ItemID zero

EXEC usp_InsertReturn
    @ItemId = '0',
    @ReturnQuantity = '1';



--ItemID negative

EXEC usp_InsertReturn
    @ItemId = '-1',
    @ReturnQuantity = '1';




--ItemID does not exist

EXEC usp_InsertReturn
    @ItemId = '99999',
    @ReturnQuantity = '1';


--ReturnQuantity contains alphabets

EXEC usp_InsertReturn
    @ItemId = '3',
    @ReturnQuantity = 'ABC';


--ReturnQuantity contains special characters

EXEC usp_InsertReturn
    @ItemId = '3',
    @ReturnQuantity = '@#$';



--Return quantity is zero

EXEC usp_InsertReturn
    @ItemId = '3',
    @ReturnQuantity = '0';


-- RET15: Return quantity is negative

EXEC usp_InsertReturn
    @ItemId = '3',
    @ReturnQuantity = '-1';



------------------------------------------------------------
/* Return quantity exceeds purchased quantity
ItemID 4 purchased quantity = 1 */

EXEC usp_InsertReturn
    @ItemId = '4',
    @ReturnQuantity = '2';




/* Return more than remaining returnable quantity
Run after RET01 and RET02.
ItemID 3 purchased quantity = 2
 Already returned quantity = 2 */

EXEC usp_InsertReturn
    @ItemId = '3',
    @ReturnQuantity = '1';


--Invalid return status

EXEC usp_InsertReturn
    @ItemId = '4',
    @ReturnQuantity = '1',
    @Reason = 'Product Damaged',
    @ReturnStatus = 'Unknown';




--Empty return status

EXEC dbo.usp_InsertReturn
    @ItemId = '4',
    @ReturnQuantity = '1',
    @Reason = 'Product Damaged',
    @ReturnStatus = '';



--NULL return status

EXEC usp_InsertReturn
    @ItemId = '4',
    @ReturnQuantity = '1',
    @Reason = 'Product Damaged',
    @ReturnStatus = NULL;

SELECT * FROM Returns