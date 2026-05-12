
--1.  usp_GetEmployeeActivityLog Stored Procedure

Create Procedure usp_GetEmployeeActivityLog 
@EmployeeId BigInt = Null,   --Optional Employee Identifier
@StartDate DateTime2 = Null,  
@EndDate DateTime2   = Null,   
@RowLimit Int        = 15

As
Begin 
      --Using Top to Control Row Limit
	  Select Top (@RowLimit) *
	  From       Main.ActivityLog
	  Where
	  -- If given an Employee Id Return Filtering Result Otherwise Return All.
		         (@EmployeeId Is Null Or UpdatedBy = @EmployeeId) And 
	  -- Checking Date Range
		         (@StartDate Is Null Or UpdatedOn >= @StartDate) And
		   (@EndDate Is Null Or UpdatedOn <= @EndDate)
       Order By UpdatedOn Desc;  -- See newest activities first
	   End

	   Go


EXEC usp_GetEmployeeActivityLog 
    @EmployeeId = 151,--1, 2, 146, 151, 152 
    @StartDate = '2021-01-01', 
    @EndDate = '2026-05-12', 
    @RowLimit = 15;

EXEC usp_GetEmployeeActivityLog 
    @EmployeeId = 2, 
    @RowLimit = 10;

EXEC usp_GetEmployeeActivityLog;


GO



--2. usp_GetEmployeeSummary Stored Procedure

	   CREATE PROCEDURE usp_GetEmployeeSummary
    @AccountId BIGINT = NULL -- filter by Account Identifier Optional
AS
BEGIN
    SELECT 
        COUNT(Id) AS TotalEmployees, -- Total number of employees
        SUM(CASE WHEN Archived = 0 THEN 1 ELSE 0 END) AS ActiveEmployees, -- Count active employees
        SUM(CASE WHEN Archived = 1 THEN 1 ELSE 0 END) AS ArchivedEmployees --Count archived employees
    FROM Main.Employee
    WHERE (@AccountId IS NULL OR AccountId = @AccountId); --if provided then Apply Account filter 
END
GO

EXEC usp_GetEmployeeSummary;
EXEC usp_GetEmployeeSummary @AccountId = 1;

GO



--3. usp_GetActivityReport Stored Procedure

    CREATE PROCEDURE usp_GetActivityReport
    @StartDate DATETIME2,
    @EndDate DATETIME2
AS
BEGIN
    SELECT 
        ActivityType, 
        Action, 
        COUNT(Id) AS ActivityCount -- Count How much Activity in this Id
    FROM Main.ActivityLog
    WHERE UpdatedOn BETWEEN @StartDate AND @EndDate -- This is the filter between date range
    GROUP BY ActivityType, Action -- Grouping Data by ype and Action
    ORDER BY ActivityType;
END
GO

EXEC usp_GetActivityReport 
    @StartDate = '2021-05-10 00:00:00', 
    @EndDate = '2026-05-10 23:59:59';

EXEC usp_GetActivityReport 
    @StartDate = '2022-05-01', 
    @EndDate = '2026-05-12';

EXEC usp_GetActivityReport 
    @StartDate = '2025-05-12 08:00:00', 
    @EndDate = '2026-05-12 13:00:00';


	GO
--4. usp_SearchContacts Stored Procedure

CREATE PROCEDURE usp_SearchContacts
    @SearchText NVARCHAR(100), -- Search keyword by Name or Email
    @PageNumber INT = 1,       -- pagination
    @PageSize INT = 10         -- Number of records per page
AS
BEGIN
    -- Retrieve the total count of matching records
    SELECT COUNT(Id) AS TotalCount FROM Main.Contact 
    WHERE (Name LIKE '%' + @SearchText + '%' OR Email LIKE '%' + @SearchText + '%');

    -- Retrieve paged results using (OFFSET-FETCH)
    SELECT * FROM Main.Contact
    WHERE (Name LIKE '%' + @SearchText + '%' OR Email LIKE '%' + @SearchText + '%')
    ORDER BY Name
    OFFSET (@PageNumber - 1) * @PageSize ROWS -- How much Row Scaped
    FETCH NEXT @PageSize ROWS ONLY;           -- How much Row Retrive after Scaped
END
GO

EXEC usp_SearchContacts @SearchText = 'John';

EXEC usp_SearchContacts @SearchText = 'gmail', @PageNumber = 2, @PageSize = 30;

EXEC usp_SearchContacts @SearchText = '1', @PageNumber = 1, @PageSize = 5;

GO

--5.usp_GetWorkflowParticipants Stored Procedure

CREATE PROCEDURE usp_GetWorkflowParticipants
    @WorkflowId BIGINT
AS
BEGIN
    SELECT 
        p.[Order], p.Name AS ParticipantName, 
        e.FirstName, e.LastName, e.Email
    FROM Workflow.Participant p
    JOIN Main.Employee e ON p.UserId = e.Id -- Join Employee Table by User ID from Participant Table.
    WHERE p.WorkflowId = @WorkflowId
    ORDER BY p.[Order] ASC; -- Sort by the defined participant order
END
GO

EXEC usp_GetWorkflowParticipants @WorkflowId = 1;

EXEC usp_GetWorkflowParticipants @WorkflowId = 2;

GO
--6. usp_GetEmployeeLoginHistory Stored Procedure

CREATE PROCEDURE usp_GetEmployeeLoginHistory
    @StartDate DATETIME2 = NULL,
    @EndDate DATETIME2 = NULL,
    @NotLoggedInRecently BIT = 0 
AS
BEGIN
    SELECT 
        e.FirstName, e.LastName, 
        MAX(lh.Date) AS LastLoginDate,
        CASE 
            WHEN MAX(lh.Date) IS NULL THEN 'Never Logged In'
            WHEN MAX(lh.Date) < DATEADD(DAY, -30, GETDATE()) THEN 'Inactive Recently'
            ELSE 'Active'
        END AS LoginStatus
    FROM Main.Employee e
    LEFT JOIN Main.LoginHistory lh ON e.Id = lh.UserId
    WHERE 
        -- Date Filtering And Null Handling Logic
        (@StartDate IS NULL OR lh.Date >= @StartDate OR lh.Date IS NULL) AND
        (@EndDate IS NULL OR lh.Date <= @EndDate OR lh.Date IS NULL)
    GROUP BY e.FirstName, e.LastName, e.Id
    HAVING 
        (@NotLoggedInRecently = 0 OR 
         MAX(lh.Date) < DATEADD(DAY, -30, GETDATE()) OR 
         MAX(lh.Date) IS NULL);
END
GO

GO
EXEC usp_GetEmployeeLoginHistory 
    @StartDate = '2025-01-01', 
    @EndDate = '2026-05-12',
	@NotLoggedInRecently = 1;

EXEC usp_GetEmployeeLoginHistory 
    @NotLoggedInRecently = 1;

EXEC usp_GetEmployeeLoginHistory;


GO

-- 7.usp_GenerateActivityDashboard Stored Procedure

CREATE PROCEDURE usp_GenerateActivityDashboard
AS
BEGIN
    SELECT 
        e.FirstName + ' ' + e.LastName AS EmployeeName,
        COUNT(al.Id) AS TotalActivities,       -- Total activity count per employee
        MAX(al.UpdatedOn) AS LastActivityTime, -- Most recent activity timestamp
        COUNT(DISTINCT al.ActivityType) AS UniqueActivityTypes -- Count of unique activity categories
    FROM Main.Employee e
    LEFT JOIN Main.ActivityLog al ON e.Id = al.UpdatedBy
    GROUP BY e.FirstName, e.LastName, e.Id;
END
GO

EXEC usp_GenerateActivityDashboard;


