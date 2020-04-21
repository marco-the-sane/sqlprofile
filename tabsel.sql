-- selection of tables to be profiled
DROP TABLE IF EXISTS tbid;
CREATE TABLE tbid(table_schema,table_name,reduction_filter) AS 
SELECT 
  table_schema
, table_name
, NULL AS reduction_filter 
FROM tables 
-- select the tables you want to profile here ...
WHERE table_schema='public' 
  AND table_name IN('foo','foo_str');
-- end of table selection ...
-- control query
\pset footer
\qecho '----------------------------------------------'
\qecho ' --  | these tables will be profiled:'
\qecho '----------------------------------------------'
SELECT
  '-- ' AS "-- "
, table_schema
, table_name
, NULL AS reduction_filter 
FROM tbid
;
