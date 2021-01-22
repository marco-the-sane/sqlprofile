# sqlprofile
Profile one or more Vertica tables for optimal data types, using SQL generating SQL.

Contact: marco.gessner@vertica.com

The package consists of three scripts: 
* profile.sql: a script of SQL generating profiling SQL, and 
* tabsel.sql:  a script that defines the tables to be profiled
  by profile.sql
* profile_scenario.sql: a script generating the tables and data that match
  the table selection as it is initially in "tabsel.sql", and can be used to
  familiarise oneself with the working principle.

For each table, first, each string is profiled for being a timestamp, a
number or a UUID rather than a string, and, based on those findings, a view
named `<schema>.<tbname>_pv` is created.

Then, each column in `<schema>.<tbname>_pv` is profiled for the most
restrictive length/precision/scale or sub data type possible for the data
found in it.

`tabsel.sql` selects the tables to profile from the system catalog like this:
```SQL
    CREATE TABLE tbid(table_schema,table_name,reduction_filter) AS 
    SELECT 
      table_schema
    , table_name
    , NULL AS reduction_filter 
    FROM tables 
    -- select the tables you want to profile here ...
    WHERE table_schema='public' 
      AND table_name IN('foo','foo_str');
```
Note the value "NULL" for the "reduction_filter" column above.  If you want
to scan a subset of the rows, change the reduction_filter column
accordingly ( `WHERE RANDOM() <= 1/100` to only profile every 100-th row,
for example).

The final outcome will be a CREATE TABLE with schema renamed to
`<schema>_new` and same table name that can then be used, and a matching
INSERT ... SELECT statement.

It's good practice to modify `tabsel.sql` and run it alone with:
```bash
  vsql -f tabsel.sql
```
to verify if the right tables will be profiled, and, if applicable, with
the right row restrictions, before running the whole profiling script.

All can be called in one shell line:
* generate the script that profiles the strings, 
* pipe the generated script through vsql, getting the CREATE VIEW statement
* pipe that CREATE VIEW statement through vsql again, and have the view ready
* generate the script that profiles the freshly created view
* pipe the generated detail profile script through vsql, getting finally
  the create table you expect, followed by an INSERT ... SELECT command
to copy the profiled table's data into the table with the new data types.

The call would simply be:
```bash
$ vsql -f profile.sql | tee out.sql
```
Happy playing!
