1. What is the difference between a function and a procedure in PostgreSQL?
Function needs to return something and can used directly through select, however procedure can return something or not and used through call - it is designed to perform actions like inserting or updating data
2. Can a trigger be executed manually? Why or why not?
No, trigger cannot executed manually. Trigger is automatically triggered by PostgreSQL in response to specific event like: insert, update or delete. It is not callable object, it runs only when certain event occurs. To test trigger manually we might do triggering operation (like insert or delete or update)
3. What are the advantages and disadvantages of storing business logic inside the database?
Advantages:
Disadvantages:
