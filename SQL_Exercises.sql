--1
SELECT Name
FROM Employee
WHERE DepartmentId =
(
	SELECT DepartmentId
	FROM Employee
	WHERE Name LIKE '%John%'
)
AND Name NOT LIKE '%John%';

--2
SELECT
	Job,
	TotalRegisteredHours = SUM(Hours)
FROM DailyTimeSheet
GROUP BY Job
ORDER BY 2 DESC;

--3
SELECT T.*
FROM DailyTimeSheet T
JOIN Employee E
ON E.Id = T.EmployeeId
WHERE T.EntryDate > E.Terminated;

--4
SELECT
	Year,
	WeekNumber,
	EmployeeName,
	Department,
	ISNULL(Monday, 0) AS TotalHoursMonday,
	ISNULL(Tuesday, 0) AS TotalHoursTuesday,
	ISNULL(Wednesday, 0) AS TotalHoursWednesday,
	ISNULL(Thursday, 0) AS TotalHoursThursday,
	ISNULL(Friday, 0) AS TotalHoursFriday,
	ISNULL(Weekend, 0) AS TotalHoursWeekend
FROM
(
	SELECT *
	FROM
	(
		SELECT		
			'Year' = DATEPART(YEAR, T.EntryDate),
			'WeekNumber' = DATEPART(WEEK, T.EntryDate),
			E.Name AS EmployeeName,
			ISNULL(D.Name,'-') AS Department,
			'DayOfWeek' = 
				CASE WHEN DATENAME(WEEKDAY, T.EntryDate) IN ('Saturday', 'Sunday') THEN 'Weekend'
					 ELSE DATENAME(WEEKDAY, T.EntryDate)
					 END,
			T.Hours
		FROM DailyTimeSheet T
		JOIN Employee E
		ON E.Id = T.EmployeeId
		LEFT JOIN Department1 D --left join to prevent filtering out of time entries where employees have no assigned department
		ON D.Id = E.DepartmentId
	)A
	PIVOT
	(
		SUM(Hours)
		FOR DayOfWeek IN ([Monday], [Tuesday], [Wednesday], [Thursday], [Friday], [Weekend])
	)B
)C
ORDER BY 1,2,3;

--5
SELECT
	T.EntryDate,
	E.Name,
	T.Job,
	T.Hours
FROM DailyTimeSheet T
JOIN Employee E
ON E.Id = T.EmployeeId
WHERE DATEPART(M, T.EntryDate) = DATEPART(M,DATEADD(M,-1,GETDATE())) --fetch only rec-ords from previous monthnumber
AND DATEPART(YYYY, T.EntryDate) = DATEPART(YYYY,DATEADD(M,-1,GETDATE())) --include year of the previous month as additional filter
ORDER BY 1,2,3;

--6
SELECT Name
FROM Employee
WHERE Id IN
(
	SELECT EmployeeId
	FROM DailyTimeSheet
	GROUP BY EmployeeId
	HAVING COUNT(EmployeeId) = 1
);

--7
SELECT Job
FROM DailyTimeSheet
GROUP BY Job
HAVING COUNT(DISTINCT(EmployeeID)) >= 2;

--8
SELECT 
	A.Job,
	EmployeeNames = 
	STUFF(
			(
				SELECT DISTINCT TOP 5 ', ' + E.Name
				FROM Employee E
				JOIN DailyTimeSheet T
				ON T.EmployeeId = E.Id
				WHERE T.Job = A.Job
				FOR XML PATH('')
			),
			1,1,''
		 )
FROM
(
	SELECT 
		Job
	FROM DailyTimeSheet
	GROUP BY Job
	HAVING COUNT(DISTINCT(EmployeeID)) >= 2
)A;

--9
SELECT A.Name
FROM
(
	SELECT
		Name,
		ROW_NUMBER() OVER(ORDER BY Name) AS RowNumber
	FROM Employee
)A
WHERE A.RowNumber % 3 = 0
ORDER BY Name;

--10
SELECT 
	E.Name,
	AvgMonthlyPayment = AVG(P.Amount)
FROM Payment P
JOIN Employee E
ON E.Id = P.EmployeeId
GROUP BY E.Name
HAVING AVG(P.Amount) > 1000;

--11
SELECT 
	A.Name, 
	A.AvgMonthlyPayment
FROM
(
	SELECT 
		E.Name,
		AvgMonthlyPayment = 
		(
			SELECT AVG(P.Payment) AS AvgMonthlyPayment
			FROM Payment P
			WHERE P.EmployeeId = E.Id
		)
	FROM Employee E
)A
WHERE AvgMonthlyPayment > 1000;

--12
CREATE TABLE Forex2 AS
SELECT
	CurrencyFrom,
	CurrencyTo,
	Rate = ROUND(CAST(Rate2/Rate1 AS FLOAT),3,1)
FROM
(
	SELECT
		Currency AS CurrencyFrom,
		Rate AS Rate1
	FROM Forex
	UNION
	SELECT 
		BaseCurrency,
		Rate = 1
	FROM Setup
)A
CROSS JOIN
(
	SELECT
		Currency AS CurrencyTo,
		Rate AS Rate2
	FROM Forex
	UNION
	SELECT 
		BaseCurrency,
		Rate = 1
	FROM Setup
)B
ORDER BY CurrencyFrom DESC, 
CASE CurrencyFrom WHEN 'USD' THEN --Nested case statements to determine sort ranking
	CASE CurrencyTo WHEN 'USD' THEN 3
					WHEN 'PHP' THEN 1
					WHEN 'DKK' THEN 2
					END
ELSE CASE CurrencyFrom WHEN 'PHP' THEN
	CASE CurrencyTo WHEN 'USD' THEN 1
					WHEN 'PHP' THEN 3
					WHEN 'DKK' THEN 2
					END
ELSE CASE CurrencyFrom WHEN 'DKK' THEN
	CASE CurrencyTo WHEN 'USD' THEN 1
					WHEN 'PHP' THEN 2
					WHEN 'DKK' THEN 3
					END
		END
	END
END;

--13
SELECT 
	B.EmployeeId,
	CASE WHEN Day='HoursMonday' THEN B.WeekStart
		 WHEN Day='HoursTuesday' THEN DATEADD(Day, 1,B.WeekStart)
		 WHEN Day='HoursWednesday' THEN DATEADD(Day, 2,B.WeekStart)
		 WHEN Day='HoursThursday' THEN DATEADD(Day, 3,B.WeekStart)
		 WHEN Day='HoursFriday' THEN DATEADD(Day, 4,B.WeekStart)
		 WHEN Day='HoursSaturday' THEN DATEADD(Day, 5,B.WeekStart)
		 WHEN Day='HoursSunday' THEN DATEADD(Day, 6,B.WeekStart)
	END AS EntryDate,
	Hours
FROM
(
	SELECT *
	FROM WeeklyTimeSheet
	UNPIVOT
	(
		Hours
		FOR Day IN (HoursMonday, HoursTuesday, HoursWednesday, HoursThursday, HoursFriday, HoursSaturday, HoursSunday)
	)A
)B;

--14
SELECT DISTINCT C.FIRST_NAME + ' ' + C.LAST_NAME AS NAME
FROM CUSTOMER C
JOIN RESERVATIONS R
ON R.cust_id = C.cust_id
LEFT JOIN SALES S
ON S.cust_id = R.cust_id
WHERE S.inv_id IS NULL;

--15
SELECT
	Service,
	SALES_REVENUE = ISNULL(SUM(IL.days * IL.nb_guests * S.Price),0),
	FUTURE_REVENUE = ISNULL(SUM(RL.res_days * RL.future_guests * S.Price),0)
FROM Service S
LEFT JOIN INVOICE_LINE IL
ON IL.service_id = S.service_id
LEFT JOIN RESERVATION_LINE RL
ON RL.service_id = S.service_id
GROUP BY Service
ORDER BY SUM(S.Price * IL.nb_guests * IL.days) DESC;

--16
SELECT 
	A.Resort AS RESORT,
	A.SALES_REVENUE
FROM
(
	SELECT 
		R.resort,
		SALES_REVENUE = SUM(IL.days * IL.nb_guests * S.Price),
		RANK() OVER(ORDER BY SUM(IL.days * IL.nb_guests * S.Price) DESC) AS Rank
	FROM RESORT R
	JOIN SERVICE_LINE SL
	ON SL.resort_id = R.resort_id
	JOIN SERVICE S
	ON S.sl_id = SL.sl_id
	JOIN INVOICE_LINE IL
	ON IL.service_id = S.service_id
	GROUP BY R.resort
)A
WHERE A.Rank = 1;

--17
SELECT REVENUE = SALES_REVENUE + FUTURE_REVENUE
FROM
(
SELECT
	SL.service_line,
	SALES_REVENUE = SUM(IL.days * IL.nb_guests * S.Price),
	FUTURE_REVENUE = SUM(RL.res_days * RL.future_guests * S.Price)
FROM SERVICE_LINE SL
JOIN SERVICE S
ON S.sl_id = SL.sl_id
JOIN INVOICE_LINE IL
ON IL.service_id = S.service_id
JOIN Sales SA
ON SA.inv_id = IL.inv_id
LEFT JOIN RESERVATION_LINE RL --left join to prevent filtering of lines without reservation
ON RL.service_id = S.service_id
LEFT JOIN RESERVATIONS R --left join to prevent filtering of lines without reservation
ON R.res_id = RL.res_id
WHERE DATEPART(YEAR, SA.invoice_date) = 2012
OR DATEPART(YEAR, R.res_date) = 2012
GROUP BY SL.service_line
HAVING SL.service_line = 'Accommodation'
)A;

--18
SELECT *
FROM
(
	SELECT 
		T.Title,
		T.Subject,
		T.MaxStudents,
		COUNT(E.StudentId) AS NrOfEnrolledStudents
	FROM Training T
	LEFT JOIN Enrollment E
	ON E.TrainingId = T.Id
	GROUP BY T.Title, T.Subject, T.MaxStudents
)A
WHERE A.NrOfEnrolledStudents > A.MaxStudents;

--19
WITH Students AS
(
	SELECT DISTINCT
		S.Name AS Student,
		T.Subject
	FROM Student S
	JOIN Enrollment E
	ON E.StudentId = S.Id
	LEFT JOIN Training T
	ON T.Id = E.TrainingId
)

SELECT Student
FROM Students
WHERE Subject = 'Algebra'

EXCEPT

SELECT Student
FROM Students
WHERE Subject = 'Statistics';

--20
WITH Schedule AS
(
	SELECT
		S.Name AS Student,
		C.StartTime,
		C.EndTime,
		C.TrainingId
	FROM Student S
	JOIN Enrollment E
	ON E.StudentId = S.Id
	JOIN Training T
	ON T.Id = E.TrainingId
	JOIN ClassSchedule C
	ON C.TrainingId = T.Id
)

SELECT S.*
FROM Schedule S
JOIN
(
	SELECT
		Student,
		StartTime,
		EndTime
	FROM Schedule
	GROUP BY Student, StartTime, EndTime
	HAVING COUNT(Student)>1
)A
ON A.Student = S.Student
AND A.StartTime = S.StartTime
AND A.EndTime = S.EndTime;

