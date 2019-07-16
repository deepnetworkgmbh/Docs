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

## 4. 
