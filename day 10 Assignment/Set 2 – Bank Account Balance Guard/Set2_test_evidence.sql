USE Day10Bank;
GO
INSERT dbo.accounts VALUES(1,'Savings',100),(2,'Savings',200),(3,'Savings',300),(4,'Savings',400),(5,'Savings',500);
INSERT dbo.account_transaction VALUES(101,1,25),(102,2,50);
UPDATE dbo.account_transaction SET amount=amount+5 WHERE transaction_id IN(101,102);
DELETE dbo.account_transaction WHERE transaction_id=102;
BEGIN TRY
 UPDATE dbo.v_accounts SET balance=CASE WHEN account_id=3 THEN -1 ELSE balance+10 END;
 THROW 51010,'Expected failure did not occur',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>50012 THROW;
 SELECT ERROR_MESSAGE() AS expected_error;
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.accounts WHERE balance<>account_id*100) THROW 51011,'Batch was not atomic',1;
UPDATE dbo.v_accounts SET balance=balance+10;
IF (SELECT COUNT(*) FROM dbo.balance_audit)<>5 THROW 51012,'Balance audit failed',1;
IF (SELECT COUNT(*) FROM dbo.transaction_audit)<>5 THROW 51013,'Transaction audit failed',1;
INSERT dbo.recursion_demo VALUES(1,0);
UPDATE dbo.recursion_demo SET n=10 WHERE id=1;
SELECT * FROM dbo.recursion_demo; -- 11: recursive invocation stops at guard
SELECT * FROM dbo.accounts;
SELECT * FROM dbo.transaction_audit;
SELECT * FROM dbo.balance_audit;
PRINT 'Bank tests passed';
