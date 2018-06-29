# How to do SQL Logging right

This will be an introductory text for logging in a sequence of articles.
 
Stored Procedure Logging (or tracing?) is an extremely important topic in SQL world. 

Since most of the time we don't debug SPROCs line by line, and they pretty much execute behind the scenes, we need to able to trace if anything goes wrong for debugging or diagnostic purposes. 

Even if we return errors/warnings in the result sets; still as SQL developer, we would like to see what went wrong and how the problem occurred.

Here we will take a sample SPROC that modifies a Users table, and add logging to it.

First we need to initialize common objects to use throughout this tutorial:
```
CREATE TABLE [dbo].[Users] (
    [Id]         BIGINT        IDENTITY(1,1),
    [Firstname]  NVARCHAR(128) NOT NULL,
    [Lastname]   NVARCHAR(128) NOT NULL,

    PRIMARY KEY (Id)
)
```

```
CREATE OR ALTER PROCEDURE [dbo].[pDeleteUser] (
    @UserId BIGINT = NULL
)
AS
BEGIN
    DECLARE @ReturnCode INT          = -1;
    
    DELETE U
    FROM [dbo].[Users] AS U
    WHERE U.[Id] = @UserId;
    
    SET @ReturnCode = 0;
    
    RETURN @ReturnCode;
END
```

## Basic logging
Let's try to introduce a very basic logging tool that will help us to keep history of our executions. To do that, we are just going to add every one of our SQL statements into our logging table. However, we don't have any SQL statement as `varchar` in our hands. So we need to change our function a bit. Also we need the `Logs` table to keep logging records.

```
CREATE TABLE [dbo].[Logs] (
    [Id]                 BIGINT        IDENTITY(1,1),
    [SqlText]            NVARCHAR(MAX) NOT NULL,
    [ExecutionDateTime]  DATETIME2(7)  NOT NULL,

    PRIMARY KEY (Id)
)
```

```
CREATE OR ALTER PROCEDURE [dbo].[pDeleteUser] (
    @UserId BIGINT = NULL
)
AS
BEGIN
    DECLARE @ReturnCode INT = -1;
    
    DECLARE @SqlText NVARCHAR(MAX) = N'';
    SET @SqlText = N'DELETE U FROM [dbo].[Users] AS U';
    SET @SqlText = @SqlText + N' WHERE U.[Id] = ' + CAST(@UserId AS NVARCHAR(24));

    EXEC sp_executesql @SqlText;
    SET @ReturnCode = 0;

    INSERT INTO [dbo].[Logs] (
        SqlText, ExecutionDateTime)
    VALUES (@SqlText, SYSUTCDATETIME());
    
    RETURN @ReturnCode;
END
```

Great! Every execution will now be inserted as rows into the `Logs` table. However, with this kind of logging, **ugly** `@SqlText` will be introduced in every function, procedure in our project; moreover, this will populate lots of lengthy records in the Logs table.

## Redundant data in Logs

First we're going to solve the first problem. In the previous example, we know that the procedure will execute same SQL statement with just a little difference: parameter `@UserId` will be used in the WHERE clause. It means, instead of writing down the whole SQL statement as text, we can just log function call within the function. Like:

```
CREATE OR ALTER PROCEDURE [dbo].[pDeleteUser] (
    @UserId BIGINT = NULL
)
AS
BEGIN
    DECLARE @ReturnCode INT = -1;

    DELETE U
    FROM [dbo].[Users] AS U
    WHERE U.[Id] = @UserId;
    
    SET @ReturnCode = 0; 

    INSERT INTO [dbo].[Logs] (
        SqlText,
        ExecutionDateTime
    ) VALUES (
        'EXEC [dbo].[pDeleteUser] @UserId=' + CAST(@UserId AS NVARCHAR(24)),
        SYSUTCDATETIME()
    );
    
    RETURN @ReturnCode;
END
```
By doing this, we just got rid of all the redundant `DELETE (...) FROM (...) WHERE (...)` statements in our logs. Also we didn't lose any information as we already know what was the actual SQL statement executing just by looking inside the procedure.

## More details needed
As a maintainer we would like to know more about the execution. Only `SqlText` and `ExecutionDateTime` doesn't provide enough information about what's wrong with the execution. Let's add couple of more information to our logs:

```
CREATE TABLE [dbo].[Logs] (
    [Id]                 BIGINT         IDENTITY(1,1),
    [SqlText]            NVARCHAR(MAX)  NOT NULL, -- Executed SQL statement
    [ObjectId]           BIGINT         NOT NULL, -- Executed SProc/Func Id, see note[1]
    [StartDateTime]      DATETIME2(7)   NOT NULL, -- Execution started at
    [EndDateTime]        DATETIME2(7)   NOT NULL, -- Execution finished at
    [ReturnCode]         NVARCHAR(MAX)  NOT NULL, -- Scalar value returned as a result
    [Details]            NVARCHAR(MAX)  NOT NULL, -- Detailed text from the developer  
    [ErrorCode]          BIGINT         NOT NULL, -- If there is an error, we store code here.
    PRIMARY KEY (Id)
)
```
*[1]: we're using only objectId here instead of object name which could be derived by `OBJECT_NAME(objectId)`; because we may not have enough permission to use `sys` tables for every time we execute this proc due to lack of permissions* 

Now, we have following usage from now on:

```
CREATE OR ALTER PROCEDURE [dbo].[pDeleteUser] (
    @UserId       BIGINT      = NULL
)
AS
BEGIN
    DECLARE @ReturnCode INT = -1;
    DECLARE @StartTime  DATETIME2(7) = SYSUTCDATETIME();
    
    DELETE U
    FROM [dbo].[Users] AS U
    WHERE U.[Id] = @UserId;
    
    SET @ReturnCode = 0;

    INSERT INTO [dbo].[Logs] (
        SqlText,
        ObjectId,
        StartDateTime,
        EndDateTime,
        ReturnCode,
        Details,
        ErrorCode
    ) VALUES (
        'EXEC [dbo].[pDeleteUser] @UserId=' + CAST(@UserId AS NVARCHAR(24)),
        @@PROCID,
        @StartTime,
        SYSUTCDATETIME(),
        @ReturnCode,
        '... more explanation about what has been done',
        0,
    );
    
    RETURN @ReturnCode;
END
```

## DRY (Don't Repeat Yourself!)

What's wrong with this style is that we have lot's of lines all repeated in our codebase. To overcome this issue, we can take `INSERT` statement out as a new procedure which do the logging for us. To do this, we will refactor last usage a bit and create a procedure out of the `INSERT` statement.

```
CREATE OR ALTER PROCEDURE [dbo].[pLog] (
    @SqlText            NVARCHAR(MAX)  , -- Executed SQL statement
    @ObjectId           BIGINT         , -- Executed SProc/Func Id
    @StartDateTime      DATETIME2(7)   , -- Execution started at
    @EndDateTime        DATETIME2(7)   , -- Execution finished at
    @ReturnCode         NVARCHAR(MAX)  , -- Scalar value returned as a result
    @Details            NVARCHAR(MAX)  , -- Detailed text from the developer  
    @ErrorCode          BIGINT           -- If there is an error, we store code here.
)
AS 
BEGIN TRY
    INSERT INTO [dbo].[Logs] (
        SqlText,
        ObjectId,
        StartDateTime,
        EndDateTime,
        ReturnCode,
        Details,
        ErrorCode
    ) VALUES (
        @SqlText,
        @ObjectId,
        @StartDateTime,
        @EndDateTime,
        @ReturnCode,
        @Details,
        @ErrorCode
    );
END TRY
BEGIN CATCH 
    -- Just to catch exception safely if there is an error. 
    -- We never want to fail from a proc just because logging failed. 
    -- Silently ignoring, if it fits with your requirements, 
    --                    otherwise, you can always free to fail or RAISERROR.
    PRINT 'Logging error, It''s CRITICAL but we must ignore!'
END CATCH
```
```
CREATE OR ALTER PROCEDURE [dbo].[pDeleteUser] (
    @UserId BIGINT = NULL
)
AS
BEGIN
    DECLARE @ReturnCode INT = -1;
    
    -- vv Logging variables. ---------------------------------------------------------------------------------------
    DECLARE @LogStartTime      DATETIME2(7)  = SYSUTCDATETIME();
    DECLARE @LogEndTime        DATETIME2(7)  = SYSUTCDATETIME();
    DECLARE @LogSqlStatement   NVARCHAR(MAX) = 'EXEC [dbo].[pDeleteUser] @UserId=' + CAST(@UserId AS NVARCHAR(24));
    DECLARE @LogDetails        NVARCHAR(MAX) = '... more explanation about what has been done';
    -- ^^ Logging variables. ---------------------------------------------------------------------------------------
    
    DELETE U
    FROM [dbo].[Users] AS U
    WHERE U.[Id] = @UserId;
    
    SET @ReturnCode = 0;

    -- Logging
	SELECT @LogEndTime = SYSUTCDATETIME();
    EXEC [dbo].[pLog] @LogSqlStatement, @@PROCID, @LogStartTime, @LogEndTime, @ReturnCode, @LogDetails, 0
    
    RETURN @ReturnCode;
END
```

Happy SQLogging,

Enes Unal - DeepNetwork GmbH
