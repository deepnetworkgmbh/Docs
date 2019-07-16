# SPROC Logging Best Practices

Here are some best practices around SQL Logging

## 1. Truncate the Logging tables periodically 

Logging tables grow indefinitely and should be periodically truncated. Best Place to achieve is this during pre-deployment scripts, Or some periodic `HouseKeeping` operations.

```
IF (	EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'logging' AND TABLE_NAME = 'LogTable'))
)
	TRUNCATE TABLE [logging].[LogTable]
GO
```

## 2. Keep Logging related Tables, SPROCs in their own SQL `Schema`

It's always a good practice to create a logging schema:

```
CREATE SCHEMA [logging]
    AUTHORIZATION [dbo];
GO
```
On this note, Please be aware of the concept called `DB Ownership chaining` 

## 3. Trace also `ExecutedBy`

Even if the User is the `SYSTEM_USER` ensure its properly logged. Under cases where the SPROC is executed by a service, there is always the `SYSTEM_USER` and also if you use Row-Level Security and use the `SESSION_CONTEXT` bridge mark the appropriate context

```
 SET @SystemUser = 'Identifier: ' + ISNULL(CAST(SESSION_CONTEXT(N'UserId') AS NVARCHAR(255)), SYSTEM_USER) + ' IdentifierType: ' + ISNULL(CAST(SESSION_CONTEXT(N'IdType') AS NVARCHAR(255)), 'not set');  
 ```
