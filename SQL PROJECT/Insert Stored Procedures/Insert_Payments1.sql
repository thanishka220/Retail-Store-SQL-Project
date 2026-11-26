------------------------Insert Payments------------------------------
ALTER PROCEDURE usp_InsertPayment
    @OrderId VARCHAR(20) = NULL,
    @PaymentMethod VARCHAR(30) = NULL,
    @PaymentStatus VARCHAR(30) = 'Pending',
    @PaymentAmount VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TransactionStarted BIT = 0;

    BEGIN TRY

        DECLARE @OrderIDValue INT,
                @Amount DECIMAL(10,2),
                @OrderTotal DECIMAL(12,2),
                @PaidAmount DECIMAL(12,2),
                @FailedAttempts INT,
                @StoreIDValue INT,
                @ItemCount INT;

        SET @OrderId = TRIM(@OrderId);
        SET @PaymentMethod = TRIM(@PaymentMethod);
        SET @PaymentStatus = TRIM(@PaymentStatus);
        SET @PaymentAmount = TRIM(@PaymentAmount);

        IF @OrderId IS NULL OR @OrderId = ''
        BEGIN
            PRINT 'Order ID is required.';
            RETURN;
        END

        IF @PaymentMethod IS NULL OR @PaymentMethod = ''
        BEGIN
            PRINT 'Payment method is required.';
            RETURN;
        END

        IF @PaymentStatus IS NULL OR @PaymentStatus = ''
        BEGIN
            PRINT 'Payment status is required.';
            RETURN;
        END

        IF @PaymentAmount IS NULL OR @PaymentAmount = ''
        BEGIN
            PRINT 'Payment amount is required.';
            RETURN;
        END


        SET @OrderIDValue = TRY_CONVERT(INT, @OrderId);
        SET @Amount = TRY_CONVERT(DECIMAL(10,2), @PaymentAmount);

        IF @OrderIDValue IS NULL OR @OrderIDValue <= 0
        BEGIN
            PRINT 'Enter a valid positive order ID.';
            RETURN;
        END

        IF @Amount IS NULL OR @Amount <= 0
        BEGIN
            PRINT 'Payment amount must be greater than zero.';
            RETURN;
        END


        IF @PaymentMethod NOT IN ('Cash', 'Card', 'UPI', 'NetBanking')
        BEGIN
            PRINT 'Invalid payment method.';
            RETURN;
        END

    

        IF @PaymentStatus NOT IN ('Pending', 'Completed', 'Failed')
        BEGIN
            PRINT 'Invalid payment status.';
            RETURN;
        END


        IF @@TRANCOUNT > 0
        BEGIN
            PRINT 'An existing transaction is open. Close it before executing this procedure.';
            RETURN;
        END

        BEGIN TRANSACTION;

        SET @TransactionStarted = 1;


        SELECT @StoreIDValue = StoreID
        FROM dbo.Orders
        WHERE OrderID = @OrderIDValue
          AND OrderStatus = 'Pending';

        IF @StoreIDValue IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @TransactionStarted = 0;

            PRINT 'Order does not exist or is not in Pending status.';
            RETURN;
        END


        SELECT
            @OrderTotal = SUM(
                CAST(OrderQuantity AS DECIMAL(12,2)) * ItemPrice
            ),
            @ItemCount = COUNT(*)
        FROM dbo.OrderProducts
        WHERE OrderID = @OrderIDValue;

        IF @ItemCount = 0 OR @OrderTotal IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @TransactionStarted = 0;

            PRINT 'Cannot process payment because the order has no products.';
            RETURN;
        END


        SELECT @PaidAmount = ISNULL(SUM(PaymentAmount), 0)
        FROM dbo.Payments
        WHERE OrderID = @OrderIDValue
          AND PaymentStatus = 'Completed';

  

        IF @PaymentStatus IN ('Pending', 'Completed')
           AND @Amount > (@OrderTotal - @PaidAmount)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @TransactionStarted = 0;

            PRINT 'Payment amount exceeds the remaining order balance.';
            RETURN;
        END


        INSERT INTO dbo.Payments
        (
            OrderID,
            PaymentMethod,
            PaymentStatus,
            PaymentAmount
        )
        VALUES
        (
            @OrderIDValue,
            @PaymentMethod,
            @PaymentStatus,
            @Amount
        );



        IF @PaymentStatus = 'Failed'
        BEGIN
            SELECT @FailedAttempts = COUNT(*)
            FROM dbo.Payments
            WHERE OrderID = @OrderIDValue
              AND PaymentStatus = 'Failed';

            IF @FailedAttempts >= 3
            BEGIN
                UPDATE dbo.Orders
                SET OrderStatus = 'Cancelled',
                    UpdatedAt = SYSDATETIME()
                WHERE OrderID = @OrderIDValue
                  AND OrderStatus = 'Pending';

                COMMIT TRANSACTION;
                SET @TransactionStarted = 0;

                PRINT 'Payment failed 3 times. Order cancelled.';
                RETURN;
            END

            COMMIT TRANSACTION;
            SET @TransactionStarted = 0;

            PRINT CONCAT('Payment failed. Attempt ', @FailedAttempts, ' of 3.');
            RETURN;
        END


        IF @PaymentStatus = 'Completed'
        BEGIN
            SET @PaidAmount = @PaidAmount + @Amount;

            IF @PaidAmount >= @OrderTotal
            BEGIN


                IF EXISTS
                (
                    SELECT 1
                    FROM dbo.OrderProducts OP
                    LEFT JOIN dbo.Inventory I
                        ON I.StoreID = @StoreIDValue
                       AND I.ProductID = OP.ProductID
                    WHERE OP.OrderID = @OrderIDValue
                      AND
                      (
                          I.InventoryID IS NULL
                          OR I.StockQuantity < OP.OrderQuantity
                      )
                )
                BEGIN
                    ROLLBACK TRANSACTION;
                    SET @TransactionStarted = 0;

                    PRINT 'Insufficient inventory. Payment requires reconciliation with the payment provider.';
                    RETURN;
                END

  

                UPDATE I
                SET I.StockQuantity = I.StockQuantity - OP.OrderQuantity,
                    I.UpdatedAt = SYSDATETIME()
                FROM dbo.Inventory I
                INNER JOIN dbo.OrderProducts OP
                    ON OP.ProductID = I.ProductID
                WHERE OP.OrderID = @OrderIDValue
                  AND I.StoreID = @StoreIDValue;


                UPDATE dbo.Orders
                SET OrderStatus = 'Completed',
                    UpdatedAt = SYSDATETIME()
                WHERE OrderID = @OrderIDValue;

                COMMIT TRANSACTION;
                SET @TransactionStarted = 0;

                PRINT 'Full payment completed. Inventory deducted and order marked Completed.';
                RETURN;
            END
        END

        COMMIT TRANSACTION;
        SET @TransactionStarted = 0;

        IF @PaymentStatus = 'Completed'
            PRINT 'Payment recorded successfully. Remaining balance is pending.';
        ELSE
            PRINT 'Payment recorded as Pending.';

    END TRY

    BEGIN CATCH

        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @TransactionStarted = 0;
        END

        PRINT CONCAT('Error inserting payment: ', ERROR_MESSAGE());
        PRINT CONCAT('Error Line: ', ERROR_LINE());
        PRINT CONCAT('Error Number: ', ERROR_NUMBER());

    END CATCH
END;


-----------------------------------TestCases-------------------------------------------
--Insert Pending payment
EXEC usp_InsertPayment
    @OrderId = '1',
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Pending',
    @PaymentAmount = '1000';


--Insert Failed payment
EXEC dbo.usp_InsertPayment
    @OrderId = '3',
    @PaymentMethod = 'Card',
    @PaymentStatus = 'Failed',
    @PaymentAmount = '500';


--Insert partial Completed payment
EXEC usp_InsertPayment
    @OrderId = '2',
    @PaymentMethod = 'Cash',
    @PaymentStatus = 'Completed',
    @PaymentAmount = '1000';


-- Pay remaining amount 

EXEC usp_InsertPayment
    @OrderId = '3',
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Completed',
    @PaymentAmount = '2000';

--Pay the full amount in one payment
EXEC usp_InsertPayment
    @OrderId = '3',
    @PaymentMethod = 'Cash',
    @PaymentStatus = 'Completed',
    @PaymentAmount = '5000';

--Order ID is NULL
EXEC usp_InsertPayment
    @OrderId = NULL,
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Pending',
    @PaymentAmount = '1000';

--Payment method is NULL
EXEC usp_InsertPayment
    @OrderId = '1',
    @PaymentMethod = NULL,
    @PaymentStatus = 'Pending',
    @PaymentAmount = '1000';


--Payment amount is NULL
EXEC dbo.usp_InsertPayment
    @OrderId = '1',
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Pending',
    @PaymentAmount = NULL;


--Order ID is empty
EXEC dbo.usp_InsertPayment
    @OrderId = '',
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Pending',
    @PaymentAmount = '1000';


--Order ID contains alphabets
EXEC dbo.usp_InsertPayment
    @OrderId = 'ABC',
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Pending',
    @PaymentAmount = '1000';


--Order ID is zero
EXEC usp_InsertPayment
    @OrderId = '0',
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Pending',
    @PaymentAmount = '1000';


--Order does not exist
EXEC usp_InsertPayment
    @OrderId = '99999',
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Pending',
    @PaymentAmount = '1000';


/* Insert Pending payment
Order 1 total = 117647.06 */

EXEC usp_InsertPayment
    @OrderId = '1',
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Pending',
    @PaymentAmount = '1000';



/*Full payment in one payment
Order 4 total = 3000
Store 2 has 30 units of Product 3 */

EXEC usp_InsertPayment
    @OrderId = '4',
    @PaymentMethod = 'Cash',
    @PaymentStatus = 'Completed',
    @PaymentAmount = '3000';


--Partial completed payment
EXEC usp_InsertPayment
    @OrderId = '5',
    @PaymentMethod = 'Card',
    @PaymentStatus = 'Completed',
    @PaymentAmount = '500'

-- Pay remaining amount
EXEC usp_InsertPayment
    @OrderId = '5',
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Completed',
    @PaymentAmount = '1000.50';

--OrderID NULL
EXEC usp_InsertPayment
    @OrderId = NULL,
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Pending',
    @PaymentAmount = '1000';


--PaymentMethod NULL

EXEC dbo.usp_InsertPayment
    @OrderId = '1',
    @PaymentMethod = NULL,
    @PaymentStatus = 'Pending',
    @PaymentAmount = '1000';




--PaymentStatus NULL

EXEC usp_InsertPayment
    @OrderId = '1',
    @PaymentMethod = 'UPI',
    @PaymentStatus = NULL,
    @PaymentAmount = '1000';

--PaymentAmount NULL

EXEC usp_InsertPayment
    @OrderId = '1',
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Pending',
    @PaymentAmount = NULL;

-- OrderID empty

EXEC usp_InsertPayment
    @OrderId = '',
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Pending',
    @PaymentAmount = '1000';

--PaymentMethod empty

EXEC usp_InsertPayment
    @OrderId = '1',
    @PaymentMethod = '',
    @PaymentStatus = 'Pending',
    @PaymentAmount = '1000';




--PaymentStatus empty

EXEC dbo.usp_InsertPayment
    @OrderId = '1',
    @PaymentMethod = 'UPI',
    @PaymentStatus = '',
    @PaymentAmount = '1000';



--PaymentAmount empty

EXEC dbo.usp_InsertPayment
    @OrderId = '1',
    @PaymentMethod = 'UPI',
    @PaymentStatus = 'Pending',
    @PaymentAmount = '';

SELECT * FROM Payments
SELECT * FROM Orders
SELECT * FROM Inventory