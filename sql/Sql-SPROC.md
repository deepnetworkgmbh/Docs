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

