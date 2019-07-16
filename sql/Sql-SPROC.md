# Writing SQL Stored Procedures (SPROCs)

## 1. SET XACT_ABORT ON

You can read more about this feature here:
```
https://stackoverflow.com/questions/1150032/what-is-the-benefit-of-using-set-xact-abort-on-in-a-stored-procedure
```
The gist is the default for this is `OFF` and the main protection against is client side timeouts -- it will prevent the transaction from dangling.

The MSDN documentation is a bit misleading in terms of what it means to have a XACT_STATE = 1 in a CATCH block, so please read this for further information:
```
https://dba.stackexchange.com/questions/128535/in-what-cases-a-transaction-can-be-committed-from-inside-the-catch-block-when-xa
```
The main point is: **With TRY-CATCH and with XACT_ABORT ON the transaction is doomed in all possible cases.**

## 2. SET NOCOUNT ON

This is an historical artifact from an era where the count returning result was also effecting the performance, the modern thinking is its no longer required, but doesn't harm either.

More details here:
http://daleburnett.com/2014/01/everything-ever-wanted-know-set-nocount/

## 3. Put every SPROC into a particular SCHEMA

The SPROC should be in the same set as the tables it modifies.

```
CREATE PROCEDURE [myschema].[pMySproc]    
(    
 @Param1 BIT = 0
) 
```

## 4. Always return a SPROC Return Code:

Its critical to return at least some SUCCESS/FAIL error code, such as 0 for success and -1 for failure.
Or another alternative is to set the @@ROWCOUNT as the return code on success paths, since this is always a positive number, and set to -1 on failures.

```
CREATE PROCEDURE [myschema].[pMySproc]    
(    
 @Param1 BIT = 0,    
 ...
)    
AS    
BEGIN   
    DECLARE @StoredProcReturnCode  INT    = 0;
    RETURN @StoredProcReturnCode    
END  
```

## 5. RAISEERROR vs. THROW
Prefer Throw'ing in T-SQL, `but` unfortunately you also need to occasionally RAISEERROR

Here is a thorough description of differences:
```
https://sqltutorialtips.blogspot.com/2017/06/raiserror-vs-throw.html
```



## 6. Use TRY-CATCH error handling
This is part of a bigger discussion of how to handle errors, and its a pretty involved one, please check the following blog about a more comprehensive discourse on this topic:

```
http://www.sommarskog.se/error-handling-I.html
```
For many application developers in Java, C#, etc. the semantisc of a TRY-CATCH / THROW logic is pretty intuitive; but there are quite a few gotchas.

So if we put everything we said until now together, the ideal boilerplate SPROC looks as following:

```
CREATE PROCEDURE [myschema].[pMySproc]    
(    
 @Param1 BIT = 0,    
 ...
)    
AS    
BEGIN    
SET NOCOUNT ON;    
SET XACT_ABORT ON;    
  
BEGIN TRY
   -- vv------------
   -- MAIN CODE BLOCK
   -- ^^------------ 
END TRY
BEGIN CATCH
   -- vv------------
    SET @StoredProcReturnCode = -1;    
    
    IF ( XACT_STATE() = -1 OR ( XACT_STATE() = 1 AND @@TRANCOUNT > 0) )    
    BEGIN    
        ROLLBACK TRANSACTION;    
    END   
    
    SET @MessageNumber = ERROR_NUMBER();    
    SET @MessageText = LEFT(ERROR_MESSAGE(), 4000);    
    SET @ErrorSeverity = ERROR_SEVERITY();    
    SET @ErrorState = ERROR_STATE();    
    
    SET @StopTime = SYSUTCDATETIME();    
    
    IF @MessageNumber < 50000    
        RAISERROR (@MessageText, @ErrorSeverity, @ErrorState);    
    ELSE    
        THROW @MessageNumber, @MessageText, @ErrorState   
   -- ^^------------ 
END CATCH

RETURN @StoredProcReturnCode    
END  
```




