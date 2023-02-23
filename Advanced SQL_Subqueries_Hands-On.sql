USE AdventureWorks2019

--Exercise: Scalar subqueries in the SELECT and WHERE clauses

SELECT
	BusinessEntityID,
	JobTitle,
	VacationHours,
	MaxVacationHours = (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee),
	PctFromMaxVacation = (VacationHours*1.0)/(SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee)
FROM AdventureWorks2019.HumanResources.Employee
WHERE (VacationHours*1.0)/(SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee) >= .80

--Exercise: Correlated Subqueries

SELECT
	PurchaseOrderID,
	VendorID,
	OrderDate,
	TotalDue,
	NonRejectedItems = 
	(
		SELECT
			COUNT(*)
		FROM Purchasing.PurchaseOrderDetail B
		WHERE A.PurchaseOrderID = B.PurchaseOrderID
		AND RejectedQty = 0
	),
	MostExpensiveItem = 
	(
		SELECT
			MAX(B.UnitPrice)
		FROM Purchasing.PurchaseOrderDetail B
		WHERE A.PurchaseOrderID = B.PurchaseOrderID
	)
FROM Purchasing.PurchaseOrderHeader A

--Exercise: EXISTS/NOT EXISTS

--1
SELECT
	PurchaseOrderID,
	OrderDate,
	SubTotal,
	TaxAmt
FROM Purchasing.PurchaseOrderHeader OH
WHERE EXISTS
(
	SELECT 1
	FROM Purchasing.PurchaseOrderDetail OD
	WHERE OD.PurchaseOrderID = OH.PurchaseOrderID
	AND OD.OrderQty >500
)
ORDER BY 1

SELECT
	PurchaseOrderID,
	OrderQty,
	RejectedQty
FROM Purchasing.PurchaseOrderDetail

--2
SELECT OH.*
FROM Purchasing.PurchaseOrderHeader OH
WHERE EXISTS
(
	SELECT 1
	FROM Purchasing.PurchaseOrderDetail OD
	WHERE OD.PurchaseOrderID = OH.PurchaseOrderID
	AND OD.OrderQty > 500
	AND OD.UnitPrice > 50
)
ORDER BY 1

--3
SELECT OH.*
FROM Purchasing.PurchaseOrderHeader OH
WHERE NOT EXISTS
(
	SELECT 1
	FROM Purchasing.PurchaseOrderDetail OD
	WHERE OD.PurchaseOrderID = OH.PurchaseOrderID
	AND OD.RejectedQty > 0
)
ORDER BY 1

--Exercise: FOR XML PATH

SELECT 
	S.*,
	S.Name AS SubcategoryName,
	Products =
	STUFF(
		(
			SELECT
			';' + P.Name
			FROM Production.Product P
			WHERE P.ProductSubcategoryID = S.ProductSubcategoryID
			FOR XML PATH('')
		),
		1,1,''
	)
FROM Production.ProductSubcategory S

--Exercise: FOR XML PATH with filter

SELECT 
	S.*,
	S.Name AS SubcategoryName,
	Products =
	STUFF(
		(
			SELECT
			';' + P.Name
			FROM Production.Product P
			WHERE P.ProductSubcategoryID = S.ProductSubcategoryID
			AND P.ListPrice > 50
			FOR XML PATH('')
		),
		1,1,''
	)
FROM Production.ProductSubcategory S

--Exercise: PIVOT function

SELECT
	[Sales Representative],
	Buyer,
	Janitor
FROM
(
	SELECT
		JobTitle,
		VacationHours
	FROM HumanResources.Employee
)E
PIVOT
(
	AVG(VacationHours)
	FOR JobTitle IN ([Sales Representative], Janitor, Buyer)
)P

SELECT DISTINCT JobTitle
FROM HumanResources.Employee

--Exercise: PIVOT with additional field

SELECT
	[Sales Representative],
	Buyer,
	Janitor,
	[Employee Gender] = Gender
FROM
(
	SELECT
		JobTitle,
		VacationHours,
		Gender
	FROM HumanResources.Employee
)E
PIVOT
(
	AVG(VacationHours)
	FOR JobTitle IN ([Sales Representative], Janitor, Buyer)
)P