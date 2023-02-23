USE AdventureWorks2019

--Exercise: OVER function

SELECT DISTINCT
	P.FirstName,
	P.LastName,
	E.JobTitle,
	EP.Rate,
	AVG(EP.Rate) OVER() AS AverageRate,
	MAX(EP.Rate) OVER() AS MaximumRate,
	(EP.Rate - AVG(EP.Rate) OVER()) AS DiffFromAvgRate,
	(EP.Rate/MAX(EP.Rate) OVER())*100 AS PercentofMaxRate
FROM Person.Person P
JOIN HumanResources.Employee E
ON P.BusinessEntityID = E.BusinessEntityID
JOIN HumanResources.EmployeePayHistory EP
ON EP.BusinessEntityID = E.BusinessEntityID

--Exercise: PARTITION BY

SELECT 
  ProductName = A.Name,
  A.ListPrice,
  ProductSubcategory = B.Name,
  ProductCategory = C.Name,
  AvgPriceByCategory = AVG(A.ListPrice) OVER(PARTITION BY C.Name),
  AvgPriceByCategoryAndSubcategory = AVG(A.ListPrice) OVER(PARTITION BY C.Name, B.Name),
  ProductVsCategoryDelta = A.ListPrice - AVG(A.ListPrice) OVER(PARTITION BY C.Name)
FROM AdventureWorks2019.Production.Product A
JOIN AdventureWorks2019.Production.ProductSubcategory B
ON A.ProductSubcategoryID = B.ProductSubcategoryID
JOIN AdventureWorks2019.Production.ProductCategory C
ON B.ProductCategoryID = C.ProductCategoryID

--Exercise: ROW_NUMBER function

SELECT 
  ProductName = A.Name,
  A.ListPrice,
  ProductSubcategory = B.Name,
  ProductCategory = C.Name,
  PriceRank = ROW_NUMBER() OVER(ORDER BY A.ListPrice DESC),
  CategoryPriceRank = ROW_NUMBER() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC),
  CASE WHEN ROW_NUMBER() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC) <= 5
	THEN 'Yes'
	ELSE 'No'
  END AS 'Top5PriceInCategory'
FROM AdventureWorks2019.Production.Product A
JOIN AdventureWorks2019.Production.ProductSubcategory B
ON A.ProductSubcategoryID = B.ProductSubcategoryID
JOIN AdventureWorks2019.Production.ProductCategory C
ON B.ProductCategoryID = C.ProductCategoryID

--Exercise: ROW_NUMBER, RANK, and DENSE_RANK

SELECT 
  ProductName = A.Name,
  A.ListPrice,
  ProductSubcategory = B.Name,
  ProductCategory = C.Name,
  PriceRank = ROW_NUMBER() OVER(ORDER BY A.ListPrice DESC),
  CategoryPriceRank = ROW_NUMBER() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC),
  CategoryPriceRankWithRank = RANK() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC),
  CategoryPriceRankWithDenseRank = DENSE_RANK() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC),
  CASE WHEN DENSE_RANK() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC) <= 5
	THEN 'Yes'
	ELSE 'No'
  END AS 'Top5PriceInCategory'
FROM AdventureWorks2019.Production.Product A
JOIN AdventureWorks2019.Production.ProductSubcategory B
ON A.ProductSubcategoryID = B.ProductSubcategoryID
JOIN AdventureWorks2019.Production.ProductCategory C
ON B.ProductCategoryID = C.ProductCategoryID

--Exercise: LEAD/LAG with PARTITION BY

SELECT DISTINCT: 
	P.OrderDate,
	P.PurchaseOrderID,
	P.TotalDue,
	V.Name AS VendorName,
	PrevOrderFromVendorAmt = LAG(P.TotalDue, 1) OVER(PARTITION BY P.VendorID ORDER BY P.OrderDate),
	NextOrderByEmployeeVendor = LEAD(V.Name, 1) OVER(PARTITION BY P.EmployeeID ORDER BY P.OrderDate),
	Next2OrderByEmployeeVendor = LEAD(V.Name, 2) OVER(PARTITION BY P.EmployeeID ORDER BY P.OrderDate)
FROM Purchasing.PurchaseOrderHeader P
JOIN Purchasing.Vendor V
ON V.BusinessEntityID = P.VendorID
WHERE OrderDate >= '2013-01-01'
AND TotalDue > 500

--Exercise: Select the most expensive item per order in a single query

SELECT * FROM
(
	SELECT
		SalesOrderID,
		SalesOrderDetailID,
		LineTotal,
		LineTotalRanking = ROW_NUMBER() OVER(PARTITION BY SalesOrderID ORDER BY LineTotal DESC)
	FROM AdventureWorks2019.Sales.SalesOrderDetail
)A
WHERE LineTotalRanking = 1

--Exercise: Filter by vendorID rank

SELECT DISTINCT
	PurchaseOrderID,
	VendorID,
	OrderDate,
	TaxAmt,
	Freight,
	TotalDue
FROM
(
	SELECT DISTINCT
		PurchaseOrderID,
		VendorID,
		OrderDate,
		TaxAmt,
		Freight,
		TotalDue,
		RankByVendorId = DENSE_RANK() OVER(PARTITION BY VendorID ORDER BY TotalDue DESC)
	FROM Purchasing.PurchaseOrderHeader
)P
WHERE RankByVendorId <= 3