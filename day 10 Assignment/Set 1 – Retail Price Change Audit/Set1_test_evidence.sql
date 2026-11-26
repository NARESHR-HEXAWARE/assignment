USE Day10Retail;
GO
INSERT dbo.product_price VALUES(1,100,150),(2,200,250),(3,300,350);
UPDATE dbo.product_price SET price=160 WHERE product_id=1;
UPDATE dbo.product_price SET price=price+20 WHERE product_id IN(1,2);
UPDATE dbo.product_price SET price=CASE WHEN product_id=1 THEN 90 ELSE 290 END WHERE product_id IN(1,2);
SELECT * FROM dbo.product_price ORDER BY product_id;
SELECT * FROM dbo.price_audit ORDER BY audit_id;
IF (SELECT price FROM dbo.product_price WHERE product_id=1)<>180 OR (SELECT price FROM dbo.product_price WHERE product_id=2)<>270 THROW 51000,'Price guard failed',1;
IF (SELECT COUNT(*) FROM dbo.price_audit WHERE outcome='ACCEPTED')<>3 OR (SELECT COUNT(*) FROM dbo.price_audit WHERE outcome='REJECTED')<>1 THROW 51001,'Audit failed',1;
PRINT 'Retail tests passed';
