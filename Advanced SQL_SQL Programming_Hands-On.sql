--Exercise: Variables in SQL

DECLARE @MaxVacationHours INT = (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee)
SELECT
	   BusinessEntityID,
	   JobTitle,
	   VacationHours,
	   MaxVacationHours = @MaxVacationHours,
	   PercentOfMaxVacationHours = (VacationHours * 1.0) / @MaxVacationHours
FROM AdventureWorks2019.HumanResources.Employee
WHERE (VacationHours * 1.0) / @MaxVacationHours >= 0.8

--Exercise: Variables for complex date math

DECLARE @Today DATE = CAST(GETDATE() AS DATE)
SELECT @Today

DECLARE @Current14 DATE = DATEFROMPARTS(YEAR(@Today),MONTH(@Today),14)
SELECT @Current14

DECLARE @PayPeriodEnd DATE = 
CASE WHEN DAY(@Today) >= 15 THEN @Current14
	 ELSE DATEADD(MONTH,-1,@Current14)
	 END

DECLARE @PayPeriodBeg DATE = DATEADD(DAY,1,DATEADD(MONTH,-1,@PayPeriodEnd))

SELECT @PayPeriodBeg
SELECT @PayPeriodEnd

--Exercise: User defined functions

CREATE FUNCTION dbo.ufnPercentOf(@Number1 INT, @Number2 INT)
RETURNS VARCHAR(50)
AS
BEGIN
	RETURN FORMAT((@Number1*1.0) / @Number2, 'P')
END

EXEC dbo.ufnPercentOf (2, 6)

DROP FUNCTION dbo.ufnPercentOf

--Exercise: User defined functions with variables
DECLARE @MaxVacationHours INT = (SELECT MAX(VacationHours) FROM HumanResources.Employee)

SELECT
	BusinessEntityID,
	JobTitle,
	VacationHours,
	PercentOfMaxVacation = dbo.ufnPercentOf(VacationHours,@MaxVacationHours)
FROM HumanResources.Employee

--Exercise: Stored procedures with parameters

ALTER PROCEDURE sp_OrdersAboveThreshold(@Threshold FLOAT, @StartYear INT, @EndYear INT)
AS
BEGIN
	SELECT *
	FROM Sales.SalesOrderHeader
	WHERE TotalDue > @Threshold
	AND YEAR(OrderDate) BETWEEN @StartYear AND @EndYear
END

EXEC sp_OrdersAboveThreshold 500, 2011, 2013

	SELECT *
	FROM Sales.SalesOrderHeader

--Exercise: IF statement control flow

ALTER PROCEDURE sp_OrdersAboveThreshold(@Threshold FLOAT, @StartYear INT, @EndYear INT, @OrderType INT)
AS
BEGIN
	IF @OrderType = 1
		BEGIN
			SELECT *
			FROM Sales.SalesOrderHeader
			WHERE TotalDue > @Threshold
			AND YEAR(OrderDate) BETWEEN @StartYear AND @EndYear
		END
	ELSE 
		BEGIN
			SELECT *
			FROM Purchasing.PurchaseOrderHeader
			WHERE TotalDue > @Threshold
			AND YEAR(OrderDate) BETWEEN @StartYear AND @EndYear
		END
END

EXEC sp_OrdersAboveThreshold 500, 2011, 2013, 2

--Exercise: Multiple stored procedures

ALTER PROCEDURE sp_OrdersAboveThreshold(@Threshold FLOAT, @StartYear INT, @EndYear INT, @OrderType INT)
AS
BEGIN
	IF @OrderType = 1
		BEGIN
			SELECT *
			FROM Sales.SalesOrderHeader
			WHERE TotalDue > @Threshold
			AND YEAR(OrderDate) BETWEEN @StartYear AND @EndYear
		END
	IF @OrderType = 2 
		BEGIN
			SELECT *
			FROM Purchasing.PurchaseOrderHeader
			WHERE TotalDue > @Threshold
			AND YEAR(OrderDate) BETWEEN @StartYear AND @EndYear
		END
	IF @OrderType = 3
		BEGIN
			SELECT 
				SalesOrderID AS OrderID,
				OrderDate,
				TotalDue,
				'Sales' AS OrderType
			FROM Sales.SalesOrderHeader
			WHERE TotalDue > @Threshold
			AND YEAR(OrderDate) BETWEEN @StartYear AND @EndYear

			UNION ALL

			SELECT
				PurchaseOrderID AS OrderID,
				OrderDate,
				TotalDue,
				'Purchases' AS OrderType
			FROM Purchasing.PurchaseOrderHeader
			WHERE TotalDue > @Threshold
			AND YEAR(OrderDate) BETWEEN @StartYear AND @EndYear
		END
END

EXEC sp_OrdersAboveThreshold 500, 2011, 2013, 3

--Exercise: Dynamic SQL queries
ALTER PROCEDURE dbo.NameSearch(@NameToSearch VARCHAR(100), @SearchPattern VARCHAR(100))
AS
BEGIN
	DECLARE @Field VARCHAR(100) =
	CASE WHEN @NameToSearch = 'first' THEN 'FirstName'
		 WHEN @NameToSearch = 'middle' THEN 'MiddleName'
		 WHEN @NameToSearch = 'last' THEN 'LastName'
	END
	DECLARE @DynamicSQL VARCHAR(MAX)
	SET @DynamicSQL = 
	'SELECT * FROM AdventureWorks2019.Person.Person WHERE '
	SET @DynamicSQL = @DynamicSQL + @Field
	SET @DynamicSQL = @DynamicSQL  + ' LIKE ' + '''' + '%' + @SearchPattern + '%' + ''''
	EXEC (@DynamicSQL)
END

EXEC NameSearch 'first', 'jo'