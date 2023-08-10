-- in 9.2, with too many columns to profile, you might run into:
-- ERROR 8617:  Request size too big
-- You can disable this check by setting MaxParsedQuerySizeMB to 0.

-- create the table selection auxiliary table
-- edit tabsel.sql to define the tables you want to profile
\i tabsel.sql


\pset tuples_only
\o | vsql -AtqX
WITH 
-- suffix for re-casting view ...
suff(vwsuff,tbsuff) AS (SELECT '_pv','_new')
,
-- determine all needed formatting aids and other details
collist AS (
  SELECT
    tbid.table_schema||'.'||tbid.table_name AS schema_dot_table
  , tbid.table_name
  , column_name
  , UPPER(data_type) AS data_type
  , ordinal_position
  , ROW_NUMBER() OVER(i) = 1 AS isfirst
  , ROW_NUMBER() OVER(i) = COUNT(*) OVER(a) AS islast
  , MAX(CHAR_LENGTH(column_name)) OVER(a) AS max_nm_len
  , MAX(CHAR_LENGTH(data_type    )) OVER(a) AS max_tp_len
  , reduction_filter
  , (   split_part(data_type,'(',1) = 'char'
     OR split_part(data_type,'(',1) = 'varchar' ) AS isstring
  FROM tbid 
  JOIN (
    SELECT table_schema,table_name,column_name,data_type,ordinal_position FROM columns 
    UNION ALL
    SELECT table_schema,table_name,column_name,data_type,ordinal_position FROM view_columns 
  ) c USING(table_schema,table_name) 
  WINDOW a AS (PARTITION BY tbid.table_schema,tbid.table_name) 
       , i AS (PARTITION BY tbid.table_schema,tbid.table_name ORDER BY ordinal_position)
)
SELECT
   CASE
   WHEN isfirst
     THEN '\o | vsql -AtqX'||CHR(10)||'SELECT'||CHR(10)||'  MAX(''DROP VIEW IF EXISTS '')||'''||schema_dot_table||vwsuff||';''||CHR(10)'
     ||'||''CREATE VIEW '||schema_dot_table||'_pv AS SELECT''||CHR(10)||''  '
   ELSE   '||CHR(10)||'', '
   END
 ||column_name||''''
 ||CASE 
   WHEN isstring THEN 
   CHR(10)||'||'
 ||'RPAD(SPLIT_PART(NVL('||CHR(10)
 ||'    MAX('||CHR(10)
 ||'      CASE'||CHR(10)
 ||'      WHEN'||CHR(10)
 ||'        REGEXP_LIKE('||CHR(10)
 ||'          TRIM('||column_name||')'||CHR(10)
 ||'        , ''^\d\d:\d\d(:\d\d)?(\.\d+)?'''||CHR(10)
 ||'        , ''ib'''||CHR(10)
 ||'        )'||CHR(10)
 ||'      THEN ''3-::TIME'''||CHR(10)
 ||'      WHEN'||CHR(10)
 ||'        REGEXP_LIKE('||CHR(10)
 ||'          TRIM('||column_name||')'||CHR(10)
 ||'        , ''^\d\d(\d\d)?[-./]\d\d[-./]\d\d(\d\d)?([ T]\d\d:\d\d:\d\d(\.\d+)?)?'''||CHR(10)
 ||'        , ''ib'''||CHR(10)
 ||'        )'||CHR(10)
 ||'      THEN ''2-::TIMESTAMP'''||CHR(10)
 ||'      WHEN REGEXP_LIKE(TRIM('||column_name||'),''^[-+]?(\d+(\.\d*)?|\.\d+)$'',''ib'')'||CHR(10)
 ||'      THEN ''1-::NUMERIC'''||CHR(10)
 ||'      WHEN REGEXP_LIKE(TRIM('||column_name||'),''^[a-f0-9]{8}-?[a-f0-9]{4}-?[a-f0-9]{4}-?[a-f0-9]{4}-?[a-f0-9]{12}$'',''ib'')'||CHR(10)
 ||'      THEN ''4-::UUID'''||CHR(10)
 ||'      WHEN OCTET_LENGTH(TRIM('||column_name||')) <> CHAR_LENGTH(TRIM('||column_name||'))'||CHR(10)
 ||'      THEN ''7-::NCHAR VARYING'''
 ||'      WHEN OCTET_LENGTH(TRIM('||column_name||')) = CHAR_LENGTH(TRIM('||column_name||'))'||CHR(10)
 ||'      THEN ''6-::VARCHAR'''||CHR(10)
 ||'      ELSE ''0-::CHAR'''||CHR(10)
 ||'      END'||CHR(10)
 ||'    )'||CHR(10)
 ||'  , ''0-::CHAR'''||CHR(10)
 ||'  ),''-'',2),16,'' '')||'''
 ||REPEAT(' ',max_nm_len-OCTET_LENGTH(column_name) )
 ||'-- CURRENTLY  '||data_type||''''
   ELSE ''
   END
 ||CASE
   WHEN islast
     THEN '||CHR(10)||''FROM '||schema_dot_table||';'''
     ||CHR(10)||'FROM '||schema_dot_table
     ||CHR(10)||NVL(reduction_filter,'')
     ||CHR(10)||CHR(59)||CHR(10)
   ELSE ''
   END
FROM collist CROSS JOIN suff
ORDER BY schema_dot_table,ordinal_position
;


\o | vsql -AtqX

WITH
-- suffix for re-casting view, which is actually profiled here ...
suff(vwsuff,tbsuff) AS (SELECT '_pv','_new')
,
vwid(table_schema,table_name,view_name,reduction_filter,vwsuff,tbsuff) AS (
  SELECT table_schema,table_name,table_name||vwsuff,reduction_filter,vwsuff,tbsuff
  FROM tbid CROSS JOIN suff
)
,
-- determine all needed formatting aids and other details
-- including isstring, isnumeric, istimestamp, istime Booleans
-- including membership of a column in a key constraint ('u' or 'p')
-- but only one key constraint - hence analytic limit clause
collist0 AS (
  SELECT
    tbid.table_schema||'.'||tbid.table_name AS schema_dot_table
  , tbid.table_schema
  , tbid.table_name
  , vwsuff
  , tbsuff
  , c.column_name
  , UPPER(data_type) AS data_type
  , ordinal_position
  , ordinal_position = 1 AS isfirst
  ,    SPLIT_PART(data_type,'(',1) = 'char'
    OR SPLIT_PART(data_type,'(',1) = 'varchar'
    AS isstring
  ,    SPLIT_PART(data_type,'(',1) = 'binary'
    OR SPLIT_PART(data_type,'(',1) = 'varbinary'
    AS isbinary
  ,
       SPLIT_PART(data_type,'(',1) = 'long varchar'
    OR SPLIT_PART(data_type,'(',1) = 'long varbinary'
    AS islong
  ,               data_type        = 'float'
    OR            data_type        = 'int'
    OR SPLIT_PART(data_type,'(',1) = 'numeric'
    AS isnumeric
  ,    SPLIT_PART(data_type,'(',1) = 'time'
    AS istime
  ,    SPLIT_PART(data_type,'(',1) = 'timestamp'
    AS istimestamp
  , MAX(CHAR_LENGTH(c.column_name)) OVER (w) AS max_nm_len
  , MAX(CHAR_LENGTH(data_type)) OVER (w) + 4 AS max_tp_len
  , reduction_filter
  FROM vwid AS tbid 
  JOIN (
    SELECT table_schema,table_name,column_name,data_type,ordinal_position FROM columns 
    UNION ALL
    SELECT table_schema,table_name,column_name,data_type,ordinal_position FROM view_columns 
  ) c USING(table_schema) 
  WHERE c.table_name = view_name
  WINDOW w AS (PARTITION BY tbid.table_schema,tbid.table_name) 
)
,
-- can only count columns once applied analytic limit clause
collist AS (
  SELECT
    c.*
  , c.ordinal_position = (
      COUNT(*) OVER(PARTITION BY schema_dot_table) 
    ) AS islast
  , UPPER(oc.data_type) AS orig_data_type
  FROM collist0 c
  JOIN (
    SELECT table_schema,table_name,column_name,data_type,ordinal_position FROM columns 
    UNION ALL
    SELECT table_schema,table_name,column_name,data_type,ordinal_position FROM view_columns 
  ) oc USING(table_schema,column_name)
  WHERE REPLACE(c.table_name,vwsuff,'')=oc.table_name
)
-- need to buffer code in a common table expression to add sorting 
-- column which won't be printed at the end.
,
code(schema_dot_table,phase,ordinal_position,code) AS (
  SELECT
    schema_dot_table
  , 10 as phase
  , ordinal_position
  , CASE
    WHEN isfirst
      THEN 'WITH'||CHR(10)||'lengths AS ('||CHR(10)||'SELECT'||CHR(10)||'  '
    ELSE ', '
    END
     ||
     CASE
     WHEN isnumeric
       THEN 
         'CASE '||CHR(10)
       ||'   WHEN INSTR('||column_name||'::VARCHAR(32), ''.'') = 0'||CHR(10)
       ||'     THEN OCTET_LENGTH('||column_name||'::VARCHAR(32))'||CHR(10)
       ||'   ELSE OCTET_LENGTH(SPLIT_PART('||column_name||'::VARCHAR(32), ''.'', 1))'||CHR(10)
       ||'  END AS '||column_name||'_prec'||CHR(10)
       ||', CASE '||CHR(10)
       ||'   WHEN INSTR('||column_name||'::VARCHAR(32), ''.'') = 0'||CHR(10)
       ||'     THEN 0'||CHR(10)
       ||'   ELSE OCTET_LENGTH(RTRIM(SPLIT_PART('||column_name||'::VARCHAR(32), ''.'',2), ''0''))'||CHR(10)
       ||'  END AS '||column_name||'_scale'
     WHEN istime
       THEN
         'OCTET_LENGTH(RTRIM('||column_name||'::VARCHAR(32))) AS '||column_name||'_prec'||CHR(10)
       ||', CASE '||CHR(10)
       ||'   WHEN INSTR('||column_name||'::VARCHAR(32), ''.'') = 0'||CHR(10)
       ||'     THEN 0'||CHR(10)
       ||'   ELSE OCTET_LENGTH(RTRIM(SPLIT_PART('||column_name||'::VARCHAR(32),''.'',2)))'||CHR(10)
       ||'  END AS '||column_name||'_scale'
     WHEN istimestamp
       THEN
         'CASE '||CHR(10)
       ||'   WHEN OCTET_LENGTH(RTRIM('||column_name||'::VARCHAR(32))) > 10'||CHR(10)
       ||'    AND INSTR('||column_name||'::VARCHAR(32), ''00:00:00'') = 0'||CHR(10)
       ||'     THEN 19'||CHR(10)
       ||'   ELSE 10'||CHR(10)
       ||'  END AS '||column_name||'_prec'||CHR(10)
       ||', CASE '||CHR(10)
       ||'   WHEN INSTR('||column_name||'::VARCHAR(32), ''.'') = 0'||CHR(10)
       ||'     THEN 0'||CHR(10)
       ||'   ELSE OCTET_LENGTH(RTRIM(SPLIT_PART('||column_name||'::VARCHAR(32),''.'',2)))'||CHR(10)
       ||'  END AS '||column_name||'_scale'
     WHEN isstring
       THEN
         'OCTET_LENGTH(RTRIM('||column_name||')) AS '||column_name||'_prec'
     WHEN isbinary
       THEN
         'OCTET_LENGTH('||column_name||') AS '||column_name||'_prec'
     WHEN islong
       THEN
         'OCTET_LENGTH('||column_name||') AS '||column_name||'_prec'
     ELSE 
         '8 AS '||column_name||'_prec'
     END
     ||
     CASE
     WHEN islast
       THEN CHR(10)||'FROM '||schema_dot_table||' -- tbname'
          ||CHR(10)||NVL(reduction_filter,'')
          ||CHR(10)||') -- lengths GTE'||CHR(10)
     ELSE ''
     END
  FROM collist
  UNION ALL
  SELECT
    schema_dot_table
  , 20 as phase
  , ordinal_position
  , CASE WHEN isfirst
      THEN
        ','||CHR(10)
      ||'maxlengths AS ('||CHR(10)
      ||'SELECT'||CHR(10)
      ||'  '
      ELSE
        ', '
    END
    ||
    'MAX('||column_name||'_prec) AS '||column_name||'_prec'||CHR(10)
       ||
       CASE 
       WHEN isnumeric OR istime OR istimestamp
         THEN    ', MAX('||column_name||'_scale) AS '||column_name||'_scale'
       ELSE ''
       END
       ||
       CASE WHEN islast
         THEN CHR(10)||'FROM lengths'||CHR(10)||') -- maxlengths GTE'
       ELSE ''
       END
  FROM collist
  UNION ALL
  SELECT
    schema_dot_table
  , 30 AS phase
  , ordinal_position
  ,  CASE WHEN isfirst
     THEN 'SELECT'
     ||CHR(10)||'  CHR(10)||''CREATE SCHEMA IF NOT EXISTS '||table_schema||tbsuff||';'''
     ||CHR(10)||'||CHR(10)||''DROP TABLE IF EXISTS '||table_schema||tbsuff||'.'||table_name||';'''
     ||CHR(10)||'||CHR(10)||''CREATE TABLE '||table_schema||tbsuff||'.'||table_name||'('''
     ||CHR(10)||'||CHR(10)||''  '
   ELSE   
     '||CHR(10)||'', '
   END
     ||RPAD(column_name,max_nm_len+1,' ')||''''||CHR(10)||'||'
     ||CASE 
       WHEN isnumeric
        THEN
           'RPAD(CASE '||CHR(10)
         ||'   WHEN '||column_name||'_scale IS NULL'||CHR(10)
         ||'     THEN ''CHAR(1) -- always NULL'''||CHR(10)
         ||'   WHEN '||column_name||'_scale = 0 AND '||column_name||'_prec <= 18'||CHR(10)
         ||'     THEN ''INTEGER'''||CHR(10)
         ||'   ELSE ''NUMERIC(''||('||column_name||'_prec+'||column_name||'_scale)::VARCHAR(4)||'',''||'
            ||column_name||'_scale::VARCHAR(4)||'')'''||CHR(10)
         ||'  END,'||max_tp_len||','' '')|| ''-- currently '||orig_data_type||''''
        WHEN istime
         THEN
            'RPAD(CASE '||CHR(10)
          ||'   WHEN '||column_name||'_prec IS NULL'||CHR(10)
          ||'     THEN ''CHAR(1) -- always NULL'''||CHR(10)
          ||'   WHEN '||column_name||'_prec = 8 AND '||column_name||'_prec = 0'||CHR(10)
          ||'     THEN ''TIME(0)'''||CHR(10)
          ||'   ELSE ''TIME(''||'||column_name||'_scale::VARCHAR(4)||'')'''||CHR(10)
          ||'  END,'||max_tp_len||')'||CHR(10)
          ||'|| ''-- currently '||orig_data_type||''''||CHR(10)
        WHEN istimestamp
         THEN
            'RPAD(CASE '||CHR(10)
          ||'   WHEN '||column_name||'_prec IS NULL'||CHR(10)
          ||'     THEN ''CHAR(1) -- always NULL'''||CHR(10)
          ||'   WHEN '||column_name||'_prec = 10'||CHR(10)
          ||'     THEN ''DATE'''||CHR(10)
          ||'   WHEN '||column_name||'_prec = 19 AND '||column_name||'_prec = 0'||CHR(10)
          ||'     THEN ''TIMESTAMP(0)'''||CHR(10)
          ||'   ELSE ''TIMESTAMP(''||'||column_name||'_scale::VARCHAR(4)||'')'''||CHR(10)
          ||'  END,'||max_tp_len||')'||CHR(10)
          ||'|| ''-- currently '||orig_data_type||''''||CHR(10)
       WHEN isstring
         THEN
            'RPAD(CASE '||CHR(10)
          ||'   WHEN '||column_name||'_prec IS NULL'||CHR(10)
          ||'     THEN ''CHAR(1) -- always NULL'''||CHR(10)
          ||'   ELSE'||CHR(10)
          ||'     CASE'||CHR(10)
          ||'       WHEN '||column_name||'_prec <= 16'||CHR(10)
          ||'        THEN  ''CHAR(''||'||column_name||'_prec::VARCHAR(4)||'')'''||CHR(10)
          ||'       ELSE ''VARCHAR(''||'||column_name||'_prec::VARCHAR(4)||'')'''||CHR(10)
          ||'     END'||CHR(10)
          ||'  END'||CHR(10)
          ||' ,'||max_tp_len||')'||CHR(10)
          ||'|| ''-- currently '||orig_data_type||''''||CHR(10)
       WHEN isbinary
         THEN
            'RPAD(CASE '||CHR(10)
          ||'   WHEN '||column_name||'_prec IS NULL'||CHR(10)
          ||'     THEN ''CHAR(1) -- always NULL'''||CHR(10)
          ||'   ELSE'||CHR(10)
          ||'    ''VARBINARY(''||'||column_name||'_prec::VARCHAR(4)||'')'''||CHR(10)
          ||'  END'||CHR(10)
          ||','||max_tp_len||')'||CHR(10)
          ||'|| ''-- currently '||orig_data_type||''''||CHR(10)
       WHEN islong
         THEN
            'RPAD(CASE '||CHR(10)
          ||'   WHEN '||column_name||'_prec IS NULL'||CHR(10)
          ||'     THEN ''CHAR(1) -- always NULL'''||CHR(10)
          ||'   ELSE'||CHR(10)
          ||'    '''||SPLIT_PART(data_type,'(',1)||'(''||'||column_name||'_prec::VARCHAR(4)||'')'''||CHR(10)
          ||'  END'||CHR(10)
          ||','||max_tp_len||')'||CHR(10)
          ||'|| ''-- currently '||orig_data_type||''''||CHR(10)
       ELSE 'RPAD('''||data_type||''','||max_tp_len||','' '')|| ''-- currently '||orig_data_type||''''
     END
     || CASE WHEN islast THEN CHR(10)||'||CHR(10)||'')''||CHR(59) FROM maxlengths'||CHR(59) ELSE '' END
FROM collist
UNION ALL
  SELECT DISTINCT
    schema_dot_table
  , 50 AS phase
  , 1
  , 'SELECT'
   ||CHR(10)||'  CHR(10)||''INSERT /*+DIRECT */ INTO '||table_schema||tbsuff||'.'||table_name||' SELECT * FROM '||schema_dot_table||vwsuff||';'';'
  FROM collist
)
SELECT code FROM CODE order by schema_dot_table,phase,ordinal_position;

