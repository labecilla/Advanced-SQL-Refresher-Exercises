USE AdventureWorks2019
GO

--Exercise: Select and insert data into temp tables.
SELECT 
	OrderDate
	,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
	,TotalDue
	,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
INTO #Sales
FROM AdventureWorks2019.Sales.SalesOrderHeader

SELECT
	OrderMonth,
	TotalSales = SUM(TotalDue)
INTO #AvgSalesMinusTop10
FROM #Sales
WHERE OrderRank > 10
GROUP BY OrderMonth

SELECT 
	OrderDate
	,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
	,TotalDue
	,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
INTO #Purchasing
FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader

SELECT
	OrderMonth,
	TotalPurchases = SUM(TotalDue)
INTO #AvgPurchasesMinusTop10
FROM #Purchasing
WHERE OrderRank > 10
GROUP BY OrderMonth

SELECT
	S.OrderMonth,
	S.TotalSales,
	P.TotalPurchases
FROM #AvgSalesMinusTop10 S
JOIN #AvgPurchasesMinusTop10 P
ON S.OrderMonth = P.OrderMonth
ORDER BY 1

DROP TABLE #AvgPurchasesMinusTop10
DROP TABLE #AvgSalesMinusTop10
DROP TABLE #Purchasing
DROP TABLE #Sales


--Exercise: Create temp tables and insert data

CREATE TABLE #Sales
(
	OrderDate DATE,
	OrderMonth DATE,
	TotalDue MONEY,
	OrderRank INT
)
INSERT INTO #Sales
SELECT 
	OrderDate
	,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
	,TotalDue
	,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
FROM AdventureWorks2019.Sales.SalesOrderHeader

CREATE TABLE #AvgSalesMinusTop10
(
	OrderMonth DATE,
	TotalSales MONEY
)

INSERT INTO #AvgSalesMinusTop10
SELECT
	OrderMonth,
	TotalSales = SUM(TotalDue)
FROM #Sales
WHERE OrderRank > 10
GROUP BY OrderMonth

CREATE TABLE #Purchasing
(
	OrderDate DATE,
	OrderMonth DATE,
	TotalDue MONEY,
	OrderRank INT
)
INSERT INTO #Purchasing
SELECT 
	OrderDate
	,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
	,TotalDue
	,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader

CREATE TABLE #AvgPurchasesMinusTop10
(
	OrderMonth DATE,
	TotalPurchases MONEY
)

INSERT INTO #AvgPurchasesMinusTop10
SELECT
	OrderMonth,
	TotalPurchases = SUM(TotalDue)
FROM #Purchasing
WHERE OrderRank > 10
GROUP BY OrderMonth

SELECT
	S.OrderMonth,
	S.TotalSales,
	P.TotalPurchases
FROM #AvgSalesMinusTop10 S
JOIN #AvgPurchasesMinusTop10 P
ON S.OrderMonth = P.OrderMonth
ORDER BY 1

DROP TABLE #AvgPurchasesMinusTop10
DROP TABLE #AvgSalesMinusTop10
DROP TABLE #Purchasing
DROP TABLE #Sales

--Exercise: TRUNCATE table

CREATE TABLE #Orders
(
	OrderDate DATE,
	OrderMonth DATE,
	TotalDue MONEY,
	OrderRank INT
)
INSERT INTO #Orders
SELECT 
	OrderDate
	,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
	,TotalDue
	,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
FROM AdventureWorks2019.Sales.SalesOrderHeader

CREATE TABLE #OrdersMinusTop10
(
	OrderMonth DATE,
	Total MONEY,
	[Type] VARCHAR(50)
)

INSERT INTO #OrdersMinusTop10
SELECT
	OrderMonth,
	Total = SUM(TotalDue),
	[Type] = 'Sales'
FROM #Orders
WHERE OrderRank > 10
GROUP BY OrderMonth

TRUNCATE TABLE #Orders

INSERT INTO #Orders
SELECT 
	OrderDate
	,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
	,TotalDue
	,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader

INSERT INTO #OrdersMinusTop10
SELECT
	OrderMonth,
	Total = SUM(TotalDue),
	[Type] = 'Purchases'
FROM #Orders
WHERE OrderRank > 10
GROUP BY OrderMonth

SELECT * FROM #OrdersMinusTop10

--Exercise: Update temp tables

CREATE TABLE #SalesOrders
(
 SalesOrderID INT,
 OrderDate DATE,
 TaxAmt MONEY,
 Freight MONEY,
 TotalDue MONEY,
 TaxFreightPercent FLOAT,
 TaxFreightBucket VARCHAR(32),
 OrderAmtBucket VARCHAR(32),
 OrderCategory VARCHAR(32),
 OrderSubcategory VARCHAR(32)
)

INSERT INTO #SalesOrders
(
 SalesOrderID,
 OrderDate,
 TaxAmt,
 Freight,
 TotalDue,
 OrderCategory
)

SELECT
 SalesOrderID,
 OrderDate,
 TaxAmt,
 Freight,
 TotalDue,
 OrderCategory = 'Non-holiday Order'
FROM [AdventureWorks2019].[Sales].[SalesOrderHeader]
WHERE YEAR(OrderDate) = 2013

UPDATE #SalesOrders
SET 
TaxFreightPercent = (TaxAmt + Freight)/TotalDue,
OrderAmtBucket = 
	CASE
		WHEN TotalDue < 100 THEN 'Small'
		WHEN TotalDue < 1000 THEN 'Medium'
		ELSE 'Large'
	END

UPDATE #SalesOrders
SET TaxFreightBucket = 
	CASE
		WHEN TaxFreightPercent < 0.1 THEN 'Small'
		WHEN TaxFreightPercent < 0.2 THEN 'Medium'
		ELSE 'Large'
	END

UPDATE #SalesOrders
SET  OrderCategory = 'Holiday'
FROM #SalesOrders
WHERE DATEPART(quarter,OrderDate) = 4

UPDATE #SalesOrders
SET OrderSubcategory = OrderCategory+' '+'-'+' '+OrderAmtBucket

SELECT * FROM #SalesOrders