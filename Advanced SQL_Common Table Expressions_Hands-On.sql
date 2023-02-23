USE AdventureWorks2019

--Exercise: Subquery method

SELECT
	A.OrderMonth,
	A.TotalSales,
	B.TotalPurchases
FROM (
	SELECT
		OrderMonth,
		TotalSales = SUM(TotalDue)
	FROM (
		SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM AdventureWorks2019.Sales.SalesOrderHeader
		) S
	WHERE OrderRank > 10
	GROUP BY OrderMonth
) A
JOIN (
	SELECT
		OrderMonth,
		TotalPurchases = SUM(TotalDue)
	FROM (
		SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader
		) P
	WHERE OrderRank > 10
	GROUP BY OrderMonth
) B	ON A.OrderMonth = B.OrderMonth

--Exercise: CTE method

WITH Sales AS
(
	SELECT 
		OrderDate
		,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		,TotalDue
		,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
	FROM AdventureWorks2019.Sales.SalesOrderHeader
),
AvgSalesMinusTop10 AS
(
	SELECT
		OrderMonth,
		TotalSales = SUM(TotalDue)
	FROM Sales
	WHERE OrderRank > 10
	GROUP BY OrderMonth
),
Purchasing AS
(
	SELECT 
		OrderDate
		,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		,TotalDue
		,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
	FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader
),
AvgPurchasesMinusTop10 AS
(
	SELECT
		OrderMonth,
		TotalPurchases = SUM(TotalDue)
	FROM Purchasing
	WHERE OrderRank > 10
	GROUP BY OrderMonth
)

SELECT
	S.OrderMonth,
	S.TotalSales,
	P.TotalPurchases
FROM AvgSalesMinusTop10 S
JOIN AvgPurchasesMinusTop10 P
ON S.OrderMonth = P.OrderMonth
ORDER BY 1

--Exercise: Generate number series with recursive CTE

WITH NumberSeries AS
(
	SELECT
		1 AS MyNumber

	UNION ALL

	SELECT 
		MyNumber + 2
	FROM NumberSeries
	WHERE MyNumber < 100
)

SELECT
MyNumber
FROM NumberSeries

--Exercise: Generate date series with recursive CTE

WITH Dates AS
(
	SELECT
		CAST('01-01-2020' AS DATE) AS MyDate

	UNION ALL

	SELECT
		DATEADD(MONTH, 1, MyDate)
		FROM Dates
	WHERE MyDate < CAST('12-1-2029' AS DATE)
)

SELECT MyDate
FROM Dates
OPTION (MAXRECURSION 120) -- Override max recursion default of 100