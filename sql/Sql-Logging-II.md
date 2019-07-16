# SPROC Logging Best Practices

Here are some best practices around SQL Logging

## 1. Truncate the Logging tables periodically 

Logging tables grow indefinitely and should be periodically truncated. Best Place to achieve is this during pre-deployment scripts, Or some periodic `HouseKeeping` operations.

## 2. b
