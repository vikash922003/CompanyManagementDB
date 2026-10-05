
/*
============================================================
PROJECT: Enterprise HR & Payroll Management System
DATABASE: CompanyManagementDB
PLATFORM: Microsoft SQL Server
TABLES: 31
============================================================
Run this script in SSMS on a development SQL Server instance.
It creates a fresh database named CompanyManagementDB.
============================================================
*/

USE master;
GO

IF DB_ID(N'CompanyManagementDB') IS NOT NULL
BEGIN
    ALTER DATABASE CompanyManagementDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CompanyManagementDB;
END;
GO

CREATE DATABASE CompanyManagementDB;
GO

USE CompanyManagementDB;
GO

/* ==========================================================
   1. SCHEMAS
   ========================================================== */
CREATE SCHEMA HR;
GO
CREATE SCHEMA Payroll;
GO
CREATE SCHEMA Projects;
GO
CREATE SCHEMA Admin;
GO

/* ==========================================================
   2. MASTER / HR TABLES
   ========================================================== */

CREATE TABLE HR.Branches
(
    BranchID INT IDENTITY(1,1) PRIMARY KEY,
    BranchName VARCHAR(100) NOT NULL UNIQUE,
    City VARCHAR(100) NOT NULL,
    State VARCHAR(100) NULL,
    Country VARCHAR(100) NOT NULL DEFAULT 'India',
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE HR.Departments
(
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName VARCHAR(100) NOT NULL UNIQUE,
    DepartmentDescription VARCHAR(300) NULL,
    ManagerID INT NULL,
    BranchID INT NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Departments_Branch
        FOREIGN KEY (BranchID) REFERENCES HR.Branches(BranchID)
);
GO

CREATE TABLE HR.JobTitles
(
    JobTitleID INT IDENTITY(1,1) PRIMARY KEY,
    JobTitleName VARCHAR(100) NOT NULL,
    Grade VARCHAR(20) NULL,
    MinSalary DECIMAL(12,2) NOT NULL,
    MaxSalary DECIMAL(12,2) NOT NULL,

    CONSTRAINT CK_JobTitles_Salary
        CHECK (MinSalary >= 0 AND MaxSalary >= MinSalary),

    CONSTRAINT UQ_JobTitles_Name_Grade
        UNIQUE (JobTitleName, Grade)
);
GO

CREATE TABLE HR.Employees
(
    EmployeeID INT IDENTITY(1001,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(150) NOT NULL UNIQUE,
    Phone VARCHAR(20) NULL,
    Gender VARCHAR(20) NULL,
    DateOfBirth DATE NULL,
    HireDate DATE NOT NULL,
    DepartmentID INT NOT NULL,
    JobTitleID INT NOT NULL,
    BranchID INT NOT NULL,
    ManagerID INT NULL,
    EmploymentStatus VARCHAR(20) NOT NULL DEFAULT 'Active',
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Employees_Gender
        CHECK (Gender IN ('Male','Female','Other') OR Gender IS NULL),

    CONSTRAINT CK_Employees_Status
        CHECK (EmploymentStatus IN
              ('Active','OnLeave','Resigned','Terminated')),

    CONSTRAINT CK_Employees_Dates
        CHECK (DateOfBirth IS NULL OR DateOfBirth < HireDate),

    CONSTRAINT FK_Employees_Department
        FOREIGN KEY (DepartmentID) REFERENCES HR.Departments(DepartmentID),

    CONSTRAINT FK_Employees_JobTitle
        FOREIGN KEY (JobTitleID) REFERENCES HR.JobTitles(JobTitleID),

    CONSTRAINT FK_Employees_Branch
        FOREIGN KEY (BranchID) REFERENCES HR.Branches(BranchID),

    CONSTRAINT FK_Employees_Manager
        FOREIGN KEY (ManagerID) REFERENCES HR.Employees(EmployeeID)
);
GO

ALTER TABLE HR.Departments
ADD CONSTRAINT FK_Departments_Manager
FOREIGN KEY (ManagerID) REFERENCES HR.Employees(EmployeeID);
GO

CREATE TABLE HR.EmployeeAddresses
(
    AddressID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    AddressType VARCHAR(20) NOT NULL DEFAULT 'Current',
    AddressLine1 VARCHAR(200) NOT NULL,
    AddressLine2 VARCHAR(200) NULL,
    City VARCHAR(100) NOT NULL,
    State VARCHAR(100) NULL,
    PostalCode VARCHAR(20) NULL,
    Country VARCHAR(100) NOT NULL DEFAULT 'India',

    CONSTRAINT CK_EmployeeAddresses_Type
        CHECK (AddressType IN ('Current','Permanent')),

    CONSTRAINT FK_EmployeeAddresses_Employee
        FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID)
);
GO

CREATE TABLE HR.EmergencyContacts
(
    EmergencyContactID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    ContactName VARCHAR(100) NOT NULL,
    Relationship VARCHAR(50) NOT NULL,
    Phone VARCHAR(20) NOT NULL,
    Email VARCHAR(150) NULL,

    CONSTRAINT FK_EmergencyContacts_Employee
        FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID)
);
GO

/* ==========================================================
   3. RECRUITMENT
   ========================================================== */

CREATE TABLE HR.Candidates
(
    CandidateID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(150) NOT NULL UNIQUE,
    Phone VARCHAR(20) NULL,
    HighestQualification VARCHAR(150) NULL,
    ExperienceYears DECIMAL(4,1) NOT NULL DEFAULT 0,
    ResumeFileName VARCHAR(255) NULL,
    CandidateStatus VARCHAR(30) NOT NULL DEFAULT 'New',
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Candidates_Experience
        CHECK (ExperienceYears >= 0),

    CONSTRAINT CK_Candidates_Status
        CHECK (CandidateStatus IN
              ('New','Screening','Interview','Selected','Rejected','Hired'))
);
GO

CREATE TABLE HR.JobOpenings
(
    JobOpeningID INT IDENTITY(1,1) PRIMARY KEY,
    JobTitleID INT NOT NULL,
    DepartmentID INT NOT NULL,
    BranchID INT NOT NULL,
    OpenDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    CloseDate DATE NULL,
    NumberOfPositions INT NOT NULL DEFAULT 1,
    EmploymentType VARCHAR(30) NOT NULL DEFAULT 'Full-Time',
    OpeningStatus VARCHAR(20) NOT NULL DEFAULT 'Open',

    CONSTRAINT CK_JobOpenings_Positions
        CHECK (NumberOfPositions > 0),

    CONSTRAINT CK_JobOpenings_Dates
        CHECK (CloseDate IS NULL OR CloseDate >= OpenDate),

    CONSTRAINT CK_JobOpenings_Type
        CHECK (EmploymentType IN
              ('Full-Time','Part-Time','Contract','Internship')),

    CONSTRAINT CK_JobOpenings_Status
        CHECK (OpeningStatus IN ('Open','Closed','OnHold')),

    CONSTRAINT FK_JobOpenings_JobTitle
        FOREIGN KEY (JobTitleID) REFERENCES HR.JobTitles(JobTitleID),

    CONSTRAINT FK_JobOpenings_Department
        FOREIGN KEY (DepartmentID) REFERENCES HR.Departments(DepartmentID),

    CONSTRAINT FK_JobOpenings_Branch
        FOREIGN KEY (BranchID) REFERENCES HR.Branches(BranchID)
);
GO

CREATE TABLE HR.Applications
(
    ApplicationID INT IDENTITY(1,1) PRIMARY KEY,
    CandidateID INT NOT NULL,
    JobOpeningID INT NOT NULL,
    ApplicationDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    ApplicationStatus VARCHAR(30) NOT NULL DEFAULT 'Applied',
    Source VARCHAR(50) NULL,

    CONSTRAINT CK_Applications_Status
        CHECK (ApplicationStatus IN
              ('Applied','Shortlisted','Interview','Selected','Rejected','Withdrawn')),

    CONSTRAINT FK_Applications_Candidate
        FOREIGN KEY (CandidateID) REFERENCES HR.Candidates(CandidateID),

    CONSTRAINT FK_Applications_JobOpening
        FOREIGN KEY (JobOpeningID) REFERENCES HR.JobOpenings(JobOpeningID),

    CONSTRAINT UQ_Applications_Candidate_Job
        UNIQUE (CandidateID, JobOpeningID)
);
GO

CREATE TABLE HR.Interviews
(
    InterviewID INT IDENTITY(1,1) PRIMARY KEY,
    ApplicationID INT NOT NULL,
    InterviewerEmployeeID INT NULL,
    InterviewDate DATETIME2 NOT NULL,
    InterviewRound INT NOT NULL DEFAULT 1,
    InterviewMode VARCHAR(20) NOT NULL DEFAULT 'Online',
    Result VARCHAR(20) NOT NULL DEFAULT 'Pending',
    Feedback VARCHAR(1000) NULL,

    CONSTRAINT CK_Interviews_Round
        CHECK (InterviewRound > 0),

    CONSTRAINT CK_Interviews_Mode
        CHECK (InterviewMode IN ('Online','In-Person','Phone')),

    CONSTRAINT CK_Interviews_Result
        CHECK (Result IN ('Pending','Pass','Fail','Hold')),

    CONSTRAINT FK_Interviews_Application
        FOREIGN KEY (ApplicationID) REFERENCES HR.Applications(ApplicationID),

    CONSTRAINT FK_Interviews_Interviewer
        FOREIGN KEY (InterviewerEmployeeID) REFERENCES HR.Employees(EmployeeID)
);
GO

/* ==========================================================
   4. ATTENDANCE & LEAVE
   ========================================================== */

CREATE TABLE HR.Attendance
(
    AttendanceID BIGINT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    AttendanceDate DATE NOT NULL,
    CheckIn DATETIME2 NULL,
    CheckOut DATETIME2 NULL,
    AttendanceStatus VARCHAR(20) NOT NULL DEFAULT 'Present',
    OvertimeHours DECIMAL(5,2) NOT NULL DEFAULT 0,

    CONSTRAINT UQ_Attendance_Employee_Date
        UNIQUE (EmployeeID, AttendanceDate),

    CONSTRAINT CK_Attendance_Status
        CHECK (AttendanceStatus IN
              ('Present','Absent','Half-Day','Leave','Holiday')),

    CONSTRAINT CK_Attendance_Overtime
        CHECK (OvertimeHours >= 0),

    CONSTRAINT FK_Attendance_Employee
        FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID)
);
GO

CREATE TABLE HR.LeaveTypes
(
    LeaveTypeID INT IDENTITY(1,1) PRIMARY KEY,
    LeaveTypeName VARCHAR(50) NOT NULL UNIQUE,
    AnnualLimit DECIMAL(5,2) NOT NULL,
    IsPaid BIT NOT NULL DEFAULT 1,

    CONSTRAINT CK_LeaveTypes_Limit
        CHECK (AnnualLimit >= 0)
);
GO

CREATE TABLE HR.LeaveBalances
(
    LeaveBalanceID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    LeaveTypeID INT NOT NULL,
    LeaveYear INT NOT NULL,
    AllocatedDays DECIMAL(5,2) NOT NULL DEFAULT 0,
    UsedDays DECIMAL(5,2) NOT NULL DEFAULT 0,

    CONSTRAINT UQ_LeaveBalances
        UNIQUE (EmployeeID, LeaveTypeID, LeaveYear),

    CONSTRAINT CK_LeaveBalances_Days
        CHECK (AllocatedDays >= 0 AND UsedDays >= 0 AND UsedDays <= AllocatedDays),

    CONSTRAINT FK_LeaveBalances_Employee
        FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID),

    CONSTRAINT FK_LeaveBalances_Type
        FOREIGN KEY (LeaveTypeID) REFERENCES HR.LeaveTypes(LeaveTypeID)
);
GO

CREATE TABLE HR.LeaveRequests
(
    LeaveRequestID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    LeaveTypeID INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    Reason VARCHAR(500) NULL,
    RequestStatus VARCHAR(20) NOT NULL DEFAULT 'Pending',
    ApprovedBy INT NULL,
    ApprovedAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT CK_LeaveRequests_Dates
        CHECK (EndDate >= StartDate),

    CONSTRAINT CK_LeaveRequests_Status
        CHECK (RequestStatus IN ('Pending','Approved','Rejected','Cancelled')),

    CONSTRAINT FK_LeaveRequests_Employee
        FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID),

    CONSTRAINT FK_LeaveRequests_Type
        FOREIGN KEY (LeaveTypeID) REFERENCES HR.LeaveTypes(LeaveTypeID),

    CONSTRAINT FK_LeaveRequests_Approver
        FOREIGN KEY (ApprovedBy) REFERENCES HR.Employees(EmployeeID)
);
GO

/* ==========================================================
   5. PAYROLL
   ========================================================== */

CREATE TABLE Payroll.SalaryStructures
(
    SalaryStructureID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    EffectiveFrom DATE NOT NULL,
    BasicSalary DECIMAL(12,2) NOT NULL,
    HRA DECIMAL(12,2) NOT NULL DEFAULT 0,
    ConveyanceAllowance DECIMAL(12,2) NOT NULL DEFAULT 0,
    MedicalAllowance DECIMAL(12,2) NOT NULL DEFAULT 0,
    OtherAllowance DECIMAL(12,2) NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,

    CONSTRAINT CK_SalaryStructures_Amounts
        CHECK
        (
            BasicSalary >= 0 AND
            HRA >= 0 AND
            ConveyanceAllowance >= 0 AND
            MedicalAllowance >= 0 AND
            OtherAllowance >= 0
        ),

    CONSTRAINT FK_SalaryStructures_Employee
        FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID)
);
GO

CREATE TABLE Payroll.PayrollRuns
(
    PayrollRunID INT IDENTITY(1,1) PRIMARY KEY,
    PayrollMonth DATE NOT NULL,
    ProcessedAt DATETIME2 NULL,
    ProcessedBy VARCHAR(100) NULL,
    RunStatus VARCHAR(20) NOT NULL DEFAULT 'Draft',
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT UQ_PayrollRuns_Month UNIQUE (PayrollMonth),

    CONSTRAINT CK_PayrollRuns_Status
        CHECK (RunStatus IN ('Draft','Processing','Completed','Cancelled'))
);
GO

CREATE TABLE Payroll.Payslips
(
    PayslipID BIGINT IDENTITY(1,1) PRIMARY KEY,
    PayrollRunID INT NOT NULL,
    EmployeeID INT NOT NULL,
    BasicSalary DECIMAL(12,2) NOT NULL,
    HRA DECIMAL(12,2) NOT NULL DEFAULT 0,
    Allowances DECIMAL(12,2) NOT NULL DEFAULT 0,
    OvertimePay DECIMAL(12,2) NOT NULL DEFAULT 0,
    GrossSalary AS
        (BasicSalary + HRA + Allowances + OvertimePay) PERSISTED,
    TotalDeductions DECIMAL(12,2) NOT NULL DEFAULT 0,
    NetSalary AS
        (BasicSalary + HRA + Allowances + OvertimePay - TotalDeductions) PERSISTED,
    PaymentStatus VARCHAR(20) NOT NULL DEFAULT 'Pending',
    PaymentDate DATE NULL,

    CONSTRAINT UQ_Payslips_Run_Employee
        UNIQUE (PayrollRunID, EmployeeID),

    CONSTRAINT CK_Payslips_Amounts
        CHECK
        (
            BasicSalary >= 0 AND
            HRA >= 0 AND
            Allowances >= 0 AND
            OvertimePay >= 0 AND
            TotalDeductions >= 0
        ),

    CONSTRAINT CK_Payslips_Status
        CHECK (PaymentStatus IN ('Pending','Paid','Failed')),

    CONSTRAINT FK_Payslips_Run
        FOREIGN KEY (PayrollRunID) REFERENCES Payroll.PayrollRuns(PayrollRunID),

    CONSTRAINT FK_Payslips_Employee
        FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID)
);
GO

CREATE TABLE Payroll.PayrollDeductions
(
    PayrollDeductionID BIGINT IDENTITY(1,1) PRIMARY KEY,
    PayslipID BIGINT NOT NULL,
    DeductionType VARCHAR(50) NOT NULL,
    Amount DECIMAL(12,2) NOT NULL,
    Description VARCHAR(300) NULL,

    CONSTRAINT CK_PayrollDeductions_Amount
        CHECK (Amount >= 0),

    CONSTRAINT FK_PayrollDeductions_Payslip
        FOREIGN KEY (PayslipID) REFERENCES Payroll.Payslips(PayslipID)
);
GO

/* ==========================================================
   6. PROJECT MANAGEMENT
   ========================================================== */

CREATE TABLE Projects.Projects
(
    ProjectID INT IDENTITY(1,1) PRIMARY KEY,
    ProjectName VARCHAR(150) NOT NULL UNIQUE,
    ClientName VARCHAR(150) NULL,
    ProjectManagerID INT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    Budget DECIMAL(15,2) NOT NULL DEFAULT 0,
    ProjectStatus VARCHAR(20) NOT NULL DEFAULT 'Planned',

    CONSTRAINT CK_Projects_Dates
        CHECK (EndDate IS NULL OR EndDate >= StartDate),

    CONSTRAINT CK_Projects_Budget
        CHECK (Budget >= 0),

    CONSTRAINT CK_Projects_Status
        CHECK (ProjectStatus IN
              ('Planned','Active','Completed','OnHold','Cancelled')),

    CONSTRAINT FK_Projects_Manager
        FOREIGN KEY (ProjectManagerID) REFERENCES HR.Employees(EmployeeID)
);
GO

CREATE TABLE Projects.ProjectAssignments
(
    AssignmentID INT IDENTITY(1,1) PRIMARY KEY,
    ProjectID INT NOT NULL,
    EmployeeID INT NOT NULL,
    RoleName VARCHAR(100) NOT NULL,
    AllocationPercent DECIMAL(5,2) NOT NULL DEFAULT 100,
    AssignedDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    ReleasedDate DATE NULL,

    CONSTRAINT UQ_ProjectAssignments
        UNIQUE (ProjectID, EmployeeID),

    CONSTRAINT CK_ProjectAssignments_Allocation
        CHECK (AllocationPercent > 0 AND AllocationPercent <= 100),

    CONSTRAINT CK_ProjectAssignments_Dates
        CHECK (ReleasedDate IS NULL OR ReleasedDate >= AssignedDate),

    CONSTRAINT FK_ProjectAssignments_Project
        FOREIGN KEY (ProjectID) REFERENCES Projects.Projects(ProjectID),

    CONSTRAINT FK_ProjectAssignments_Employee
        FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID)
);
GO

CREATE TABLE Projects.Tasks
(
    TaskID INT IDENTITY(1,1) PRIMARY KEY,
    ProjectID INT NOT NULL,
    AssignedToEmployeeID INT NULL,
    TaskName VARCHAR(200) NOT NULL,
    Description VARCHAR(1000) NULL,
    StartDate DATE NULL,
    DueDate DATE NULL,
    CompletionDate DATE NULL,
    TaskStatus VARCHAR(20) NOT NULL DEFAULT 'Pending',
    Priority VARCHAR(20) NOT NULL DEFAULT 'Medium',

    CONSTRAINT CK_Tasks_Dates
        CHECK
        (
            DueDate IS NULL OR StartDate IS NULL OR DueDate >= StartDate
        ),

    CONSTRAINT CK_Tasks_Status
        CHECK (TaskStatus IN
              ('Pending','In Progress','Completed','Blocked','Cancelled')),

    CONSTRAINT CK_Tasks_Priority
        CHECK (Priority IN ('Low','Medium','High','Critical')),

    CONSTRAINT FK_Tasks_Project
        FOREIGN KEY (ProjectID) REFERENCES Projects.Projects(ProjectID),

    CONSTRAINT FK_Tasks_Employee
        FOREIGN KEY (AssignedToEmployeeID) REFERENCES HR.Employees(EmployeeID)
);
GO

CREATE TABLE Projects.TimeLogs
(
    TimeLogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ProjectID INT NOT NULL,
    EmployeeID INT NOT NULL,
    WorkDate DATE NOT NULL,
    HoursWorked DECIMAL(5,2) NOT NULL,
    Description VARCHAR(500) NULL,

    CONSTRAINT CK_TimeLogs_Hours
        CHECK (HoursWorked > 0 AND HoursWorked <= 24),

    CONSTRAINT UQ_TimeLogs
        UNIQUE (ProjectID, EmployeeID, WorkDate),

    CONSTRAINT FK_TimeLogs_Project
        FOREIGN KEY (ProjectID) REFERENCES Projects.Projects(ProjectID),

    CONSTRAINT FK_TimeLogs_Employee
        FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID)
);
GO

/* ==========================================================
   7. PERFORMANCE & TRAINING
   ========================================================== */

CREATE TABLE HR.PerformanceReviews
(
    PerformanceReviewID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    ReviewerEmployeeID INT NOT NULL,
    ReviewPeriodStart DATE NOT NULL,
    ReviewPeriodEnd DATE NOT NULL,
    ReviewDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    Rating DECIMAL(3,1) NOT NULL,
    Strengths VARCHAR(1000) NULL,
    ImprovementAreas VARCHAR(1000) NULL,
    Comments VARCHAR(2000) NULL,

    CONSTRAINT CK_PerformanceReviews_Dates
        CHECK (ReviewPeriodEnd >= ReviewPeriodStart),

    CONSTRAINT CK_PerformanceReviews_Rating
        CHECK (Rating >= 0 AND Rating <= 5),

    CONSTRAINT FK_PerformanceReviews_Employee
        FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID),

    CONSTRAINT FK_PerformanceReviews_Reviewer
        FOREIGN KEY (ReviewerEmployeeID) REFERENCES HR.Employees(EmployeeID)
);
GO

CREATE TABLE HR.TrainingCourses
(
    TrainingCourseID INT IDENTITY(1,1) PRIMARY KEY,
    CourseName VARCHAR(150) NOT NULL UNIQUE,
    Description VARCHAR(1000) NULL,
    Provider VARCHAR(150) NULL,
    DurationHours DECIMAL(6,2) NOT NULL,
    Cost DECIMAL(12,2) NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,

    CONSTRAINT CK_TrainingCourses_Duration
        CHECK (DurationHours > 0),

    CONSTRAINT CK_TrainingCourses_Cost
        CHECK (Cost >= 0)
);
GO

CREATE TABLE HR.EmployeeTraining
(
    EmployeeTrainingID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    TrainingCourseID INT NOT NULL,
    EnrollmentDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    CompletionDate DATE NULL,
    TrainingStatus VARCHAR(20) NOT NULL DEFAULT 'Enrolled',
    Score DECIMAL(5,2) NULL,
    CertificateNo VARCHAR(100) NULL,

    CONSTRAINT UQ_EmployeeTraining
        UNIQUE (EmployeeID, TrainingCourseID, EnrollmentDate),

    CONSTRAINT CK_EmployeeTraining_Status
        CHECK (TrainingStatus IN ('Enrolled','Completed','Failed','Cancelled')),

    CONSTRAINT CK_EmployeeTraining_Score
        CHECK (Score IS NULL OR (Score >= 0 AND Score <= 100)),

    CONSTRAINT FK_EmployeeTraining_Employee
        FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID),

    CONSTRAINT FK_EmployeeTraining_Course
        FOREIGN KEY (TrainingCourseID) REFERENCES HR.TrainingCourses(TrainingCourseID)
);
GO

/* ==========================================================
   8. ASSETS
   ========================================================== */

CREATE TABLE Admin.Assets
(
    AssetID INT IDENTITY(1,1) PRIMARY KEY,
    AssetTag VARCHAR(50) NOT NULL UNIQUE,
    AssetType VARCHAR(50) NOT NULL,
    AssetName VARCHAR(150) NOT NULL,
    SerialNumber VARCHAR(150) NULL UNIQUE,
    PurchaseDate DATE NULL,
    PurchaseCost DECIMAL(12,2) NOT NULL DEFAULT 0,
    AssetStatus VARCHAR(20) NOT NULL DEFAULT 'Available',

    CONSTRAINT CK_Assets_Cost
        CHECK (PurchaseCost >= 0),

    CONSTRAINT CK_Assets_Status
        CHECK (AssetStatus IN
              ('Available','Assigned','Repair','Retired','Lost'))
);
GO

CREATE TABLE Admin.AssetAssignments
(
    AssetAssignmentID INT IDENTITY(1,1) PRIMARY KEY,
    AssetID INT NOT NULL,
    EmployeeID INT NOT NULL,
    AssignedDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    ReturnedDate DATE NULL,
    ConditionAtIssue VARCHAR(100) NULL,
    ConditionAtReturn VARCHAR(100) NULL,
    Notes VARCHAR(500) NULL,

    CONSTRAINT CK_AssetAssignments_Dates
        CHECK (ReturnedDate IS NULL OR ReturnedDate >= AssignedDate),

    CONSTRAINT FK_AssetAssignments_Asset
        FOREIGN KEY (AssetID) REFERENCES Admin.Assets(AssetID),

    CONSTRAINT FK_AssetAssignments_Employee
        FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID)
);
GO

/* ==========================================================
   9. SECURITY & AUDIT
   ========================================================== */

CREATE TABLE Admin.Users
(
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NULL UNIQUE,
    Username VARCHAR(100) NOT NULL UNIQUE,
    PasswordHash VARCHAR(500) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Users_Employee
        FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID)
);
GO

CREATE TABLE Admin.Roles
(
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName VARCHAR(50) NOT NULL UNIQUE,
    Description VARCHAR(300) NULL
);
GO

CREATE TABLE Admin.UserRoles
(
    UserRoleID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    RoleID INT NOT NULL,
    AssignedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT UQ_UserRoles UNIQUE (UserID, RoleID),

    CONSTRAINT FK_UserRoles_User
        FOREIGN KEY (UserID) REFERENCES Admin.Users(UserID),

    CONSTRAINT FK_UserRoles_Role
        FOREIGN KEY (RoleID) REFERENCES Admin.Roles(RoleID)
);
GO

CREATE TABLE Admin.AuditLogs
(
    AuditLogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    TableName VARCHAR(128) NOT NULL,
    RecordID VARCHAR(100) NULL,
    ActionType VARCHAR(20) NOT NULL,
    OldValue VARCHAR(MAX) NULL,
    NewValue VARCHAR(MAX) NULL,
    ChangedBy VARCHAR(128) NULL,
    ChangedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT CK_AuditLogs_Action
        CHECK (ActionType IN ('INSERT','UPDATE','DELETE'))
);
GO

/* ==========================================================
   10. INDEXES
   ========================================================== */

CREATE INDEX IX_Employees_Department
ON HR.Employees(DepartmentID);

CREATE INDEX IX_Employees_JobTitle
ON HR.Employees(JobTitleID);

CREATE INDEX IX_Employees_Manager
ON HR.Employees(ManagerID);

CREATE INDEX IX_Attendance_Employee_Date
ON HR.Attendance(EmployeeID, AttendanceDate);

CREATE INDEX IX_LeaveRequests_Employee_Status
ON HR.LeaveRequests(EmployeeID, RequestStatus);

CREATE INDEX IX_Payslips_Employee
ON Payroll.Payslips(EmployeeID);

CREATE INDEX IX_Payslips_PayrollRun
ON Payroll.Payslips(PayrollRunID);

CREATE INDEX IX_ProjectAssignments_Employee
ON Projects.ProjectAssignments(EmployeeID);

CREATE INDEX IX_TimeLogs_Employee_Date
ON Projects.TimeLogs(EmployeeID, WorkDate);

CREATE INDEX IX_Applications_JobOpening
ON HR.Applications(JobOpeningID);

CREATE INDEX IX_Interviews_Date
ON HR.Interviews(InterviewDate);
GO

/* ==========================================================
   11. SAMPLE MASTER DATA
   ========================================================== */

INSERT INTO HR.Branches
    (BranchName, City, State)
VALUES
    ('Mumbai Head Office','Mumbai','Maharashtra'),
    ('Pune Branch','Pune','Maharashtra'),
    ('Bengaluru Branch','Bengaluru','Karnataka');
GO

INSERT INTO HR.Departments
    (DepartmentName, DepartmentDescription, BranchID)
VALUES
    ('Human Resources','Recruitment and employee management',1),
    ('IT','Software and technology',1),
    ('Finance','Accounting and payroll',1),
    ('Sales','Business development and sales',2),
    ('Marketing','Marketing and advertising',2),
    ('Operations','Business operations',3);
GO

INSERT INTO HR.JobTitles
    (JobTitleName,Grade,MinSalary,MaxSalary)
VALUES
    ('HR Manager','M1',60000,150000),
    ('Software Developer','E1',25000,100000),
    ('Senior Developer','E2',60000,180000),
    ('Accountant','F1',25000,80000),
    ('Sales Executive','S1',20000,70000),
    ('Marketing Executive','MK1',20000,75000),
    ('Operations Manager','O1',50000,140000);
GO

INSERT INTO HR.Employees
(
    FirstName,LastName,Email,Phone,Gender,
    DateOfBirth,HireDate,DepartmentID,JobTitleID,BranchID
)
VALUES
('Amit','Sharma','amit@company.com','9000000001','Male',
 '1990-04-12','2020-01-15',1,1,1),

('Priya','Patil','priya@company.com','9000000002','Female',
 '1995-06-22','2021-03-10',2,3,1),

('Rahul','Verma','rahul@company.com','9000000003','Male',
 '1998-08-19','2022-07-01',2,2,1),

('Neha','Singh','neha@company.com','9000000004','Female',
 '1997-11-05','2023-02-12',3,4,1),

('Vikram','Rao','vikram@company.com','9000000005','Male',
 '1996-03-18','2023-05-20',4,5,2),

('Sneha','Joshi','sneha@company.com','9000000006','Female',
 '1999-09-27','2024-01-08',5,6,2),

('Arjun','Nair','arjun@company.com','9000000007','Male',
 '1992-02-14','2021-09-01',6,7,3);
GO

UPDATE HR.Employees
SET ManagerID = 1001
WHERE EmployeeID IN (1002,1004,1005,1006,1007);

UPDATE HR.Employees
SET ManagerID = 1002
WHERE EmployeeID = 1003;
GO

UPDATE HR.Departments
SET ManagerID =
    CASE DepartmentID
        WHEN 1 THEN 1001
        WHEN 2 THEN 1002
        WHEN 3 THEN 1001
        WHEN 4 THEN 1001
        WHEN 5 THEN 1001
        WHEN 6 THEN 1007
    END;
GO

INSERT INTO HR.EmployeeAddresses
(EmployeeID,AddressType,AddressLine1,City,State,PostalCode)
VALUES
(1001,'Current','101 MG Road','Mumbai','Maharashtra','400001'),
(1002,'Current','202 FC Road','Pune','Maharashtra','411004'),
(1003,'Current','303 Andheri Road','Mumbai','Maharashtra','400058'),
(1004,'Current','404 Baner Road','Pune','Maharashtra','411045'),
(1005,'Current','505 Hinjewadi Road','Pune','Maharashtra','411057'),
(1006,'Current','606 Powai Road','Mumbai','Maharashtra','400076'),
(1007,'Current','707 Whitefield Road','Bengaluru','Karnataka','560066');
GO

INSERT INTO HR.EmergencyContacts
(EmployeeID,ContactName,Relationship,Phone)
VALUES
(1001,'Ramesh Sharma','Father','9100000001'),
(1002,'Sunita Patil','Mother','9100000002'),
(1003,'Suresh Verma','Father','9100000003'),
(1004,'Meena Singh','Mother','9100000004'),
(1005,'Kiran Rao','Brother','9100000005'),
(1006,'Pooja Joshi','Sister','9100000006'),
(1007,'Anil Nair','Father','9100000007');
GO

/* Recruitment sample data */

INSERT INTO HR.Candidates
(FirstName,LastName,Email,Phone,HighestQualification,ExperienceYears,CandidateStatus)
VALUES
('Rohan','Mehta','rohan@example.com','9200000001','B.E. Computer Engineering',2,'Interview'),
('Anjali','Desai','anjali@example.com','9200000002','B.E. AIML',0,'Shortlisted'),
('Karan','Shah','karan@example.com','9200000003','B.Com',3,'New'),
('Pooja','Kulkarni','pooja@example.com','9200000004','MBA Marketing',2,'Selected');
GO

INSERT INTO HR.JobOpenings
(JobTitleID,DepartmentID,BranchID,OpenDate,NumberOfPositions,EmploymentType,OpeningStatus)
VALUES
(2,2,1,'2026-01-01',3,'Full-Time','Open'),
(4,3,1,'2026-02-01',1,'Full-Time','Open'),
(6,5,2,'2026-02-15',2,'Full-Time','Open'),
(5,4,2,'2026-03-01',2,'Full-Time','Open');
GO

INSERT INTO HR.Applications
(CandidateID,JobOpeningID,ApplicationDate,ApplicationStatus,Source)
VALUES
(1,1,'2026-01-05','Interview','LinkedIn'),
(2,1,'2026-01-10','Shortlisted','Company Website'),
(3,2,'2026-02-05','Applied','Referral'),
(4,3,'2026-02-20','Selected','LinkedIn');
GO

INSERT INTO HR.Interviews
(ApplicationID,InterviewerEmployeeID,InterviewDate,InterviewRound,InterviewMode,Result,Feedback)
VALUES
(1,1002,'2026-01-15 11:00','1','Online','Pass','Good technical fundamentals'),
(2,1002,'2026-01-18 14:00','1','Online','Pending','Awaiting technical round'),
(4,1006,'2026-02-25 15:00','1','In-Person','Pass','Strong marketing experience');
GO

/* Attendance */

INSERT INTO HR.Attendance
(EmployeeID,AttendanceDate,CheckIn,CheckOut,AttendanceStatus,OvertimeHours)
VALUES
(1001,'2026-09-01','2026-09-01 09:00','2026-09-01 18:00','Present',0),
(1002,'2026-09-01','2026-09-01 09:10','2026-09-01 19:00','Present',1),
(1003,'2026-09-01','2026-09-01 09:05','2026-09-01 18:00','Present',0),
(1004,'2026-09-01','2026-09-01 09:00','2026-09-01 18:00','Present',0),
(1005,'2026-09-01','2026-09-01 09:20','2026-09-01 18:30','Present',0.5),
(1006,'2026-09-01','2026-09-01 09:00','2026-09-01 18:00','Present',0),
(1007,'2026-09-01','2026-09-01 08:50','2026-09-01 18:00','Present',0);
GO

INSERT INTO HR.LeaveTypes
(LeaveTypeName,AnnualLimit,IsPaid)
VALUES
('Casual Leave',12,1),
('Sick Leave',12,1),
('Earned Leave',18,1),
('Loss of Pay',365,0);
GO

INSERT INTO HR.LeaveBalances
(EmployeeID,LeaveTypeID,LeaveYear,AllocatedDays,UsedDays)
SELECT EmployeeID,LeaveTypeID,2026,AnnualLimit,0
FROM HR.Employees
CROSS JOIN HR.LeaveTypes
WHERE LeaveTypeName <> 'Loss of Pay';
GO

INSERT INTO HR.LeaveRequests
(EmployeeID,LeaveTypeID,StartDate,EndDate,Reason,RequestStatus)
VALUES
(1003,1,'2026-09-10','2026-09-11','Personal work','Pending'),
(1005,2,'2026-09-15','2026-09-16','Medical appointment','Approved');
GO

/* Payroll */

INSERT INTO Payroll.SalaryStructures
(EmployeeID,EffectiveFrom,BasicSalary,HRA,ConveyanceAllowance,MedicalAllowance,OtherAllowance)
VALUES
(1001,'2026-01-01',80000,32000,5000,3000,5000),
(1002,'2026-01-01',90000,36000,5000,3000,7000),
(1003,'2026-01-01',45000,18000,3000,2000,3000),
(1004,'2026-01-01',50000,20000,3000,2000,3000),
(1005,'2026-01-01',40000,16000,3000,2000,2500),
(1006,'2026-01-01',42000,16800,3000,2000,2500),
(1007,'2026-01-01',75000,30000,5000,3000,5000);
GO

INSERT INTO Payroll.PayrollRuns
(PayrollMonth,ProcessedAt,ProcessedBy,RunStatus)
VALUES
('2026-08-01',SYSDATETIME(),'HR Admin','Completed'),
('2026-09-01',SYSDATETIME(),'HR Admin','Completed');
GO

INSERT INTO Payroll.Payslips
(PayrollRunID,EmployeeID,BasicSalary,HRA,Allowances,OvertimePay,TotalDeductions,PaymentStatus,PaymentDate)
SELECT
    PR.PayrollRunID,
    SS.EmployeeID,
    SS.BasicSalary,
    SS.HRA,
    SS.ConveyanceAllowance + SS.MedicalAllowance + SS.OtherAllowance,
    0,
    ROUND((SS.BasicSalary + SS.HRA +
           SS.ConveyanceAllowance + SS.MedicalAllowance +
           SS.OtherAllowance) * 0.10,2),
    'Paid',
    DATEADD(DAY,5,PR.PayrollMonth)
FROM Payroll.PayrollRuns PR
CROSS JOIN Payroll.SalaryStructures SS
WHERE SS.IsActive = 1;
GO

INSERT INTO Payroll.PayrollDeductions
(PayslipID,DeductionType,Amount,Description)
SELECT PayslipID,'PF',ROUND(GrossSalary * 0.05,2),'Employee PF contribution'
FROM Payroll.Payslips;
GO

/* Projects */

INSERT INTO Projects.Projects
(ProjectName,ClientName,ProjectManagerID,StartDate,EndDate,Budget,ProjectStatus)
VALUES
('HR Management System','Internal',1002,'2026-01-01','2026-12-31',2500000,'Active'),
('Payroll Automation','Internal',1001,'2026-02-01','2026-10-31',1200000,'Active'),
('Customer Portal','ABC Technologies',1002,'2026-03-01','2026-09-30',1800000,'Completed');
GO

INSERT INTO Projects.ProjectAssignments
(ProjectID,EmployeeID,RoleName,AllocationPercent,AssignedDate)
VALUES
(1,1002,'Technical Lead',100,'2026-01-01'),
(1,1003,'Developer',100,'2026-01-05'),
(1,1004,'Business Analyst',50,'2026-01-10'),
(2,1002,'Technical Lead',50,'2026-02-01'),
(2,1003,'Developer',50,'2026-02-01'),
(2,1004,'Finance Analyst',50,'2026-02-01'),
(3,1002,'Technical Lead',50,'2026-03-01'),
(3,1005,'Sales Consultant',50,'2026-03-01');
GO

INSERT INTO Projects.Tasks
(ProjectID,AssignedToEmployeeID,TaskName,Description,StartDate,DueDate,TaskStatus,Priority)
VALUES
(1,1003,'Employee Module','Create employee CRUD module','2026-01-10','2026-02-15','Completed','High'),
(1,1004,'Requirements Analysis','Prepare requirements','2026-01-05','2026-01-20','Completed','High'),
(2,1003,'Payroll Calculation','Build salary calculation logic','2026-02-10','2026-04-01','In Progress','Critical'),
(3,1005,'Client Testing','Support UAT','2026-07-01','2026-08-15','Completed','Medium');
GO

INSERT INTO Projects.TimeLogs
(ProjectID,EmployeeID,WorkDate,HoursWorked,Description)
VALUES
(1,1003,'2026-09-01',8,'Employee module development'),
(1,1002,'2026-09-01',7,'Architecture and review'),
(2,1003,'2026-09-01',8,'Payroll calculation'),
(2,1004,'2026-09-01',6,'Payroll validation'),
(3,1005,'2026-08-01',5,'Client testing');
GO

/* Performance */

INSERT INTO HR.PerformanceReviews
(EmployeeID,ReviewerEmployeeID,ReviewPeriodStart,ReviewPeriodEnd,ReviewDate,Rating,Strengths,ImprovementAreas,Comments)
VALUES
(1003,1002,'2026-01-01','2026-06-30','2026-07-05',4.2,
 'Good coding skills','Improve documentation','Strong technical performance'),
(1004,1001,'2026-01-01','2026-06-30','2026-07-05',4.0,
 'Good accounting knowledge','Improve automation skills','Reliable employee'),
(1005,1001,'2026-01-01','2026-06-30','2026-07-05',3.8,
 'Good communication','Improve reporting','Consistent performance');
GO

INSERT INTO HR.TrainingCourses
(CourseName,Description,Provider,DurationHours,Cost)
VALUES
('SQL Server Advanced','Advanced SQL Server concepts','Internal Academy',20,5000),
('ASP.NET Core','Web API and MVC development','External Training',30,12000),
('Leadership Skills','People management training','Internal Academy',12,3000),
('Power BI','Business intelligence and dashboards','External Training',16,8000);
GO

INSERT INTO HR.EmployeeTraining
(EmployeeID,TrainingCourseID,EnrollmentDate,CompletionDate,TrainingStatus,Score,CertificateNo)
VALUES
(1003,1,'2026-06-01','2026-06-20','Completed',88,'SQL-2026-001'),
(1002,2,'2026-05-01','2026-06-15','Completed',92,'NET-2026-002'),
(1001,3,'2026-07-01',NULL,'Enrolled',NULL,NULL),
(1004,4,'2026-07-10','2026-08-01','Completed',85,'PBI-2026-004');
GO

/* Assets */

INSERT INTO Admin.Assets
(AssetTag,AssetType,AssetName,SerialNumber,PurchaseDate,PurchaseCost,AssetStatus)
VALUES
('LAP-001','Laptop','Dell Latitude','DL10001','2025-01-10',85000,'Assigned'),
('LAP-002','Laptop','HP ProBook','HP10002','2025-02-10',75000,'Assigned'),
('MON-001','Monitor','Dell 24 Inch Monitor','MON10001','2025-03-10',15000,'Available'),
('MOB-001','Mobile','Samsung Galaxy','SAM10001','2025-04-10',35000,'Assigned');
GO

INSERT INTO Admin.AssetAssignments
(AssetID,EmployeeID,AssignedDate,ConditionAtIssue)
VALUES
(1,1003,'2026-01-10','New'),
(2,1002,'2026-01-15','New'),
(4,1005,'2026-02-01','New');
GO

/* Security */

INSERT INTO Admin.Users
(EmployeeID,Username,PasswordHash)
VALUES
(1001,'amit.admin','DEMO_HASH_NOT_REAL'),
(1002,'priya.it','DEMO_HASH_NOT_REAL'),
(1004,'neha.finance','DEMO_HASH_NOT_REAL');
GO

INSERT INTO Admin.Roles
(RoleName,Description)
VALUES
('Administrator','Full system administration'),
('HR Manager','HR and employee management'),
('Finance','Payroll and finance access'),
('Employee','Basic employee access'),
('Project Manager','Project management access');
GO

INSERT INTO Admin.UserRoles
(UserID,RoleID)
VALUES
(1,1),
(2,5),
(3,3);
GO

/* ==========================================================
   12. VIEWS
   ========================================================== */

CREATE VIEW HR.vw_EmployeeDetails
AS
SELECT
    E.EmployeeID,
    E.FirstName + ' ' + E.LastName AS EmployeeName,
    E.Email,
    E.Phone,
    D.DepartmentName,
    J.JobTitleName,
    B.BranchName,
    E.HireDate,
    E.EmploymentStatus,
    M.FirstName + ' ' + M.LastName AS ManagerName
FROM HR.Employees E
JOIN HR.Departments D ON E.DepartmentID = D.DepartmentID
JOIN HR.JobTitles J ON E.JobTitleID = J.JobTitleID
JOIN HR.Branches B ON E.BranchID = B.BranchID
LEFT JOIN HR.Employees M ON E.ManagerID = M.EmployeeID;
GO

CREATE VIEW Payroll.vw_PayslipSummary
AS
SELECT
    P.PayslipID,
    PR.PayrollMonth,
    E.EmployeeID,
    E.FirstName + ' ' + E.LastName AS EmployeeName,
    P.BasicSalary,
    P.HRA,
    P.Allowances,
    P.OvertimePay,
    P.GrossSalary,
    P.TotalDeductions,
    P.NetSalary,
    P.PaymentStatus
FROM Payroll.Payslips P
JOIN Payroll.PayrollRuns PR ON P.PayrollRunID = PR.PayrollRunID
JOIN HR.Employees E ON P.EmployeeID = E.EmployeeID;
GO

CREATE VIEW Projects.vw_ProjectSummary
AS
SELECT
    P.ProjectID,
    P.ProjectName,
    P.ClientName,
    P.ProjectStatus,
    P.Budget,
    COUNT(PA.AssignmentID) AS TeamSize,
    ISNULL(SUM(TL.HoursWorked),0) AS TotalHours
FROM Projects.Projects P
LEFT JOIN Projects.ProjectAssignments PA
    ON P.ProjectID = PA.ProjectID
LEFT JOIN Projects.TimeLogs TL
    ON P.ProjectID = TL.ProjectID
GROUP BY
    P.ProjectID,P.ProjectName,P.ClientName,
    P.ProjectStatus,P.Budget;
GO

/* ==========================================================
   13. FUNCTIONS
   ========================================================== */

CREATE FUNCTION HR.fn_EmployeeTenureYears
(
    @HireDate DATE
)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(YEAR,@HireDate,CAST(GETDATE() AS DATE))
         - CASE
             WHEN DATEADD(YEAR,DATEDIFF(YEAR,@HireDate,CAST(GETDATE() AS DATE)),@HireDate)
                  > CAST(GETDATE() AS DATE)
             THEN 1 ELSE 0
           END;
END;
GO

CREATE FUNCTION Payroll.fn_GrossSalary
(
    @BasicSalary DECIMAL(12,2),
    @HRA DECIMAL(12,2),
    @Allowances DECIMAL(12,2),
    @OvertimePay DECIMAL(12,2)
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    RETURN @BasicSalary + @HRA + @Allowances + @OvertimePay;
END;
GO

CREATE FUNCTION HR.fn_GetEmployeesByDepartment
(
    @DepartmentID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        EmployeeID,
        FirstName,
        LastName,
        Email,
        HireDate,
        EmploymentStatus
    FROM HR.Employees
    WHERE DepartmentID = @DepartmentID
);
GO

/* ==========================================================
   14. STORED PROCEDURES
   ========================================================== */

CREATE PROCEDURE HR.usp_GetEmployee
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM HR.vw_EmployeeDetails
    WHERE EmployeeID = @EmployeeID;
END;
GO

CREATE PROCEDURE HR.usp_GetEmployeesByDepartment
    @DepartmentID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM HR.vw_EmployeeDetails
    WHERE EmployeeID IN
    (
        SELECT EmployeeID
        FROM HR.Employees
        WHERE DepartmentID = @DepartmentID
    );
END;
GO

CREATE PROCEDURE HR.usp_AddEmployee
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @Email VARCHAR(150),
    @Phone VARCHAR(20),
    @Gender VARCHAR(20),
    @DateOfBirth DATE,
    @HireDate DATE,
    @DepartmentID INT,
    @JobTitleID INT,
    @BranchID INT,
    @ManagerID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO HR.Employees
    (
        FirstName,LastName,Email,Phone,Gender,
        DateOfBirth,HireDate,DepartmentID,
        JobTitleID,BranchID,ManagerID
    )
    VALUES
    (
        @FirstName,@LastName,@Email,@Phone,@Gender,
        @DateOfBirth,@HireDate,@DepartmentID,
        @JobTitleID,@BranchID,@ManagerID
    );

    SELECT SCOPE_IDENTITY() AS NewEmployeeID;
END;
GO

CREATE PROCEDURE Payroll.usp_GetMonthlyPayroll
    @PayrollMonth DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Payroll.vw_PayslipSummary
    WHERE PayrollMonth = @PayrollMonth;
END;
GO

CREATE PROCEDURE Projects.usp_GetProjectReport
    @ProjectID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Projects.vw_ProjectSummary
    WHERE ProjectID = @ProjectID;

    SELECT
        P.ProjectName,
        E.FirstName + ' ' + E.LastName AS EmployeeName,
        PA.RoleName,
        PA.AllocationPercent
    FROM Projects.ProjectAssignments PA
    JOIN Projects.Projects P ON PA.ProjectID = P.ProjectID
    JOIN HR.Employees E ON PA.EmployeeID = E.EmployeeID
    WHERE PA.ProjectID = @ProjectID;
END;
GO

/* ==========================================================
   15. TRIGGERS
   ========================================================== */

CREATE TRIGGER HR.trg_Employee_Audit
ON HR.Employees
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Admin.AuditLogs
    (
        TableName,RecordID,ActionType,
        OldValue,NewValue,ChangedBy
    )
    SELECT
        'HR.Employees',
        CAST(COALESCE(I.EmployeeID,D.EmployeeID) AS VARCHAR(100)),
        CASE
            WHEN I.EmployeeID IS NOT NULL AND D.EmployeeID IS NULL THEN 'INSERT'
            WHEN I.EmployeeID IS NULL AND D.EmployeeID IS NOT NULL THEN 'DELETE'
            ELSE 'UPDATE'
        END,
        CASE
            WHEN D.EmployeeID IS NULL THEN NULL
            ELSE
                'Name=' + D.FirstName + ' ' + D.LastName +
                ';Status=' + D.EmploymentStatus
        END,
        CASE
            WHEN I.EmployeeID IS NULL THEN NULL
            ELSE
                'Name=' + I.FirstName + ' ' + I.LastName +
                ';Status=' + I.EmploymentStatus
        END,
        SUSER_SNAME()
    FROM inserted I
    FULL OUTER JOIN deleted D
        ON I.EmployeeID = D.EmployeeID;
END;
GO

CREATE TRIGGER Admin.trg_AssetAssignment_Status
ON Admin.AssetAssignments
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE A
    SET AssetStatus =
        CASE
            WHEN IA.ReturnedDate IS NULL THEN 'Assigned'
            ELSE 'Available'
        END
    FROM Admin.Assets A
    JOIN inserted IA
        ON A.AssetID = IA.AssetID;
END;
GO

/* ==========================================================
   16. REPORTING QUERIES
   ========================================================== */

-- Employee count by department
SELECT
    D.DepartmentName,
    COUNT(E.EmployeeID) AS EmployeeCount
FROM HR.Departments D
LEFT JOIN HR.Employees E
    ON D.DepartmentID = E.DepartmentID
GROUP BY D.DepartmentName
ORDER BY EmployeeCount DESC;
GO

-- Salary report
SELECT
    E.EmployeeID,
    E.FirstName + ' ' + E.LastName AS EmployeeName,
    D.DepartmentName,
    P.GrossSalary,
    P.TotalDeductions,
    P.NetSalary
FROM Payroll.Payslips P
JOIN HR.Employees E ON P.EmployeeID = E.EmployeeID
JOIN HR.Departments D ON E.DepartmentID = D.DepartmentID
ORDER BY P.NetSalary DESC;
GO

-- Project report
SELECT *
FROM Projects.vw_ProjectSummary;
GO

-- Training completion
SELECT
    E.FirstName + ' ' + E.LastName AS EmployeeName,
    T.CourseName,
    ET.TrainingStatus,
    ET.Score
FROM HR.EmployeeTraining ET
JOIN HR.Employees E
    ON ET.EmployeeID = E.EmployeeID
JOIN HR.TrainingCourses T
    ON ET.TrainingCourseID = T.TrainingCourseID;
GO

/* ==========================================================
   17. VERIFICATION
   ========================================================== */

SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables t
JOIN sys.schemas s
    ON t.schema_id = s.schema_id
ORDER BY s.name,t.name;
GO

SELECT COUNT(*) AS TotalTables
FROM sys.tables;
GO

PRINT '====================================================';
PRINT 'CompanyManagementDB created successfully.';
PRINT '31-table Enterprise HR & Payroll project is ready.';
PRINT '====================================================';
GO
