# ssms-query-shortcuts
Queries for SQL Server Management Studio Keyboard Query Shortcuts to make finding your way around a database a little easier.



#### Usage Notes

Copy and paste the text from each of the files in the queries_collapsed folder into an available *Stored Procedure* text box in *SSMS / Options / Environment / Keyboard / Query Shortcuts*. 

![options](images/options.png)

When you open a new query window, you'll be able to use the specified keyboard shortcut combination to run the associated query. All queries except *table size name* and *table size space* require text to be selected with the cursor before hitting the shortcut keys.

If you want to customize one of the queries, it's easier to work with the duplicated ones provided in the *queries_expanded* folder and then collapse them again. To collapse the query into a single line, specify this in the *search* dialog:

![search](images/search.png)



#### Known Issues

Since the queries use an input parameter to sp_executesql to capture the highlighted text sent to the query, you are unable to select both schema and table name. No special characters such as periods can be used. Therefore, the table/procedure/module/etc shown in the output will be the one with the first alphabetically occurring schema name. If you can find a workaround to this, please let me know.



![output](images/output.png)
