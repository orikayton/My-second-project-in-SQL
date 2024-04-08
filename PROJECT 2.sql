--project 2 - ori kayton
--ex 1
SELECT PP.ProductID,PP.Name,PP.Color,PP.ListPrice,PP.Size
FROM Production.Product [PP]
WHERE NOT EXISTS 
	(SELECT ProductID FROM Sales.SalesOrderDetail WHERE PP.ProductID=ProductID)
ORDER BY PP.ProductID

--ex 3
SELECT CustomerID,FirstName,LastName,[CountOfNumber] 
FROM(
	SELECT C.CustomerID,P.FirstName,P.LastName,
	COUNT(C.CustomerID)[CountOfNumber],
	ROW_NUMBER()OVER(ORDER BY COUNT(C.CustomerID) DESC)[RN]
	FROM
	Sales.Customer [C] JOIN Person.Person [P]
	ON C.PersonID=P.BusinessEntityID
	JOIN Sales.SalesOrderHeader [SOH]
	ON SOH.CustomerID=C.CustomerID
	GROUP BY C.CustomerID,P.FirstName,P.LastName)A
WHERE[RN]<=10 

--ex 4
SELECT P.FirstName,P.LastName,E.JobTitle,E.HireDate,[CountOfTitle]
FROM Person.Person [P] JOIN HumanResources.Employee [E]
ON P.BusinessEntityID=E.BusinessEntityID 
JOIN
	(SELECT JobTitle,COUNT(*)[CountOfTitle]
	FROM HumanResources.Employee
	GROUP BY JobTitle)A 
ON A.JobTitle=E.JobTitle

--ex 5

SELECT SalesOrderID,CustomerID,LastName,FirstName,[LastOrder],[Prev Order]
FROM(
		SELECT SO.SalesOrderID,SO.CustomerID,P.LastName,P.FirstName,SO.OrderDate[LastOrder],
		LAG(SO.OrderDate,1)OVER(PARTITION BY SO.CustomerID ORDER BY SO.OrderDate)[Prev Order],
		DENSE_RANK()OVER(PARTITION BY SO.CustomerID ORDER BY SO.OrderDate DESC)[RNK]
		FROM Person.Person [P] JOIN Sales.Customer [C] ON P.BusinessEntityID=C.PersonID 
		JOIN Sales.SalesOrderHeader [SO] ON SO.CustomerID=C.CustomerID)A
WHERE RNK=1 
ORDER BY CustomerID DESC

--ex 6

SELECT [Year],SalesOrderID,FirstName,LastName,FORMAT([TOTAL],'###,###.#')[Total]
FROM (
	SELECT 
	YEAR(SOH.OrderDate)[Year],SOD.SalesOrderID,P.FirstName,P.LastName,
	SUM(SOD.UnitPrice*(1-SOD.UnitPriceDiscount)*SOD.OrderQty)[TOTAL],
	ROW_NUMBER()OVER(PARTITION BY YEAR(SOH.OrderDate)ORDER BY 
	SUM(SOD.UnitPrice*(1-SOD.UnitPriceDiscount)*SOD.OrderQty)DESC)[RN]
		FROM Person.Person [P] JOIN Sales.Customer [C]
		ON P.BusinessEntityID=C.PersonID JOIN Sales.SalesOrderHeader [SOH]
		ON C.CustomerID=SOH.CustomerID JOIN Sales.SalesOrderDetail [SOD]
		ON SOH.SalesOrderID=SOD.SalesOrderID
		GROUP BY YEAR(SOH.OrderDate),SOD.SalesOrderID,P.FirstName,P.LastName)A
WHERE RN=1

--ex 7
SELECT * 
FROM(
	SELECT MONTH(OrderDate) [Month],YEAR(OrderDate)[Year],SalesOrderID
	FROM Sales.SalesOrderHeader)A
	PIVOT(COUNT(SalesOrderID) FOR [Year] IN([2011],[2012],[2013],[2014]))piv
ORDER BY [Month]


--ex 8

WITH CUM1 AS (
	SELECT YEAR(SOH.OrderDate)[Year],CAST(MONTH(SOH.OrderDate)AS VARCHAR)[Month],
	ROUND(SUM(SOD.UnitPrice),2) [SumPrice]
	FROM Sales.SalesOrderHeader [SOH] JOIN Sales.SalesOrderDetail[SOD] ON SOH.SalesOrderID=SOD.SalesOrderID
	GROUP BY ROLLUP (YEAR(SOH.OrderDate),MONTH(SOH.OrderDate)))
	
	
	SELECT CUM1.[Year],ISNULL(CUM1.MONTH,'grand_total') [Month],ROUND(CUM1.SumPrice,2) [SumPrice],
	SUM(CUM1.SumPrice)OVER(PARTITION BY [Year] ORDER BY [Year]  ROWS
	BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW )[CumSum]
	FROM CUM1
	WHERE YEAR IS NOT NULL 
	


--ex 9 
WITH Tabl_A AS (
		SELECT D.Name [NameDepartment],E.BusinessEntityID[EmployeesID_A],P.FirstName+' '+P.LastName
		[EmployeesFULLNAME]
		FROM HumanResources.Department [D] JOIN  HumanResources.EmployeeDepartmentHistory [EDH]
		ON D.DepartmentID=EDH.DepartmentID JOIN HumanResources.Employee [E]
		ON EDH.BusinessEntityID=E.BusinessEntityID JOIN Person.Person [P] 
		ON E.BusinessEntityID=P.BusinessEntityID),

Tabl_B AS
		(SELECT BusinessEntityID [EmployeesID_B],HireDate,DATEDIFF(MM,HireDate,GETDATE())[Seniority]
		FROM HumanResources.Employee)

SELECT 
A.NameDepartment,A.EmployeesID_A,
A.EmployeesFULLNAME,B.HireDate,B.Seniority,
LAG(A.EmployeesFULLNAME,1)OVER (PARTITION BY A.NameDepartment ORDER BY B.HireDate)[PreviousEmpName],
LAG(B.HireDate,1) OVER (PARTITION BY A.NameDepartment ORDER BY B.HireDate) [PreviousEmpDate],
DATEDIFF(DD,LAG(B.HireDate,1)OVER (PARTITION BY A.NameDepartment ORDER BY B.HireDate),B.HireDate) [DiffDays]

FROM Tabl_A [A] JOIN Tabl_B [B] ON A.EmployeesID_A=B.EmployeesID_B
ORDER BY  A.NameDepartment,B.HireDate DESC



--update of netanel
UPDATE sales.customer SET personid=customerid
WHERE customerid <=290
UPDATE sales.customer SET personid=customerid+1700
WHERE customerid >= 300 AND customerid<=350
UPDATE sales.customer SET personid=customerid+1700
WHERE customerid >= 352 AND customerid<=701

--ex 2
SELECT C.CustomerID,
ISNULL(p.LastName,'Unknown')[LastName],
ISNULL(P.FirstName,'Unknown')[FirstName]
	FROM Sales.Customer [C] LEFT JOIN Person.Person [P] 
	ON P.BusinessEntityID=C.PersonID
	WHERE NOT EXISTS 
		(SELECT CustomerID FROM Sales.SalesOrderHeader [SOH] WHERE C.CustomerID=SOH.CustomerID)
ORDER BY C.CustomerID

--ex 10
SELECT DISTINCT E1.HireDate,EDH.DepartmentID,STUFF((
SELECT ',' + CAST(E.BusinessEntityID AS varchar) + P.LastName+' '+P.FirstName
FROM HumanResources.Employee [E] JOIN Person.Person [P]
ON E.BusinessEntityID=P.BusinessEntityID
WHERE E.BusinessEntityID=P.BusinessEntityID
FOR XML PATH('')),1,1,'') [TeamEmployees]

FROM HumanResources.Employee [E1] JOIN HumanResources.EmployeeDepartmentHistory [EDH]
ON E1.BusinessEntityID=EDH.BusinessEntityID JOIN Person.Person [P1]
ON E1.BusinessEntityID=P1.BusinessEntityID
ORDER BY HireDate DESC


SELECT  E2.HireDate,EDH1.DepartmentID,P2.BusinessEntityID,
P2.LastName+' '+P2.FirstName [TeamEmployees]
FROM  HumanResources.Employee [E2] JOIN HumanResources.EmployeeDepartmentHistory [EDH1]
ON E2.BusinessEntityID=EDH1.BusinessEntityID JOIN Person.Person [P2]
ON E2.BusinessEntityID=P2.BusinessEntityID
ORDER BY E2.HireDate DESC

SELECT DISTINCT E1.HireDate,EDH.DepartmentID,STUFF((
	SELECT ',' + CAST(E.BusinessEntityID AS varchar) + P.LastName+' '+P.FirstName
	FROM HumanResources.Employee [E] JOIN Person.Person [P]
	ON E.BusinessEntityID=P.BusinessEntityID
	WHERE CAST(E.BusinessEntityID AS varchar)= P.LastName+' '+P.FirstName
FOR XML PATH('')),1,1,'') [TeamEmployees]

FROM HumanResources.Employee [E1] JOIN HumanResources.EmployeeDepartmentHistory [EDH]
ON E1.BusinessEntityID=EDH.BusinessEntityID JOIN Person.Person [P1]
ON E1.BusinessEntityID=P1.BusinessEntityID
ORDER BY HireDate DESC
