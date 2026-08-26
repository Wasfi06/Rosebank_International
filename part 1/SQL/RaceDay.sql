IF DB_ID('RaceDay') IS NOT NULL
BEGIN
    ALTER DATABASE RaceDay SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDay;
END;

/*the above code checks whether the databse exists whereas in this case "RaceDay"*/

CREATE DATABASE RaceDay;

USE RaceDay;
/*5 tables created*/
CREATE TABLE Users (
    UserId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_User PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(150) NOT NULL CONSTRAINT UQ_User_Email UNIQUE,
    PasswordHash VARCHAR(500) NOT NULL,
    Role VARCHAR(20) NOT NULL,
    Phone VARCHAR(30) NULL,
    ProfileImageUrl VARCHAR(500) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_User_CreatedAt DEFAULT SYSUTCDATETIME(),
    IsActive BIT NOT NULL CONSTRAINT DF_User_IsActive DEFAULT 1,
    CONSTRAINT CK_User_Role CHECK (Role IN ('Organizer','Participant'))
);

CREATE TABLE Event (
    EventId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Event PRIMARY KEY,
    OrganizerId INT NOT NULL,
    Name VARCHAR(150) NOT NULL,
    Description VARCHAR(1000) NOT NULL,
    EventDate DATETIME2(0) NOT NULL,
    Location VARCHAR(200) NOT NULL,
    DistanceKm DECIMAL(6,2) NOT NULL,
    EventType VARCHAR(30) NOT NULL,
    RouteUrl VARCHAR(500) NULL,
    RouteDescription VARCHAR(1000) NULL,
    BannerImageUrl VARCHAR(500) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Event_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Event_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Event_Organizer FOREIGN KEY (OrganizerId) REFERENCES Users(UserId),
    CONSTRAINT CK_Event_Distance CHECK (DistanceKm > 0),
    CONSTRAINT CK_Event_Type CHECK (EventType IN ('Running','Walking','Cycling'))
);

CREATE TABLE Category (
    CategoryId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Category PRIMARY KEY,
    EventId INT NOT NULL,
    Name VARCHAR(100) NOT NULL,
    CategoryType VARCHAR(20) NOT NULL,
    MinAge INT NULL,
    MaxAge INT NULL,
    MinDistanceKm DECIMAL(6,2) NULL,
    MaxDistanceKm DECIMAL(6,2) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Category_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Category_Event FOREIGN KEY (EventId) REFERENCES Event(EventId) ON DELETE CASCADE,
    CONSTRAINT CK_Category_Type CHECK (CategoryType IN ('Age','Distance')),
    CONSTRAINT CK_Category_Age CHECK (
        CategoryType <> 'Age' OR
        (MinAge IS NOT NULL AND MaxAge IS NOT NULL AND MinAge >= 0 AND MaxAge >= MinAge)
    ),
    CONSTRAINT CK_Category_Distance CHECK (
        CategoryType <> 'Distance' OR
        (MinDistanceKm IS NOT NULL AND MaxDistanceKm IS NOT NULL AND MinDistanceKm >= 0 AND MaxDistanceKm >= MinDistanceKm)
    ),
    CONSTRAINT UQ_Category_Event_Name UNIQUE (EventId,Name)
);

CREATE TABLE Enrollment (
    EnrollmentId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Enrollment PRIMARY KEY,
    EventId INT NOT NULL,
    ParticipantId INT NOT NULL,
    CategoryId INT NOT NULL,
    EnrollmentDate DATETIME2(0) NOT NULL CONSTRAINT DF_Enrollment_Date DEFAULT SYSUTCDATETIME(),
    Status VARCHAR(20) NOT NULL CONSTRAINT DF_Enrollment_Status DEFAULT 'Confirmed',
    CONSTRAINT FK_Enrollment_Event FOREIGN KEY (EventId) REFERENCES Event(EventId),
    CONSTRAINT FK_Enrollment_Participant FOREIGN KEY (ParticipantId) REFERENCES Users(UserId),
    CONSTRAINT FK_Enrollment_Category FOREIGN KEY (CategoryId) REFERENCES Category(CategoryId),
    CONSTRAINT CK_Enrollment_Status CHECK (Status IN ('Pending','Confirmed','Cancelled')),
    CONSTRAINT UQ_Enrollment_Event_Participant UNIQUE (EventId,ParticipantId)
);

CREATE TABLE Result (
    ResultId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Result PRIMARY KEY,
    EnrollmentId INT NOT NULL,
    FinishTime TIME(0) NULL,
    FinishPosition INT NULL,
    IsPublished BIT NOT NULL CONSTRAINT DF_Result_IsPublished DEFAULT 0,
    PublishedAt DATETIME2(0) NULL,
    CONSTRAINT FK_Result_Enrollment FOREIGN KEY (EnrollmentId) REFERENCES Enrollment(EnrollmentId) ON DELETE CASCADE,
    CONSTRAINT UQ_Result_Enrollment UNIQUE (EnrollmentId),
    CONSTRAINT CK_Result_Position CHECK (FinishPosition IS NULL OR FinishPosition > 0),
    CONSTRAINT CK_Result_PublishedAt CHECK (IsPublished=0 OR PublishedAt IS NOT NULL)
);

CREATE TABLE Session (
    SessionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Session PRIMARY KEY,
    UserId INT NOT NULL,
    RoleSnapshot VARCHAR(20) NOT NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Session_CreatedAt DEFAULT SYSUTCDATETIME(),
    ExpiresAt DATETIME2(0) NOT NULL,
    RevokedAt DATETIME2(0) NULL,
    CONSTRAINT FK_Session_User FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    CONSTRAINT CK_Session_Role CHECK (RoleSnapshot IN ('Organizer','Participant')),
    CONSTRAINT CK_Session_Expiry CHECK (ExpiresAt > CreatedAt)
);

INSERT INTO Users (FirstName,LastName,Email,PasswordHash,Role,Phone)
VALUES
('Lerato','Mokoena','lerato.organizer@raceday.co.za','PBKDF2-SHA256$SAMPLE_HASH_001','Organizer','0825550101'),
('Jason','Naidoo','jason.organizer@raceday.co.za','PBKDF2-SHA256$SAMPLE_HASH_002','Organizer','0835550102'),
('Aisha','Jacobs','aisha.participant@raceday.co.za','PBKDF2-SHA256$SAMPLE_HASH_003','Participant','0845550103'),
('Musa','Khumalo','musa.participant@raceday.co.za','PBKDF2-SHA256$SAMPLE_HASH_004','Participant','0855550104');

INSERT INTO Event
(OrganizerId,Name,Description,EventDate,Location,DistanceKm,EventType,RouteUrl,RouteDescription)
VALUES
(1,'Cape Town Sunrise 10K','A fast coastal 10 km road race for runners of varied experience.',
 DATEADD(DAY,30,CAST(CAST(GETDATE() AS DATE) AS DATETIME2)),'Green Point, Cape Town',10.00,'Running',
 'https://example.org/routes/cape-town-sunrise-10k','Coastal route starting and finishing near Green Point.'),
(1,'Cape Winelands Family Walk','A community walking event through scenic Winelands surroundings.',
 DATEADD(DAY,45,CAST(CAST(GETDATE() AS DATE) AS DATETIME2)),'Stellenbosch, Western Cape',5.00,'Walking',
 'https://example.org/routes/winelands-family-walk','Accessible 5 km community route.'),
(2,'Cape Cycle Challenge','A recreational road cycling event around Paarl.',
 DATEADD(DAY,60,CAST(CAST(GETDATE() AS DATE) AS DATETIME2)),'Paarl, Western Cape',40.00,'Cycling',
 'https://example.org/routes/cape-cycle-challenge','40 km loop with rolling terrain.');

INSERT INTO Category
(EventId,Name,CategoryType,MinAge,MaxAge,MinDistanceKm,MaxDistanceKm)
VALUES
(1,'Junior','Age',13,17,NULL,NULL),
(1,'Open','Age',18,39,NULL,NULL),
(1,'Masters','Age',40,99,NULL,NULL),
(2,'Family','Age',10,99,NULL,NULL),
(2,'5 km Walk','Distance',NULL,NULL,5.00,5.00),
(3,'Open Cycling','Age',18,99,NULL,NULL),
(3,'40 km Challenge','Distance',NULL,NULL,40.00,40.00);

INSERT INTO Enrollment(EventId,ParticipantId,CategoryId,Status)
VALUES
(1,3,2,'Confirmed'),
(1,4,2,'Confirmed'),
(2,3,4,'Confirmed'),
(3,4,6,'Confirmed');

INSERT INTO Result(EnrollmentId,FinishTime,FinishPosition,IsPublished,PublishedAt)
VALUES
(1,'00:48:32',12,1,SYSUTCDATETIME()),
(2,'00:52:10',19,1,SYSUTCDATETIME());

SELECT COUNT(*) AS UserCount FROM Users;
SELECT COUNT(*) AS EventCount FROM Event;
SELECT COUNT(*) AS CategoryCount FROM Category;
SELECT COUNT(*) AS EnrollmentCount FROM Enrollment;
SELECT COUNT(*) AS ResultCount FROM Result;
SELECT COUNT(*) AS SessionCount FROM Session;
